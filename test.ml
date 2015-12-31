module type TURTLE = sig
  val move : float -> unit
  val turn : float -> unit
  val penup : unit -> unit
  val pendown : unit -> unit
end

module Fern (T : TURTLE) : sig
  val fern : unit -> unit
end = struct
  let rec fern size sign =
    if size >= 1.0 then begin
      T.move size;
      T.turn (70.0 *. sign); fern (size *. 0.5) (-. sign); T.turn (-70.0 *. sign);
      T.move size;
      T.turn (-70.0 *. sign); fern (size *. 0.5) sign; T.turn (70.0 *. sign);
      T.turn (7.0 *. sign); fern (size -. 1.0) sign; T.turn (-7.0 *. sign);
      T.move (size *. -2.0)
    end

  let fern () =
    T.penup ();
    T.move (-150.0);
    T.turn (-90.0);
    T.move 90.0;
    T.turn 90.0;
    T.pendown ();
    fern 25.0 1.0
end

module type GRAPHICS = sig
  val rlineto : int -> int -> unit
  val rmoveto : int -> int -> unit
  val set_line_width : int -> unit
end

module Turtle_osx : TURTLE = struct
  module G = Graphics_osx

  let pi = 4.0 *. atan 1.0
  let deg2rad d = pi *. d /. 180.0

  let () =
    G.open_graph ""

  type state =
    {
      mutable r : float;
      mutable x : float;
      mutable y : float;
      mutable d : bool;
    }

  let t =
    {
      r = pi /. 2.0;
      x = 0.0;
      y = 0.0;
      d = true;
    }

  let move d =
    let x = t.x +. d *. cos t.r in
    let y = t.y +. d *. sin t.r in
    if t.d then G.stroke_line t.x t.y x y;
    t.x <- x;
    t.y <- y

  let turn a =
    t.r <- t.r -. deg2rad a

  let pendown () =
    t.d <- true

  let penup () =
    t.d <- false
end

module F = Fern (Turtle_osx)

let () =
  F.fern ();
  ignore (read_line ())

  (* G.open_graph ""; *)
  (* print_endline "title?"; *)
  (* let title = read_line () in *)
  (* G.set_window_title title; *)
  (* let r = read_int () in *)
  (* let g = read_int () in *)
  (* let b = read_int () in *)
  (* G.set_color (G.rgb r g b); *)
  (* let module T = Turtle (G) in *)
  (* let rec loop () = *)
  (*   let r = read_int () in *)
  (*   let x = read_int () in *)
  (*   T.turn (float r); *)
  (*   T.move (float x); *)
  (*   loop () *)
  (* in *)
  (* loop () *)
