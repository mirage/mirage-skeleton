module P = Io_page

module Main (C: CONSOLE) = struct

  let start c =
    let one_page = P.get 1 in
    let cstruct_page = P.to_cstruct one_page in
    let cstruct_first_100bytes = Cstruct.sub cstruct_page 0 100 in
    C.log_s "Page is %d bytes long.\n" (P.length one_page) >>
    C.log_s "Cstruct is %d bytes long.\n%!" (Cstruct.len cstruct_page) >>
    ( Cstruct.hexdump cstruct_first_100bytes;
      P.string_blit "Hello world!" 0 one_page 0 12;
      Cstruct.hexdump cstruct_first_100bytes;
      C.log_s (String.sub (P.to_string one_page) 0 12) >>
      OS.Time.sleep 2.0
    )


end
