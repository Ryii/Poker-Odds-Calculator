(* High-performance poker hand evaluator *)
(* Using a variation of the Cactus Kev's evaluator for speed *)

type hand_rank = 
  | HighCard of int list
  | Pair of int * int list  (* pair rank, kickers *)
  | TwoPair of int * int * int  (* high pair, low pair, kicker *)
  | ThreeOfAKind of int * int list
  | Straight of int  (* high card *)
  | Flush of int list
  | FullHouse of int * int  (* trips, pair *)
  | FourOfAKind of int * int  (* quads, kicker *)
  | StraightFlush of int  (* high card *)

(* Pre-computed tables for fast evaluation *)
let flush_check = Array.make 8192 false
let straight_check = Array.make 8192 0

let init_tables () =
  (* Initialize straight check table *)
  let straights = [
    0b1111100000000; (* A-T straight *)
    0b0111110000000; (* K-9 straight *)
    0b0011111000000; (* Q-8 straight *)
    0b0001111100000; (* J-7 straight *)
    0b0000111110000; (* T-6 straight *)
    0b0000011111000; (* 9-5 straight *)
    0b0000001111100; (* 8-4 straight *)
    0b0000000111110; (* 7-3 straight *)
    0b0000000011111; (* 6-2 straight *)
    0b1000000001111; (* 5-A straight (wheel) *)
  ] in
  List.iteri (fun i pattern ->
    straight_check.(pattern) <- 12 - i
  ) straights;
  
  (* Initialize flush check table *)
  for i = 0 to 8191 do
    if (i land (i - 1)) <> 0 && (* Has at least 2 bits set *)
        (i land (i - 1) land ((i land (i - 1)) - 1)) <> 0 && (* At least 3 *)
        (i land (i - 1) land ((i land (i - 1)) - 1) land 
         ((i land (i - 1) land ((i land (i - 1)) - 1)) - 1)) <> 0 && (* At least 4 *)
        (i land (i - 1) land ((i land (i - 1)) - 1) land 
         ((i land (i - 1) land ((i land (i - 1)) - 1)) - 1) land
         ((i land (i - 1) land ((i land (i - 1)) - 1) land 
          ((i land (i - 1) land ((i land (i - 1)) - 1)) - 1)) - 1)) <> 0 (* At least 5 *)
    then flush_check.(i) <- true
  done

let () = init_tables ()

(* Count set bits (popcount) *)
let popcount n =
  let rec count n acc =
    if n = 0 then acc
    else count (n land (n - 1)) (acc + 1)
  in count n 0

(* Get rank bits for a set of cards *)
let get_rank_bits cards =
  List.fold_left (fun acc card ->
    acc lor (1 lsl (Card.rank_to_int card.Card.rank))
  ) 0 cards

(* Get suit bits for each suit *)
let get_suit_bits cards =
  let suits = Array.make 4 0 in
  List.iter (fun card ->
    let suit_idx = Card.suit_to_int card.Card.suit in
    let rank_bit = 1 lsl (Card.rank_to_int card.Card.rank) in
    suits.(suit_idx) <- suits.(suit_idx) lor rank_bit
  ) cards;
  suits

(* Find the top N set bits *)
let top_bits n bits =
  let rec find bits found remaining =
    if remaining = 0 || bits = 0 then List.rev found
    else
      let highest = 
        let rec find_highest b = 
          if b land 0x1000 <> 0 then 12
          else if b land 0x800 <> 0 then 11
          else if b land 0x400 <> 0 then 10
          else if b land 0x200 <> 0 then 9
          else if b land 0x100 <> 0 then 8
          else if b land 0x80 <> 0 then 7
          else if b land 0x40 <> 0 then 6
          else if b land 0x20 <> 0 then 5
          else if b land 0x10 <> 0 then 4
          else if b land 0x8 <> 0 then 3
          else if b land 0x4 <> 0 then 2
          else if b land 0x2 <> 0 then 1
          else 0
        in find_highest bits
      in
      find (bits lxor (1 lsl highest)) (highest :: found) (remaining - 1)
  in find bits [] n

(* Evaluate a 5-7 card poker hand *)
let evaluate_hand cards =
  let rank_bits = get_rank_bits cards in
  let suit_bits = get_suit_bits cards in
  
  (* Check for flush *)
  let flush_suit = 
    let rec check_suit i =
      if i >= 4 then None
      else if popcount suit_bits.(i) >= 5 then Some i
      else check_suit (i + 1)
    in check_suit 0
  in
  
  match flush_suit with
  | Some suit_idx ->
      (* We have a flush, check for straight flush *)
      let flush_ranks = suit_bits.(suit_idx) in
      if straight_check.(flush_ranks) > 0 then
        StraightFlush straight_check.(flush_ranks)
      else
        Flush (top_bits 5 flush_ranks)
  | None ->
      (* No flush, check other hands *)
      let rank_counts = Array.make 13 0 in
      List.iter (fun card ->
        let r = Card.rank_to_int card.Card.rank in
        rank_counts.(r) <- rank_counts.(r) + 1
      ) cards;
      
      (* Find pairs, trips, quads *)
      let quads = ref [] in
      let trips = ref [] in
      let pairs = ref [] in
      let singles = ref [] in
      
      for r = 12 downto 0 do
        match rank_counts.(r) with
        | 4 -> quads := r :: !quads
        | 3 -> trips := r :: !trips
        | 2 -> pairs := r :: !pairs
        | 1 -> singles := r :: !singles
        | _ -> ()
      done;
      
      match !quads, !trips, !pairs with
      | q::_, _, _ -> 
          let kicker = match !singles @ !pairs @ !trips with
            | k::_ -> k | [] -> 0 
          in
          FourOfAKind (q, kicker)
      | [], t::_, p::_ -> FullHouse (t, p)
      | [], t::_, [] -> ThreeOfAKind (t, List.take 2 !singles)
      | [], [], p1::p2::_ -> TwoPair (p1, p2, List.hd !singles)
      | [], [], [p] -> Pair (p, List.take 3 !singles)
      | [], [], [] ->
          (* Check for straight *)
          if straight_check.(rank_bits) > 0 then
            Straight straight_check.(rank_bits)
          else
            HighCard (top_bits 5 rank_bits)
      | _ -> failwith "Invalid hand"

(* Compare two evaluated hands *)
let compare_hands h1 h2 =
  let rank_value = function
    | StraightFlush _ -> 8
    | FourOfAKind _ -> 7
    | FullHouse _ -> 6
    | Flush _ -> 5
    | Straight _ -> 4
    | ThreeOfAKind _ -> 3
    | TwoPair _ -> 2
    | Pair _ -> 1
    | HighCard _ -> 0
  in
  
  let r1 = rank_value h1 in
  let r2 = rank_value h2 in
  
  if r1 <> r2 then compare r1 r2
  else match h1, h2 with
    | StraightFlush s1, StraightFlush s2 -> compare s1 s2
    | FourOfAKind (q1, k1), FourOfAKind (q2, k2) ->
        let c = compare q1 q2 in
        if c <> 0 then c else compare k1 k2
    | FullHouse (t1, p1), FullHouse (t2, p2) ->
        let c = compare t1 t2 in
        if c <> 0 then c else compare p1 p2
    | Flush k1, Flush k2 -> compare k1 k2
    | Straight s1, Straight s2 -> compare s1 s2
    | ThreeOfAKind (t1, k1), ThreeOfAKind (t2, k2) ->
        let c = compare t1 t2 in
        if c <> 0 then c else compare k1 k2
    | TwoPair (h1, l1, k1), TwoPair (h2, l2, k2) ->
        let c = compare h1 h2 in
        if c <> 0 then c else
        let c = compare l1 l2 in
        if c <> 0 then c else compare k1 k2
    | Pair (p1, k1), Pair (p2, k2) ->
        let c = compare p1 p2 in
        if c <> 0 then c else compare k1 k2
    | HighCard k1, HighCard k2 -> compare k1 k2
    | _ -> 0

(* Helper for List.take since it might not be in stdlib *)
module List = struct
  include List
  
  let rec take n = function
    | [] -> []
    | _ when n <= 0 -> []
    | x::xs -> x :: take (n-1) xs
end 