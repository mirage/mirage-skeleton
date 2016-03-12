open Lwt.Infix

let map f ins =
  let (outs, push) = Lwt_stream.create () in
  let rec aux () =
    Lwt_stream.get ins >>= function
    | None   -> push None; Lwt.return ()
    | Some x -> f x >>= fun y -> push (Some y); aux ()
  in
  let _t = aux () in
  outs

let split iab =
  let (oa, pa) = Lwt_stream.create () in
  let (ob, pb) = Lwt_stream.create () in
  let rec aux () =
    Lwt_stream.get iab >>= function
    | None -> pa None; pb None; Lwt.return ()
    | Some (a,b) -> pa (Some a); pb (Some b); aux ()
  in
  let _ = aux () in
  (oa, ob)

let filter p is =
  let (os, push) = Lwt_stream.create () in
  let rec aux () =
    Lwt_stream.get is >>= function
    | None -> push None; Lwt.return ()
    | Some x -> p x >>= function
      | true -> push (Some x); aux ()
      | false -> aux ()
  in
  let _ = aux () in
  os

let read_line () =
  Lwt.return (String.make (Random.int 20) 's')

module Unikernel (C: V1_LWT.CONSOLE) = struct

  let start c =
    let ins, inp = Lwt_stream.create () in
    let _outs, outp = Lwt_stream.create () in

    let rec read () = (read_line () >|= fun s -> inp (Some s)) >>= read
    in
    let rec write () =
      Lwt_stream.get ins >>= function
      | None -> outp None; Lwt.return ()
      | Some x -> C.log c x; outp (Some x); write ()
    in
    read () <&> write ()

end
