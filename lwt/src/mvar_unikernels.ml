open OS
open Lwt

let map f m_in = 
  let m_out = Lwt_mvar.create_empty () in
  let rec aux () = 
    Lwt_mvar.(
      take m_in   >>=
      f           >>= fun v ->
      put m_out v >>
      aux ()
    )
  in
  let t = aux () in
  m_out
    
let split m_ab = 
  let m_a, m_b = Lwt_mvar.(create_empty (), create_empty ()) in
  let rec aux () = 
    Lwt_mvar.take m_ab >>= fun (a, b) ->
    join [
      Lwt_mvar.put m_a a;
      Lwt_mvar.put m_b b;
    ] >> aux ()
  in
  let t = aux () in
  (m_a, m_b)
    
let filter f m_a =
  let m_out = Lwt_mvar.create_empty () in
  let rec aux () = 
    Lwt_mvar.take m_a >>= fun a ->
    f a >>= function
      | true -> Lwt_mvar.put m_out a >> aux ()
      | false -> aux ()
  in
  let t = aux () in
  m_out

let read_line () =
  return (String.make (Random.int 20) 'a')

let wait_strlen str =
  OS.Time.sleep (float_of_int (String.length str)) >>
  return str

let cap_str str =
  return (String.uppercase str)

let rec print_mvar m = 
  lwt s = Lwt_mvar.take m in
  Console.log s;
  print_mvar m

let ( |> ) x f = f x
  
let echo_server2 () = 
  let m_input = Lwt_mvar.create_empty () in
  let m_output = m_input |> map wait_strlen |> map cap_str in
  
  let rec read () = 
    read_line ()           >>= fun s -> 
    Lwt_mvar.put m_input s >>=
    read
  in
  let rec write () = 
    Lwt_mvar.take m_output >>= fun r -> 
    Console.log r;
    write ()
  in
  (read ()) <&> (write ())

let int_server () = 
  let add_mult (a, b) = return (a + b, a * b) in
  let print_and_go str a =
    Console.log (Printf.sprintf "%s %d" str a);
    return a
  in
  let test_odd a = return (1 = (a mod 2)) in
  let rec print_odd m =
    lwt a = Lwt_mvar.take m in
    Console.log (Printf.sprintf "Odd: %d" a);
    print_odd m
  in
  let ( |> ) x f = f x in

  (* main *)
  let m_input = Lwt_mvar.create_empty () in
  let (ma, mm) = m_input |> map add_mult |> split in
  let _ = ma |> map (print_and_go "Add:") |> filter test_odd |> print_odd in
  let _ = mm |> map (print_and_go "Mult:") |> filter test_odd |> print_odd in
  let rec inp () =
    Lwt_mvar.put m_input (Random.int 1000, Random.int 1000) >>
    Time.sleep 1. >>
    inp () in
  inp ()
