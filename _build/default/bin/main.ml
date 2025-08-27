(* Main entry point for Poker Odds Calculator *)

open Poker_odds_calculator

let () =
  Printf.printf "🃏 Poker Odds Calculator\n";
  Printf.printf "================================================\n";
  Printf.printf "Starting graphical interface...\n\n";
  
  (* Initialize random seed *)
  Random.self_init ();
  
  (* Run the GUI *)
  Gui.run () 