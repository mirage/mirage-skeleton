open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let msg = "0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 0020 0021 0022 0023 0024 0025 0026 0027 0028 0029 0030 0031 0032 0033 0034 0035 0036 0037 0038 0039 0040 0041 0042 0043 0044 0045 0046 0047 0048 0049 0050 0051 0052 0053 0054 0055 0056 0057 0058 0059 0060 0061 0062 0063 0064 0065 0066 0067 0068 0069 0070 0071 0072 0073 0074 0075 0076 0077 0078 0079 0080 0081 0082 0083 0084 0085 0086 0087 0088 0089 0090 0091 0092 0093 0094 0095 0096 0097 0098 0099 0100 0101 0102 0103 0104 0105 0106 0107 0108 0109 0110 0111 0112 0113 0114 0115 0116 0117 0118 0119 0120 0121 0122 0123 0124 0125 0126 0127 0128 0129 0130 0131 0132 0133 0134 0135 0136 0137 0138 0139 0140 0141 0142 0143 0144 0145 0146 0147 0148 0149 0150 0151 0152 0153 0154 0155 0156 0157 0158 0159 0160 0161 0162 0163 0164 0165 0166 0167 0168 0169 0170 0171 0172 0173 0174 0175 0176 0177 0178 0179 0180 0181 0182 0183 0184 0185 0186 0187 0188 0189 0190 0191 0192 0193 0194 0195 0196 0197 0198 0199 0200 0201 0202 0203 0204 0205 0206 0207 0208 0209 0210 0211 0212 0213 0214 0215 0216 0217 0218 0219 0220 0221 0222 0223 0224 0225 0226 0227 0228 0229 0230 0231 0232 0233 0234 0235 0236 0237 0238 0239 0240 0241 0242 0243 0244 0245 0246 0247 0248 0249 0250 0251 0252 0253 0254 0255 0256 0257 0258 0259 0260 0261 0262 0263 0264 0265 0266 0267 0268 0269 0270 0271 0272 0273 0274 0275 0276 0277 0278 0279 0280 0281 0282 0283 0284 0285 0286 0287 0288 0289 0290 0291 "

let mlen = String.length msg

let usage_msg = "enter iperf server address exactly as:\nx.x.x.x p\n"
let usage_mlen = String.length usage_msg

let iperf_rx_port = 5001
let cmd_port = 8080

module Main (C:CONSOLE) (S:STACKV4) = struct

  module T  = S.TCPV4
  module CH = Channel.Make(T)

  let start console s =

    let buf = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 mlen in
    Cstruct.blit_from_string msg 0 buf 0 mlen;

    let usage_buf = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 usage_mlen in
    Cstruct.blit_from_string usage_msg 0 usage_buf 0 usage_mlen;

    Lwt_list.iter_s (fun ip -> C.log_s console 
      (sprintf "IP address: %s\n" 
        (Ipaddr.V4.to_string ip))) (S.IPV4.get_ip (S.ipv4 s))
    >>
    C.log_s console
      (green "ready to receive command connections on port %d" cmd_port)
    >>= fun () ->
    S.listen_tcpv4 s cmd_port (

      let rec snd outfl n = match n with
      | 0 -> C.log_s console (red "iperf client: done") >> T.close outfl
      | _ -> 
          T.write outfl buf >>
          snd outfl (n - 1)
      in

      let sendth dst port =
      S.TCPV4.create_connection (S.tcpv4 s) (dst, port) >>= function
      | `Ok outfl -> C.log_s console (red "connected") >> snd outfl 200000
      | `Error e -> C.log_s console (red "connect: error")
      in

      let rec cmd_loop n f =
        fun () ->
        T.read f
        >>= function
        | `Ok b ->
          T.write f b >> 
          let msg_s = (Cstruct.to_string 
                       (Cstruct.sub b 0 ((Cstruct.len b) - 2))) in
          let i = String.index msg_s ' ' in
          let d_ip_s = String.sub msg_s 0 i in
          let d_prt_s = String.sub msg_s (i+1) ((String.length msg_s) - i-1) in
          let dst = (Ipaddr.V4.of_string_exn d_ip_s) in
          let dst_p = int_of_string d_prt_s in
          let _ = sendth dst dst_p in
          C.log_s console
            (yellow "attempting iperf connection to: %s:%s\n" 
               d_ip_s d_prt_s
            )
          >>=
          cmd_loop (n + (Cstruct.len b)) f
        | `Eof -> T.close f >>
           C.log_s console
             (red "cmd connection closed - read: %d bytes " n)
        | `Error e -> C.log_s console (red "read: error")
      in
      fun flow ->
        let dst, dst_port = T.get_dest flow in
        T.write flow usage_buf >>
        C.log_s console
          (green "new command connection from %s %d" 
            (Ipaddr.V4.to_string dst) dst_port
          )
        >>
        C.log_s console
          (green "%s" usage_msg)
      >>=
      cmd_loop 0 flow
    );


    C.log_s console
      (green "ready to receive iperf connections on port %d" iperf_rx_port)
    >>= fun () ->
    S.listen_tcpv4 s iperf_rx_port (
      let rec iperf_rx_loop n f =
        fun () ->
        T.read f
        >>= function
        | `Ok b ->
	   return() >>= iperf_rx_loop (n + (Cstruct.len b)) f
        | `Eof -> T.close f >> C.log_s console (red "iperf received: %d bytes" n)
        | `Error e -> C.log_s console (red "read: error")
      in
      fun flow ->
        let dst, dst_port = T.get_dest flow in
        C.log_s console
          (green "new iperf connection from %s %d" 
            (Ipaddr.V4.to_string dst) dst_port
          )
        >>= 
        iperf_rx_loop 0 flow
    );

    S.listen s
end
