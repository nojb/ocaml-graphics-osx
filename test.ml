module type TURTLE = sig
  val move : float -> unit
  val turn : float -> unit
  val penup : unit -> unit
  val pendown : unit -> unit
end

module Fern (T : TURTLE) : sig
  val fern : unit -> unit
  val koch : int -> unit
end = struct
  let rec fern size sign =
    (* Printf.eprintf "fern size:%f sign:%f\n%!" size sign; *)
    (* ignore (read_line ()); *)
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

  let rec koch level size =
    (* Unix.sleep 1; *)
    if level = 0 then
      T.move size
    else begin
      koch (level-1) (size /. 3.0);
      T.turn 60.0;
      koch (level-1) (size /. 3.0);
      T.turn (-120.0);
      koch (level-1) (size /. 3.0);
      T.turn 60.0;
      koch (level-1) (size /. 3.0)
    end

  let koch level =
    T.turn 60.0;
    koch level 500.0;
    T.turn (-120.0);
    koch level 500.0;
    T.turn (-120.0);
    koch level 500.0
end

  (* [tg turn: 60]; *)
  (*   [self KockSnowflakeSide: level size: 500]; *)
  (*   [tg turn: -120]; *)
  (*   [self KockSnowflakeSide: level size: 500]; *)
  (*   [tg turn: -120]; *)
  (*   [self KockSnowflakeSide: level size: 500]; *)

(*  (void) KockSnowflakeSide: (int)level size:(double) size *)
(* { *)
(*     if (level == 0) *)
(*     { *)
(*         [tg move: size]; *)
(*     } *)
(*     else *)
(*     { *)
(*         [self KockSnowflakeSide: level-1 size: size/3]; *)
(*         [tg turn: 60]; *)
(*         [self KockSnowflakeSide: level-1 size: size/3]; *)
(*         [tg turn: -120]; *)
(*         [self KockSnowflakeSide: level-1 size: size/3]; *)
(*         [tg turn:60]; *)
(*         [self KockSnowflakeSide: level-1 size: size/3]; *)
(*     } *)
(* } *)


module Turtle_osx : TURTLE = struct
  module G = Graphics_osx

  let pi = 4.0 *. atan 1.0
  let deg2rad d = pi *. d /. 180.0

  let () =
    G.open_graph "";
    G.set_line_width 2.0

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
      x = 200.0;
      y = 200.0;
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
  (* F.koch 4; *)
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
