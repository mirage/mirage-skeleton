open Mirage_types.V1
open Lwt

module P = Io_page

module Main (C:CONSOLE) = struct

  let start c =
    let one_page = P.get 1 in
    let cstruct_page = P.to_cstruct one_page in
    let cstruct_first_100bytes = Cstruct.sub cstruct_page 0 100 in
    Console.log_s c (Printf.sprintf "Page is %d bytes long.\n" (P.length one_page))
    >>= fun () ->
    Console.log_s c (Printf.sprintf "Cstruct is %d bytes long.\n%!" (Cstruct.len cstruct_page))
    >>= fun () ->
    Cstruct.hexdump cstruct_first_100bytes;
    P.string_blit "Hello world!" 0 one_page 0 12;
    Cstruct.hexdump cstruct_first_100bytes;
    Console.log_s c (String.sub (P.to_string one_page) 0 12)
    >>= fun () ->
    OS.Time.sleep 2.0

end
