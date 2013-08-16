open OS
open Lwt

let map f ins = 
  let (outs, push) = Lwt_stream.create () in
  let rec aux () = match_lwt Lwt_stream.get ins with
    | None -> push None; return ()
    | Some x -> lwt y = f x  in push (Some y); aux ()
  in
  let _ = aux () in
  outs

let split iab = 
  let (oa, pa) = Lwt_stream.create () in
  let (ob, pb) = Lwt_stream.create () in 
  let rec aux () = match_lwt Lwt_stream.get iab with
    | None -> pa None; pb None; return ()
    | Some (a,b) -> pa (Some a); pb (Some b); aux ()
  in
  let _ = aux () in
  (oa, ob)

let filter p is =
  let (os, push) = Lwt_stream.create () in
  let rec aux () = match_lwt Lwt_stream.get is with
    | None -> push None; return ()
    | Some x -> match_lwt p x with
        | true -> push (Some x); aux ()
        | false -> aux ()
  in
  let _ = aux () in
  os

let ( |> ) x f = f x

let read_line () = 
  return (String.make (Random.int 20) 's')

let main () = 
  let ins, inp = Lwt_stream.create () in
  let outs, outp = Lwt_stream.create () in
  
  let rec read () = 
    read_line () >>= fun s -> return (inp (Some s)) >>= read
  in
  let rec write () = 
    match_lwt Lwt_stream.get ins with
      | None -> outp None; return ()
      | Some x -> Console.log x; outp (Some x); write ()
  in

  (read ()) <&> (write ())
