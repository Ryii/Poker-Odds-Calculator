open Graphics
open Card
open Equity_calculator


let bg_color = rgb 20 20 30
let felt_color = rgb 30 90 30
let text_color = rgb 220 220 220
let accent_color = rgb 255 100 100
let win_color = rgb 100 255 100
let lose_color = rgb 255 100 100
let tie_color = rgb 255 255 100


let window_width = 1200
let window_height = 800
let card_width = 60
let card_height = 90


type gui_state = {
  mutable hero_hand: (Card.t * Card.t) option;
  mutable board: Card.t list;
  mutable villain_range: string;
  mutable pot_size: float;
  mutable bet_to_call: float;
  mutable equity: equity_result option;
  mutable pot_odds: pot_odds option;
  mutable animation_frame: int;
  mutable selected_card: int;
  mutable needs_redraw: bool;
}

let state = {
  hero_hand = None;
  board = [];
  villain_range = "random";
  pot_size = 100.0;
  bet_to_call = 50.0;
  equity = None;
  pot_odds = None;
  animation_frame = 0;
  selected_card = -1;
  needs_redraw = true;
}


let draw_card x y card ~highlighted ~face_down =
  let scale = if highlighted then 1.1 else 1.0 in
  let w = int_of_float (float card_width *. scale) in
  let h = int_of_float (float card_height *. scale) in
  

  set_color (rgb 10 10 10);
  fill_rect (x + 3) (y - 3) w h;
  

  if face_down then begin
    set_color (rgb 50 50 150);
    fill_rect x y w h;
    set_color (rgb 70 70 170);

    for i = 0 to 5 do
      for j = 0 to 7 do
        draw_circle (x + i * 10 + 5) (y + j * 10 + 5) 3
      done
    done
  end else begin
    set_color white;
    fill_rect x y w h;
    

    set_color black;
    draw_rect x y w h;
    

    let rank_str = rank_to_string card.rank in
    let suit_str = suit_to_string card.suit in
    let color = match card.suit with
      | Hearts | Diamonds -> red
      | Clubs | Spades -> black
    in
    
    set_color color;
    moveto (x + 5) (y + h - 20);
    draw_string rank_str;
    moveto (x + 5) (y + h - 40);
    draw_string suit_str;
    

    moveto (x + w/2 - 10) (y + h/2 - 10);

    let old_x = current_x () in
    let old_y = current_y () in
    moveto (x + w/2 - 10) (y + h/2 - 10);
    draw_string suit_str;
    moveto old_x old_y;
  end


let draw_table () =

  set_color felt_color;
  fill_ellipse (window_width / 2) (window_height / 2) 400 250;
  

  set_color (rgb 80 40 20);
  set_line_width 5;
  draw_ellipse (window_width / 2) (window_height / 2) 400 250;
  set_line_width 1


let draw_equity_meter x y width height equity =

  set_color (rgb 40 40 40);
  fill_rect x y width height;
  

  let win_width = int_of_float (equity.win_probability *. float width) in
  let tie_width = int_of_float (equity.tie_probability *. float width) in
  

  let anim_factor = min 1.0 (float state.animation_frame /. 30.0) in
  let win_w = int_of_float (float win_width *. anim_factor) in
  let tie_w = int_of_float (float tie_width *. anim_factor) in
  
  set_color win_color;
  fill_rect x y win_w height;
  
  set_color tie_color;
  fill_rect (x + win_w) y tie_w height;
  
  set_color lose_color;
  fill_rect (x + win_w + tie_w) y (width - win_w - tie_w) height;
  

  set_color white;
  moveto (x + 10) (y + height + 5);
  draw_string (Printf.sprintf "Win: %.1f%%" (equity.win_probability *. 100.0));
  
  moveto (x + width / 3) (y + height + 5);
  draw_string (Printf.sprintf "Tie: %.1f%%" (equity.tie_probability *. 100.0));
  
  moveto (x + 2 * width / 3) (y + height + 5);
  draw_string (Printf.sprintf "Lose: %.1f%%" (equity.lose_probability *. 100.0))


