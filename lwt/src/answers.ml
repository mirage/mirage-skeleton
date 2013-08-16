open Lwt
open OS

let heads1 () =
  bind (join [
    bind (Time.sleep 1.0) (fun () ->
      print_endline "Heads"; return ()
    );
    bind (Time.sleep 2.0) (fun () ->
      print_endline "Tails"; return ()
    );
  ]) (fun () ->
    print_endline ("Finished"); return ()
  )

let heads2 () =
  join [
    (Time.sleep 1.0 >>= fun () -> (print_endline "Heads"; return ()));
    (Time.sleep 2.0 >>= fun () -> (print_endline "Tails"; return ()));
  ] >>= (fun () ->
    print_endline "Finished";
    return ()
  )

let heads3 () = 
  let heads =
    Time.sleep 1.0 >>
    return (print_endline "Heads");
  in
  let tails =
    Time.sleep 2.0 >>
    return (Console.log "Tails");
  in
  lwt () = heads <&> tails in
  Console.log "Finished";
  return ()

let timeout1 () = 
  Random.self_init ();
  let timeout f t = 
    Time.sleep f >>
    match state t with
      | Return v -> return (Some v)
      | _        -> cancel t; return None
  in
  let t = Time.sleep (Random.float 3.0) >> return "Heads" in
  timeout 2.0 t >>= fun v ->
    Console.log (match v with None -> "cancelled" | Some v -> v);
  Console.log "Finished";
  return ()

let timeout2 () = 
  Random.self_init ();
  let timeout f t =
    let tmout = Time.sleep f in
    pick [
      (tmout >>= fun () -> return None);
      (t >>= fun v -> return (Some v));
    ]
  in
  let t = Time.sleep (Random.float 3.0) >> return "Heads" in
  timeout 2.0 t >>= fun v ->
    Console.log (match v with None -> "Cancelled" | Some v -> v);
  Console.log "Finished";
  return ()

let echo_server1 () =
  let read_line () =
    OS.Time.sleep (Random.float 2.5) >>
    Lwt.return (String.make (Random.int 20) 'a')
  in
  let rec echo_server = function
    | 0 -> return ()
    | n -> lwt s = read_line () in
           Console.log s;
           echo_server (n-1)
  in
  echo_server 10
