module Main (R : Mirage_crypto_rng_mirage.S) = struct
  let start _r =
    Logs.info (fun m ->
        m "using Fortuna, entropy sources: %a"
          Fmt.(list ~sep:(any ", ") Mirage_crypto_rng.Entropy.pp_source)
          (Mirage_crypto_rng.Entropy.sources ()));
    Logs.info (fun m ->
        m "Random numbers: 0x%02X 0x%04X 0x%08lX 0x%016LX"
          (Randomconv.int8 R.generate)
          (Randomconv.int16 R.generate)
          (Randomconv.int32 R.generate)
          (Randomconv.int64 R.generate));
    Logs.info (fun m ->
        m "64 byte random:@ %a" (Ohex.pp_hexdump ()) (R.generate 64));
    Logs.info (fun m ->
        m "MD5 of the empty string %a" (Ohex.pp_hexdump ())
          Digestif.MD5.(to_raw_string (digest_string "")));
    Logs.info (fun m ->
        m "SHA1 of the empty string %a" (Ohex.pp_hexdump ())
          Digestif.SHA1.(to_raw_string (digest_string "")));
    Logs.info (fun m ->
        m "SHA256 of the empty string %a" (Ohex.pp_hexdump ())
          Digestif.SHA256.(to_raw_string (digest_string "")));
    Logs.info (fun m ->
        m "SHA384 of the empty string %a" (Ohex.pp_hexdump ())
          Digestif.SHA384.(to_raw_string (digest_string "")));
    Logs.info (fun m ->
        m "SHA512 of the empty string %a" (Ohex.pp_hexdump ())
          Digestif.SHA512.(to_raw_string (digest_string "")));
    let n = String.make 32 '\000' in
    let key = Mirage_crypto.Chacha20.of_secret n
    and nonce = String.make 12 '\000' in
    Logs.info (fun m ->
        m "Chacha20/Poly1305 of 32*0, key 32*0, nonce 12*0: %a"
          (Ohex.pp_hexdump ())
          (Mirage_crypto.Chacha20.authenticate_encrypt ~key ~nonce n));
    let key = Mirage_crypto_pk.Rsa.generate ~bits:4096 () in
    let signature =
      Mirage_crypto_pk.Rsa.PKCS1.sign ~hash:`SHA256 ~key (`Message n)
    in
    let verified =
      let key = Mirage_crypto_pk.Rsa.pub_of_priv key in
      let hashp = function `SHA256 -> true | _ -> false in
      Mirage_crypto_pk.Rsa.PKCS1.verify ~hashp ~key ~signature (`Message n)
    in
    Logs.info (fun m ->
        m "Generated a RSA key of %d bits (sign + verify %B)"
          (Mirage_crypto_pk.Rsa.priv_bits key)
          verified);
    Lwt.return_unit
end
