(lang dune 3.0)
(name poker_odds_calculator)

(package
 (name poker_odds_calculator)
 (synopsis "A poker odds calculator implemented in OCaml")
 (description "A comprehensive poker odds calculator that can compute equity for Texas Hold'em hands with a graphical user interface.")
 (depends 
  ocaml
  dune
  graphics
  unix
  threads)) 