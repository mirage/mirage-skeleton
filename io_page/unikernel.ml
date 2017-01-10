open Lwt.Infix

module P = Io_page

let sp = Printf.sprintf

module Main (Time: Mirage_types_lwt.TIME) (C: Mirage_types_lwt.CONSOLE) = struct

  let start _time c =
    let one_page = P.get 1 in
    let cstruct_page = P.to_cstruct one_page in
    let cstruct_first_100bytes = Cstruct.sub cstruct_page 0 100 in
    C.log c (sp "Page is %d bytes long.\n" (P.length one_page)) >>= fun () ->
    C.log c (sp "Cstruct is %d bytes long.\n%!" (Cstruct.len cstruct_page)) >>= fun () ->
    Cstruct.hexdump cstruct_first_100bytes;
    P.string_blit "Hello world!" 0 one_page 0 12;
    Cstruct.hexdump cstruct_first_100bytes;
    C.log c (String.sub (P.to_string one_page) 0 12) >>= fun () ->
    Time.sleep_ns (Duration.of_sec 2)

end
