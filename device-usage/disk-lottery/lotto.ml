type state = { hiscore : int32 }

let initial_state = { hiscore = Int32.zero }

type game =
  | New_hiscore of { hiscore : int32; old_hiscore : int32 }
  | Tie of int32
  | Loss of { loser : int32; hiscore : int32 }

let pp_game ppf = function
  | New_hiscore { hiscore; old_hiscore } ->
    Fmt.pf ppf "YOU WON! You beat the old high score %lu with %lu!" old_hiscore hiscore
  | Tie hiscore ->
    Fmt.pf ppf "TIE! You tied with the high score %lu" hiscore
  | Loss { loser; hiscore } ->
    Fmt.pf ppf "YOU LOST! With %lu you didn't beat the high score %lu" loser hiscore

let play state draw : game * state =
  if draw = state.hiscore then
    Tie draw, state
  else if Int32.unsigned_compare draw state.hiscore > 0 then
    let hiscore = draw in
    New_hiscore { hiscore; old_hiscore = state.hiscore }, { hiscore }
  else
    Loss { loser = draw; hiscore = state.hiscore }, state

(* The format is: "LOTO" || uint32 hiscore || uint32 crc32 *)
let magic = "LOTO"
let magic_offset = 0
let magic_len = 4

let hiscore_offset = 4
let hiscore_len = 4

let crc_offset = 8
let crc_len = 4

let len = 12
let () = assert (len = magic_len + hiscore_len + crc_len)

let digest_cstruct buf =
  let crc32 =
    Checkseum.Crc32.digest_bigstring
      buf.Cstruct.buffer buf.off buf.len
      Optint.zero
  in
  Checkseum.Crc32.to_int32 crc32

let marshal buf { hiscore } =
  if Cstruct.length buf < len then
    invalid_arg "Lotto.marshal";
  Cstruct.blit_from_string magic 0 buf magic_offset magic_len;
  Cstruct.BE.set_uint32 buf hiscore_offset hiscore;
  let checksum = digest_cstruct (Cstruct.sub buf 0 (magic_len + hiscore_len)) in
  Cstruct.BE.set_uint32 buf crc_offset checksum;
  Cstruct.memset (Cstruct.shift buf len) 0

let unmarshal buf =
  let ( let* ) = Result.bind in
  if Cstruct.length buf < len then
    invalid_arg "Lotto.unmarshal";
  let* () =
    if String.equal magic
        (Cstruct.to_string buf ~off:magic_offset ~len:magic_len) then
      Ok ()
    else Error (`Msg "bad magic; is this lottery data?")
  in
  let checksum = Cstruct.BE.get_uint32 buf crc_offset in
  let checksum' = digest_cstruct (Cstruct.sub buf 0 (magic_len + hiscore_len)) in
  let* () =
    if Int32.equal checksum checksum' then
      Ok ()
    else Error (`Msg "bad checksum; possible data corruption")
  in
  Ok { hiscore = Cstruct.BE.get_uint32 buf hiscore_offset }
