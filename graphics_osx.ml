let out_ref = ref None

let open_graph _ =
  let inp, out, err =
    Unix.open_process_full "graphics_server" [|"graphics_server"|]
  in
  out_ref := Some out

let output_int n =
  match !out_ref with
  | None -> ()
  | Some out -> output_binary_int out n

let output_float f =
  match !out_ref with
  | None -> ()
  | Some out ->
      let n = Int64.bits_of_float f in
      for i = 7 downto 0 do
        let n = Int64.shift_right n (8 * i) in
        let n = Int64.to_int n land 0xFF in
        output_char out (Char.chr n)
      done

let output_string s =
  match !out_ref with
  | None -> ()
  | Some out ->
      output_int (String.length s);
      output_string out s

let flush () =
  match !out_ref with
  | None -> ()
  | Some out -> flush out

let set_window_title s =
  output_int 0;
  output_string s;
  flush ()

let output_color r g b a =
  output_float r;
  output_float g;
  output_float b;
  output_float a

let set_color r g b a =
  output_int 2;
  output_color r g b a;
  flush ()

let set_font_name s =
  output_int 10;
  output_string s;
  flush ()

let set_font_size x =
  output_int 11;
  output_float x;
  flush ()

let set_line_width x =
  output_int 12;
  output_float x;
  flush ()

let output_point x y =
  output_float x;
  output_float y

let stroke_line x y a b =
  output_int 4;
  output_point x y;
  output_point a b;
  flush ()

let output_rect x y w h =
  output_float x;
  output_float y;
  output_float w;
  output_float h

let stroke_rect x y w h =
  output_int 5;
  output_rect x y w h;
  flush ()

let fill_rect x y w h =
  output_int 8;
  output_rect x y w h;
  flush ()

let stroke_oval x y w h =
  output_int 6;
  output_rect x y w h;
  flush ()

let fill_oval x y w h =
  output_int 7;
  output_rect x y w h;
  flush ()

let stroke_poly pts =
  output_int 9;
  output_int (Array.length pts);
  Array.iter (fun (x, y) -> output_point x y) pts;
  flush ()

let stroke_arc x y r a1 a2 =
  output_int 13;
  output_point x y;
  output_float r;
  output_float a1;
  output_float a2;
  flush ()
