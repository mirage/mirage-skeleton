(*
 * Copyright (c) 2005-2013 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt 
open Printf

let port = 53

(* All of this will move into ocaml-dns ... *)
let get_file filename = 
  OS.Devices.with_kv_ro "fs" (fun kv_ro ->
    match_lwt kv_ro#read filename with
      | None -> fail (Failure "File not found")
      | Some s -> Lwt_stream.to_list s >|= Cstruct.copyv
  )

module DL = Dns.Loader
module DQ = Dns.Query
module DR = Dns.RR
module DP = Dns.Packet

let dnstrie = DL.(state.db.trie)


let get_answer qname qtype id =
  let buf = OS.Io_page.(to_cstruct (get ())) in
  let qname = List.map String.lowercase qname in  
  let ans = DQ.answer_query qname qtype dnstrie in
  let detail = 
    DP.({ qr=Response; opcode=Standard; 
          aa=ans.DQ.aa; tc=false; rd=false; ra=false; 
          rcode=ans.DQ.rcode })      
  in
  let questions = [ DP.({ q_name=qname; q_type=qtype; q_class=Q_IN }) ] in
  let dp = DP.({ id; detail; questions;
        answers=ans.DQ.answer; 
        authorities=ans.DQ.authority; 
        additionals=ans.DQ.additional; 
      })
  in
  DP.marshal buf dp

let no_memo mgr src dst bits =
  let names = Hashtbl.create 8 in
  DP.(
    let d = parse names bits in
    let q = List.hd d.questions in
    let r = get_answer q.q_name q.q_type d.id in
    Net.Datagram.UDPv4.send mgr ~src dst r
  )

(* Space leaking hash table cache, always grows *)
module Leaking_cache = Hashtbl.Make (struct
  type t = string list * DP.q_type
  let equal (a:t) (b:t) = a = b
  let hash = Hashtbl.hash
end)

let cache = Leaking_cache.create 101
let weak_memo mgr src dst bits =
  let open DP in
  let names = Hashtbl.create 8 in
  let d = parse names bits in
  let q = List.hd d.questions in
  let r =
    try
      Leaking_cache.find cache (q.q_name, q.q_type)
    with Not_found -> begin
      let r = get_answer q.q_name q.q_type d.id in
      Leaking_cache.add cache (q.q_name, q.q_type) r;
      r
   end
  in
  Cstruct.BE.set_uint16 r 0 d.id;
  Net.Datagram.UDPv4.send mgr ~src dst r
  
let listen ?(mode=`none) ~zb mgr src =
  Dns.Zone.load_zone ["0mirage-perf";"local";"net"] zb;
  Net.Datagram.UDPv4.(recv mgr src
                        (match mode with
                          |`none -> no_memo mgr src
                          |`memo -> weak_memo mgr src
                        )
  )

let main () =
  Net.Manager.create (fun mgr interface id ->
    (*
     let ip = Net.Nettypes.(
      (ipv4_addr_of_tuple (10l,0l,0l,2l),
       ipv4_addr_of_tuple (255l,255l,255l,0l),
       [ipv4_addr_of_tuple (10l,0l,0l,1l)]
      )) in
    *)
    lwt () = Net.Manager.configure interface (`DHCP) in
    let src = None, port in
    let zonefile = "zones.db" in
    lwt zb = get_file zonefile in
    listen ~mode:`memo ~zb mgr src
  )
