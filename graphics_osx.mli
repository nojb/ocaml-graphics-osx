val open_graph : string -> unit

type color = int

val rgb : int -> int -> int -> color
val set_color : color -> unit
val plot : int -> int -> unit
val set_window_title : string -> unit
val moveto : int -> int -> unit
val rmoveto : int -> int -> unit
val rlineto : int -> int -> unit
val set_line_width : int -> unit