let draw_pot_odds_display x y pot_odds equity =
  set_color text_color;
  moveto x y;
  draw_string "POT ODDS ANALYSIS";
  

  let pot_radius = 40 in
  let pot_x = x + 100 in
  let pot_y = y - 50 in
  

  set_color (rgb 255 215 0);
  fill_circle pot_x pot_y pot_radius;
  set_color black;
  draw_circle pot_x pot_y pot_radius;
  

  set_color accent_color;
  fill_circle (pot_x + 80) pot_y 20;
  

  set_color white;
  moveto (pot_x + 60) pot_y;
  lineto (pot_x + 40) pot_y;
  

  set_color text_color;
  moveto x (y - 100);
  draw_string (pot_odds_to_string pot_odds);
  

  let should_call = should_call equity pot_odds in
  set_color (if should_call then win_color else lose_color);
  moveto x (y - 130);
  draw_string (if should_call then "✓ CALL (Profitable)" else "✗ FOLD (Unprofitable)")


let draw_hand_strength x y strength =

  let radius = 60 in
  let center_x = x + radius in
  let center_y = y + radius in
  

  set_color (rgb 40 40 40);
  fill_circle center_x center_y radius;
  

  let angle = int_of_float (strength *. 360.0) in
  set_color (rgb 
    (int_of_float ((1.0 -. strength) *. 255.0))
    (int_of_float (strength *. 255.0))
    0);
  fill_arc center_x center_y radius radius 90 (90 - angle);
  

  set_color white;
  moveto (center_x - 20) (center_y - 5);
  draw_string (Printf.sprintf "%.0f%%" (strength *. 100.0))


let draw_state () =

  set_color bg_color;
  fill_rect 0 0 window_width window_height;
  

  draw_table ();
  

  set_color white;
  moveto (window_width / 2 - 150) (window_height - 50);
  draw_string "POKER ODDS CALCULATOR";
  

  begin match state.hero_hand with
  | Some (c1, c2) ->
      draw_card 500 100 c1 ~highlighted:(state.selected_card = 0) ~face_down:false;
      draw_card 570 100 c2 ~highlighted:(state.selected_card = 1) ~face_down:false;
      
      set_color text_color;
      moveto 520 80;
      draw_string "Your Hand"
  | None ->
      draw_card 500 100 (Card.create Two Hearts) ~highlighted:false ~face_down:true;
      draw_card 570 100 (Card.create Two Hearts) ~highlighted:false ~face_down:true
  end;
  

  let board_x = 350 in
  let board_y = 350 in
  for i = 0 to 4 do
    if i < List.length state.board then
      let card = List.nth state.board i in
      draw_card (board_x + i * 70) board_y card 
        ~highlighted:(state.selected_card = i + 2) ~face_down:false
    else
      draw_card (board_x + i * 70) board_y (Card.create Two Hearts) 
        ~highlighted:false ~face_down:true
  done;
  
  set_color text_color;
  moveto (board_x + 100) (board_y - 20);
  draw_string "Community Cards";
  

  begin match state.equity with
  | Some equity ->
      draw_equity_meter 300 600 600 30 equity;
      draw_hand_strength 50 500 equity.hand_strength;
      

      begin match state.pot_odds with
      | Some pot_odds ->
          draw_pot_odds_display 50 300 pot_odds equity
      | None -> ()
      end
  | None -> ()
  end;
  

  set_color (rgb 150 150 150);
  moveto 20 20;
  draw_string "Click cards to select • Press 1-9,T,J,Q,K,A for rank • Press h,d,c,s for suit • Press SPACE to calculate";
  

  synchronize ()


let handle_click x y =

  if x >= 500 && x <= 560 && y >= 100 && y <= 190 then
    state.selected_card <- 0
  else if x >= 570 && x <= 630 && y >= 100 && y <= 190 then
    state.selected_card <- 1

  else
    for i = 0 to 4 do
      let card_x = 350 + i * 70 in
      if x >= card_x && x <= card_x + 60 && y >= 350 && y <= 440 then
        state.selected_card <- i + 2
    done


