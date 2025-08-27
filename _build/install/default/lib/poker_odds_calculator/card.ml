(* Card representation with bitwise operations for performance *)

type rank = Two | Three | Four | Five | Six | Seven | Eight | Nine | Ten | Jack | Queen | King | Ace
type suit = Hearts | Diamonds | Clubs | Spades

type t = {
  rank : rank;
  suit : suit;
  bit_value : int;  (* For fast hand evaluation *)
}

let rank_to_int = function
  | Two -> 0 | Three -> 1 | Four -> 2 | Five -> 3 | Six -> 4
  | Seven -> 5 | Eight -> 6 | Nine -> 7 | Ten -> 8 | Jack -> 9
  | Queen -> 10 | King -> 11 | Ace -> 12

let int_to_rank = function
  | 0 -> Two | 1 -> Three | 2 -> Four | 3 -> Five | 4 -> Six
  | 5 -> Seven | 6 -> Eight | 7 -> Nine | 8 -> Ten | 9 -> Jack
  | 10 -> Queen | 11 -> King | 12 -> Ace | _ -> failwith "Invalid rank"

let suit_to_int = function
  | Hearts -> 0 | Diamonds -> 1 | Clubs -> 2 | Spades -> 3

let int_to_suit = function
  | 0 -> Hearts | 1 -> Diamonds | 2 -> Clubs | 3 -> Spades
  | _ -> failwith "Invalid suit"

let rank_to_string = function
  | Two -> "2" | Three -> "3" | Four -> "4" | Five -> "5" | Six -> "6"
  | Seven -> "7" | Eight -> "8" | Nine -> "9" | Ten -> "T" | Jack -> "J"
  | Queen -> "Q" | King -> "K" | Ace -> "A"

let suit_to_string = function
  | Hearts -> "H" | Diamonds -> "D" | Clubs -> "C" | Spades -> "S"

let suit_to_char = function
  | Hearts -> 'h' | Diamonds -> 'd' | Clubs -> 'c' | Spades -> 's'

let create rank suit =
  let rank_val = rank_to_int rank in
  let suit_val = suit_to_int suit in
  {
    rank;
    suit;
    bit_value = (1 lsl (rank_val + suit_val * 13))
  }

let to_string card =
  rank_to_string card.rank ^ suit_to_string card.suit

let from_string str =
  if String.length str <> 2 then failwith "Invalid card string";
  let rank_char = str.[0] in
  let suit_char = str.[1] in
  let rank = match rank_char with
    | '2' -> Two | '3' -> Three | '4' -> Four | '5' -> Five | '6' -> Six
    | '7' -> Seven | '8' -> Eight | '9' -> Nine | 'T' | 't' -> Ten
    | 'J' | 'j' -> Jack | 'Q' | 'q' -> Queen | 'K' | 'k' -> King | 'A' | 'a' -> Ace
    | _ -> failwith "Invalid rank"
  in
  let suit = match suit_char with
    | 'h' | 'H' -> Hearts
    | 'd' | 'D' -> Diamonds  
    | 'c' | 'C' -> Clubs
    | 's' | 'S' -> Spades
    | _ -> failwith "Invalid suit"
  in
  create rank suit

let compare c1 c2 =
  let r = compare (rank_to_int c1.rank) (rank_to_int c2.rank) in
  if r <> 0 then r else compare (suit_to_int c1.suit) (suit_to_int c2.suit)

let equal c1 c2 = compare c1 c2 = 0

(* Generate standard 52-card deck *)
let full_deck () =
  let ranks = [Two; Three; Four; Five; Six; Seven; Eight; Nine; Ten; Jack; Queen; King; Ace] in
  let suits = [Hearts; Diamonds; Clubs; Spades] in
  List.concat_map (fun suit ->
    List.map (fun rank -> create rank suit) ranks
  ) suits 