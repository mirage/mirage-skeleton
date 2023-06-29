type state
type game

val initial_state : state
val pp_game : Format.formatter -> game -> unit
val play : state -> int32 -> game * state
val len : int
val marshal : Cstruct.t -> state -> unit
val unmarshal : Cstruct.t -> (state, [> `Msg of string ]) result
