(* Test suite for poker odds calculator *)

open Poker_odds_calculator

let test_card_creation () =
  let card = Card.create Card.Ace Card.Spades in
  assert (Card.to_string card = "A♠");
  Printf.printf "✓ Card creation test passed\n"

let test_hand_evaluation () =
  let open Card in
  let open Hand_evaluator in
  
  (* Test royal flush *)
  let royal_flush = [
    create Ace Hearts; create King Hearts; create Queen Hearts;
    create Jack Hearts; create Ten Hearts; create Two Clubs; create Three Clubs
  ] in
  let result = evaluate_hand royal_flush in
  assert (match result with StraightFlush 12 -> true | _ -> false);
  Printf.printf "✓ Royal flush test passed\n";
  
  (* Test full house *)
  let full_house = [
    create King Hearts; create King Diamonds; create King Clubs;
    create Two Hearts; create Two Spades
  ] in
  let result = evaluate_hand full_house in
  assert (match result with FullHouse (11, 0) -> true | _ -> false);
  Printf.printf "✓ Full house test passed\n";
  
  (* Test two pair *)
  let two_pair = [
    create Ace Hearts; create Ace Diamonds;
    create King Hearts; create King Spades;
    create Queen Clubs
  ] in
  let result = evaluate_hand two_pair in
  assert (match result with TwoPair (12, 11, 10) -> true | _ -> false);
  Printf.printf "✓ Two pair test passed\n"

let test_equity_calculation () =
  let open Card in
  let open Equity_calculator in
  
  (* AA vs random hand *)
  let aces = (create Ace Hearts, create Ace Spades) in
  let board = [] in
  let villain_range = Card.full_deck () in
  
  let equity = calculate_equity ~hero_hand:aces ~villain_range ~board ~iterations:1000 in
  
  (* AA should have ~85% equity vs random hand preflop *)
  assert (equity.win_probability > 0.80 && equity.win_probability < 0.90);
  Printf.printf "✓ Equity calculation test passed (AA wins %.1f%%)\n" 
    (equity.win_probability *. 100.0)

let test_pot_odds () =
  let open Equity_calculator in
  
  let pot_odds = calculate_pot_odds ~pot_size:100.0 ~bet_to_call:50.0 ~implied_odds_factor:1.0 in
  
  (* Need 33.33% equity to call *)
  assert (abs_float (pot_odds.required_equity -. 0.3333) < 0.01);
  Printf.printf "✓ Pot odds test passed (need %.1f%% equity)\n"
    (pot_odds.required_equity *. 100.0);
  
  (* Test decision making *)
  let good_equity = { 
    win_probability = 0.4; 
    tie_probability = 0.0; 
    lose_probability = 0.6;
    hand_strength = 0.4;
    potential = 0.0 
  } in
  assert (should_call good_equity pot_odds = true);
  
  let bad_equity = { 
    win_probability = 0.2; 
    tie_probability = 0.0; 
    lose_probability = 0.8;
    hand_strength = 0.2;
    potential = 0.0 
  } in
  assert (should_call bad_equity pot_odds = false);
  Printf.printf "✓ Decision making test passed\n"

let test_performance () =
  let open Card in
  let open Hand_evaluator in
  
  let deck = Card.full_deck () in
  let start_time = Unix.gettimeofday () in
  let iterations = 100_000 in
  
  for _ = 1 to iterations do
    (* Random 7 cards *)
    let cards = 
      let shuffled = List.sort (fun _ _ -> Random.int 3 - 1) deck in
      List.take 7 shuffled
    in
    let _ = evaluate_hand cards in
    ()
  done;
  
  let end_time = Unix.gettimeofday () in
  let elapsed = end_time -. start_time in
  let hands_per_second = float iterations /. elapsed in
  
  Printf.printf "✓ Performance test: %.0f hands/second\n" hands_per_second;
  assert (hands_per_second > 50_000.0)  (* Should be much faster *)

let () =
  Printf.printf "🃏 Running Poker Odds Calculator Tests\n";
  Printf.printf "=====================================\n\n";
  
  test_card_creation ();
  test_hand_evaluation ();
  test_equity_calculation ();
  test_pot_odds ();
  test_performance ();
  
  Printf.printf "\n✅ All tests passed!\n" 