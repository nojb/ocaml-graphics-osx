let out_ref = ref None

let open_graph _ =
  let inp, out, err =
    Unix.open_process_full "graphics_osx.app/Contents/MacOS/graphics_osx" [|"graphics_osx"|]
  in
  out_ref := Some out

let output_binary_int n =
  match !out_ref with
  | None -> ()
  | Some out -> output_binary_int out n

let output_string s =
  match !out_ref with
  | None -> ()
  | Some out -> output_string out s

let flush () =
  match !out_ref with
  | None -> ()
  | Some out -> flush out

let plot x y =
  output_binary_int 1;
  output_binary_int x;
  output_binary_int y;
  flush ()

let set_window_title s =
  output_binary_int 0;
  output_binary_int (String.length s);
  output_string s;
  flush ()
