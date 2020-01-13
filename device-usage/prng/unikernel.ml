open Lwt.Infix

module Main (R : Mirage_random.S) = struct

  let s_to_str (s : Entropy.source) = match s with
    | `Timer -> "timer (rdtsc)"
    | `Rdseed -> "rdseed"
    | `Rdrand -> "rdrand"
    | `Xentropyd -> "xentropyd"

  let p_to_str = function
    | `Stdlib -> "stdlib"
    | `Nocrypto -> "fortuna"

  let other = function
    | `Stdlib -> `Nocrypto
    | `Nocrypto -> `Stdlib

  let t_to_str = function
    | `Unix  -> "unix"
    | `Xen -> "xen"
    | `Muen -> "muen"
    | `Qubes -> "qubes"
    | `MacOSX -> "macosx"
    | `Virtio -> "virtio"
    | `Hvt -> "hvt"
    | `Spt -> "spt"

  let start _ _r =
    let rng = Key_gen.prng () in
    let t = Key_gen.target () in
    Entropy.connect () >|= fun ent ->
    let sources = String.concat "; " (List.map s_to_str (Entropy.sources ent)) in
    Logs.info (fun m -> m "PRNG example running on %s" Sys.os_type) ;
    Logs.info (fun m -> m "using %s PRNG" (p_to_str rng)) ;
    if rng = `Nocrypto && (t = `Unix || t = `MacOSX) then
      Logs.info (fun m -> m "/dev/[u]random is used for entropy harvesting")
    else
      Logs.info (fun m -> m "Entropy sources: %s" sources) ;
    Logs.info (fun m -> m "32 byte random:@ %a" Cstruct.hexdump_pp (R.generate 32)) ;
    let open Randomconv in
    Logs.info (fun m -> m "Random numbers: 0x%02X 0x%04X 0x%08lX 0x%016LX"
                  (int8 R.generate) (int16 R.generate)
                  (int32 R.generate) (int64 R.generate)) ;
    let other = other rng in
    Logs.info (fun m -> m "(use %s PRNG by executing 'mirage configure --prng %s -t %s')"
                  (p_to_str other) (p_to_str other) (t_to_str t))
end
