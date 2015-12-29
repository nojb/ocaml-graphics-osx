let () =
  let inp, out, err =
    Unix.open_process_full "graphics_osx.app/Contents/MacOS/graphics_osx" [|"graphics_osx"|]
  in
  let rec loop () =
    let title = read_line () in
    Printf.ksprintf (fun s ->
        output_binary_int out (String.length s);
        output_string out s;
        flush out
      )
      "{ %S : %S, %S : %S }\n" "kind" "setTitle" "title" title;
    loop ()
  in
  loop ()
