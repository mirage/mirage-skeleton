module Main (R : Mirage_random.S) = struct
  let t_to_str = function
    | `Unix -> "unix"
    | `Xen -> "xen"
    | `Muen -> "muen"
    | `Qubes -> "qubes"
    | `MacOSX -> "macosx"
    | `Virtio -> "virtio"
    | `Hvt -> "hvt"
    | `Spt -> "spt"

  let generate i = R.generate i

  let start _r =
    let t = Key_gen.target () in
    Logs.info (fun m ->
        m "PRNG example running on %s (target %s)" Sys.os_type (t_to_str t));
    Logs.info (fun m ->
        m "using Fortuna, entropy sources: %a"
          Fmt.(list ~sep:(any ", ") Mirage_crypto_rng.Entropy.pp_source)
          (Mirage_crypto_rng.Entropy.sources ()));
    Logs.info (fun m ->
        m "32 byte random:@ %a" Cstruct.hexdump_pp (R.generate 32));
    let open Randomconv in
    Logs.info (fun m ->
        m "Random numbers: 0x%02X 0x%04X 0x%08lX 0x%016LX" (int8 generate)
          (int16 generate) (int32 generate) (int64 generate));
    Lwt.return_unit
end
