  open Hand_evaluator

type player_hand = Card.t * Card.t
type board = Card.t list

type equity_result = {
  win_probability: float;
  tie_probability: float;
  lose_probability: float;
  hand_strength: float;
  potential: float;
}

type pot_odds = {
  pot_size: float;
  bet_to_call: float;
  pot_odds_ratio: float;
  required_equity: float;
  implied_odds_factor: float;
}

let calculate_equity ~hero_hand ~villain_range ~board ~iterations =
  let hero_cards = match hero_hand with (c1, c2) -> [c1; c2] in
  let board_cards = board in
  let dead_cards = hero_cards @ board_cards in
  
  let wins = ref 0 in
  let ties = ref 0 in
  let total = ref 0 in
  
  for _ = 1 to iterations do

    let villain_cards = 
      let rec sample () =
        let idx1 = Random.int (List.length villain_range) in
        let idx2 = Random.int (List.length villain_range) in
        if idx1 = idx2 then sample ()
        else
          let c1 = List.nth villain_range idx1 in
          let c2 = List.nth villain_range idx2 in
          if List.mem c1 dead_cards || List.mem c2 dead_cards || Card.equal c1 c2
          then sample ()
          else [c1; c2]
      in sample ()
    in
    

    let remaining_board = 
      let deck = Card.full_deck () in
      let available = List.filter (fun c -> 
        not (List.mem c dead_cards || List.mem c villain_cards)
      ) deck in
      
      let rec sample_n n cards =
        if n = 0 then []
        else
          let idx = Random.int (List.length cards) in
          let card = List.nth cards idx in
          let remaining = List.filter (fun c -> not (Card.equal c card)) cards in
          card :: sample_n (n-1) remaining
      in
      sample_n (5 - List.length board_cards) available
    in
    
    let full_board = board_cards @ remaining_board in
    let hero_eval = evaluate_hand (hero_cards @ full_board) in
    let villain_eval = evaluate_hand (villain_cards @ full_board) in
    
    match compare_hands hero_eval villain_eval with
    | n when n > 0 -> incr wins
    | 0 -> incr ties
    | _ -> ()
  done;
  
  total := iterations;
  {
    win_probability = float !wins /. float !total;
    tie_probability = float !ties /. float !total;
    lose_probability = 1.0 -. (float !wins +. float !ties) /. float !total;
    hand_strength = (float !wins +. float !ties *. 0.5) /. float !total;
    potential = 0.0;
  }

let calculate_exact_equity ~hero_hand ~villain_hand ~board =
  let hero_cards = match hero_hand with (c1, c2) -> [c1; c2] in
  let villain_cards = match villain_hand with (c1, c2) -> [c1; c2] in
  let board_cards = board in
  let dead_cards = hero_cards @ villain_cards @ board_cards in
  
  let deck = Card.full_deck () in
  let remaining = List.filter (fun c -> not (List.mem c dead_cards)) deck in
  
  let wins = ref 0 in
  let ties = ref 0 in
  let total = ref 0 in
  

  let cards_needed = 5 - List.length board_cards in
  
  let rec enumerate_boards remaining_cards n current_board =
    if n = 0 then begin
      let full_board = board_cards @ current_board in
      let hero_eval = evaluate_hand (hero_cards @ full_board) in
      let villain_eval = evaluate_hand (villain_cards @ full_board) in
      
      incr total;
      match compare_hands hero_eval villain_eval with
      | n when n > 0 -> incr wins
      | 0 -> incr ties
      | _ -> ()
    end else
      match remaining_cards with
      | [] -> ()
      | card :: rest ->
          enumerate_boards rest n current_board;
          enumerate_boards rest (n-1) (card :: current_board)
  in
  
  enumerate_boards remaining cards_needed [];
  
  {
    win_probability = float !wins /. float !total;
    tie_probability = float !ties /. float !total;
    lose_probability = 1.0 -. (float !wins +. float !ties) /. float !total;
    hand_strength = (float !wins +. float !ties *. 0.5) /. float !total;
    potential = 0.0;
  }

let calculate_pot_odds ~pot_size ~bet_to_call ~implied_odds_factor =
  let pot_odds_ratio = bet_to_call /. (pot_size +. bet_to_call) in
  {
    pot_size;
    bet_to_call;
    pot_odds_ratio;
    required_equity = pot_odds_ratio;
    implied_odds_factor;
  }

let estimate_implied_odds ~position ~_opponent_vpip ~opponent_aggression ~stack_sizes =
  let base_factor = 1.0 in
  let position_bonus = if position = "button" then 0.2 else 0.0 in
  let aggression_bonus = opponent_aggression *. 0.3 in
  let stack_depth_factor = min 2.0 (stack_sizes /. 100.0) in
  
  base_factor +. position_bonus +. aggression_bonus *. stack_depth_factor

let calculate_hand_potential ~hero_hand ~board =
  if List.length board >= 5 then 0.0
  else
    let hero_cards = match hero_hand with (c1, c2) -> [c1; c2] in
    let current_hand = evaluate_hand (hero_cards @ board) in
    
    let outs = match current_hand with
      | HighCard _ -> 6
      | Pair _ -> 5
      | TwoPair _ -> 4
      | _ -> 2
    in
    
    let cards_to_come = 5 - List.length board in
    let cards_in_deck = 52 - 2 - List.length board in
    

    1.0 -. (float (cards_in_deck - outs) /. float cards_in_deck) ** float cards_to_come

let parse_range str =
  let all_cards = Card.full_deck () in
  match str with
  | "random" | "100%" -> all_cards
  | "top10%" -> 
      List.filter (fun c -> 
        let r = Card.rank_to_int c.Card.rank in
        r >= 9
      ) all_cards
  | _ -> all_cards

let should_call equity pot_odds =
  equity.hand_strength >= pot_odds.required_equity

let pot_odds_to_string pot_odds =
  Printf.sprintf "Pot: $%.2f, Call: $%.2f, Odds: %.1f%% (Need %.1f%% equity)"
    pot_odds.pot_size
    pot_odds.bet_to_call
    (pot_odds.pot_odds_ratio *. 100.0)
    (pot_odds.required_equity *. 100.0) 