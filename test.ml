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
  let rec loop () =
    let x = read_int () in
    let y = read_int () in
    G.plot x y;
    loop ()
  in
  loop ()
