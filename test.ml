module type GRAPHICS = sig
  val rlineto : int -> int -> unit
  val rmoveto : int -> int -> unit
  val set_line_width : int -> unit
end

module Turtle (G : GRAPHICS) : sig
  val move : float -> unit
  val set_size : float -> unit
  val turn : float -> unit
  val pen_down : unit -> unit
  val pen_up : unit -> unit
end = struct
  let round d = int_of_float (floor (d +. 0.5))
  let theta = ref 90.0
  let pi = 4.0 *. atan 1.0
  let pendown = ref true

  let deg2rad d = d /. 180.0 *. pi

  let move d =
    let dx = round (d *. cos (deg2rad !theta)) in
    let dy = round (d *. sin (deg2rad !theta)) in
    if !pendown then G.rlineto dx dy else G.rmoveto dx dy

  let set_size sz =
    G.set_line_width (round sz)

  let turn r =
    theta := !theta -. r

  let pen_down () =
    pendown := true

  let pen_up () =
    pendown := false
end

module G = Graphics_osx

let () =
  G.open_graph "";
  print_endline "title?";
  let title = read_line () in
  G.set_window_title title;
  let r = read_int () in
  let g = read_int () in
  let b = read_int () in
  G.set_color (G.rgb r g b);
  let module T = Turtle (G) in
  let rec loop () =
    let r = read_int () in
    let x = read_int () in
    T.turn (float r);
    T.move (float x);
    loop ()
  in
  loop ()
