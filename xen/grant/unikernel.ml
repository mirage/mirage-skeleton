
module Main (C: V1_LWT.CONSOLE) = struct
  open Lwt

  open Gnt

  let start c = 
    OS.Xs.make () >>= fun client ->
    OS.Xs.(immediate client (fun h -> read h "domid")) >>= fun domid ->
    C.log_s c (Printf.sprintf "I have domid %s" domid) >>= fun () ->
    let domid = int_of_string domid in
    let sh = Gntshr.interface_open () in
    let share = Gntshr.share_pages_exn sh domid 1 true in
    let grant = List.hd share.Gntshr.refs in
    let src = Io_page.to_cstruct share.Gntshr.mapping in
    C.log_s c (Printf.sprintf "Granted page to myself with reference %d" grant) >>= fun () ->
    let mh = Gnttab.interface_open () in
    let map = Gnttab.map_exn mh { Gnttab.domid; ref = grant } true in
    let buf = Gnttab.Local_mapping.to_buf map in
    let dst = Io_page.to_cstruct buf in
    C.log_s c "Mapped grant reference in" >>= fun () ->
    Cstruct.set_uint8 src 0 0xff;
    let result = Cstruct.get_uint8 dst 0 in
    (if result <> 0xff
    then C.log_s c (Printf.sprintf "I wrote 0xff but read %02x" result)
    else C.log_s c "Everything looks ok") >>= fun () ->
    OS.Time.sleep 5.

end
