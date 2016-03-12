open OS
open Lwt.Infix

let ( |> ) x f = f x

let map f m_in =
  let m_out = Lwt_mvar.create_empty () in
  let rec aux () =
    Lwt_mvar.(
      take m_in   >>=
      f           >>= fun v ->
      put m_out v >>= fun () ->
      aux ()
    )
  in
  let _t = aux () in
  m_out

let split m_ab =
  let m_a, m_b = Lwt_mvar.(create_empty (), create_empty ()) in
  let rec aux () =
    Lwt_mvar.take m_ab >>= fun (a, b) ->
    Lwt.join [
      Lwt_mvar.put m_a a;
      Lwt_mvar.put m_b b;
    ] >>= aux
  in
  let _t = aux () in
  (m_a, m_b)

let filter f m_a =
  let m_out = Lwt_mvar.create_empty () in
  let rec aux () =
    Lwt_mvar.take m_a >>= fun a ->
    f a >>= function
      | true -> Lwt_mvar.put m_out a >>= aux
      | false -> aux ()
  in
  let _t = aux () in
  m_out

let read_line () =
  Lwt.return (String.make (Random.int 20) 'a')

let wait_strlen str =
  OS.Time.sleep (float_of_int (String.length str)) >>= fun () ->
  Lwt.return str

let cap_str str =
  Lwt.return (String.uppercase str)

module Echo_server2 (C: V1_LWT.CONSOLE) = struct

  let start c =
  let m_input = Lwt_mvar.create_empty () in
  let m_output = m_input |> map wait_strlen |> map cap_str in

  let rec read () =
    read_line ()           >>= fun s ->
    Lwt_mvar.put m_input s >>=
    read
  in
  let rec write () =
    Lwt_mvar.take m_output >>= fun r ->
    C.log c r;
    write ()
  in
  (read ()) <&> (write ())

end

module Int_server (C: V1_LWT.CONSOLE) = struct

  let start c =
    let add_mult (a, b) = Lwt.return (a + b, a * b) in
    let print_and_go str a =
      C.log c (Printf.sprintf "%s %d" str a);
      Lwt.return a
    in
    let test_odd a = Lwt.return (1 = (a mod 2)) in
    let rec print_odd m =
      Lwt_mvar.take m >>= fun a ->
      C.log c (Printf.sprintf "Odd: %d" a);
      print_odd m
    in
    let ( |> ) x f = f x in

    (* main *)
    let m_input = Lwt_mvar.create_empty () in
    let (ma, mm) = m_input |> map add_mult |> split in
    let _ = ma |> map (print_and_go "Add:") |> filter test_odd |> print_odd in
    let _ = mm |> map (print_and_go "Mult:") |> filter test_odd |> print_odd in
    let rec inp () =
      Lwt_mvar.put m_input (Random.int 1000, Random.int 1000) >>= fun () ->
        Time.sleep 1. >>= fun () ->
        inp () in
    inp ()

end