let handle_key key =
  if state.selected_card >= 0 then
    let rank = match key with
      | '2' -> Some Two | '3' -> Some Three | '4' -> Some Four
      | '5' -> Some Five | '6' -> Some Six | '7' -> Some Seven
      | '8' -> Some Eight | '9' -> Some Nine | 't' | 'T' -> Some Ten
      | 'j' | 'J' -> Some Jack | 'q' | 'Q' -> Some Queen
      | 'k' | 'K' -> Some King | 'a' | 'A' -> Some Ace
      | _ -> None
    in
    
    let suit = match key with
      | 'h' -> Some Hearts | 'd' -> Some Diamonds
      | 'c' -> Some Clubs | 's' -> Some Spades
      | _ -> None
    in
    

    match rank, suit with
    | Some r, _ ->
        let current_suit = 
          if state.selected_card < 2 then
            match state.hero_hand with
            | Some (c1, c2) -> 
                if state.selected_card = 0 then c1.suit else c2.suit
            | None -> Hearts
          else
            try (List.nth state.board (state.selected_card - 2)).suit
            with _ -> Hearts
        in
        let new_card = Card.create r current_suit in
        
        if state.selected_card < 2 then
          match state.hero_hand with
          | Some (c1, c2) ->
              if state.selected_card = 0 then
                state.hero_hand <- Some (new_card, c2)
              else
                state.hero_hand <- Some (c1, new_card)
          | None ->
              if state.selected_card = 0 then
                state.hero_hand <- Some (new_card, Card.create Two Hearts)
              else
                state.hero_hand <- Some (Card.create Two Hearts, new_card)
        else
          let idx = state.selected_card - 2 in
          let rec update_board i = function
            | [] -> if i = idx then [new_card] else []
            | h::t -> 
                if i = idx then new_card :: t
                else h :: update_board (i+1) t
          in
          state.board <- update_board 0 state.board
          
    | _, Some s ->
        let current_rank = 
          if state.selected_card < 2 then
            match state.hero_hand with
            | Some (c1, c2) -> 
                if state.selected_card = 0 then c1.rank else c2.rank
            | None -> Ace
          else
            try (List.nth state.board (state.selected_card - 2)).rank
            with _ -> Ace
        in
        let new_card = Card.create current_rank s in
        
        if state.selected_card < 2 then
          match state.hero_hand with
          | Some (c1, c2) ->
              if state.selected_card = 0 then
                state.hero_hand <- Some (new_card, c2)
              else
                state.hero_hand <- Some (c1, new_card)
          | None ->
              state.hero_hand <- Some (new_card, Card.create Two Hearts)
        else
          let idx = state.selected_card - 2 in
          state.board <- List.mapi (fun i c -> 
            if i = idx then new_card else c
          ) state.board
    | _ -> ()
  ;
  

  if key = ' ' then begin
    match state.hero_hand with
    | Some hero ->
        let villain_range = parse_range state.villain_range in
        let equity = calculate_equity ~hero_hand:hero 
          ~villain_range ~board:state.board ~iterations:10000 in
        state.equity <- Some equity;
        
        let pot_odds = calculate_pot_odds 
          ~pot_size:state.pot_size 
          ~bet_to_call:state.bet_to_call 
          ~implied_odds_factor:1.5 in
        state.pot_odds <- Some pot_odds;
        
        state.animation_frame <- 0
    | None -> ()
  end


let rec main_loop () =
  if state.needs_redraw then begin
    draw_state ();
    state.needs_redraw <- false
  end;
  
  let event = wait_next_event [Button_down; Key_pressed] in
  
  if event.button then begin
    handle_click event.mouse_x event.mouse_y;
    state.needs_redraw <- true
  end;
  
  if event.keypressed then begin
    handle_key event.key;
    state.needs_redraw <- true
  end;
  
  Unix.sleepf 0.016;
  main_loop ()


let run () =
  open_graph (Printf.sprintf " %dx%d" window_width window_height);
  set_window_title "Poker Odds Calculator";
  auto_synchronize false;
  

  state.hero_hand <- Some (Card.create Ace Hearts, Card.create King Hearts);
  state.board <- [
    Card.create Queen Hearts;
    Card.create Jack Hearts;
    Card.create Ten Spades
  ];
  
  try
    main_loop ()
  with
  | Graphic_failure _ -> close_graph () 