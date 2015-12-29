module G = Graphics_osx

let () =
  G.open_graph "";
  let rec loop () =
    let title = read_line () in
    G.set_window_title title;
    loop ()
  in
  loop ()
