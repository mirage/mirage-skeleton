### DHCP server

This is a standalone example of a DHCP server using
[charrua-core](http://www.github.com/haesbaert/charrua-core).

It creates a DHCP server on a single interface.

You need to edit `unikernel.ml` and change the interface address to your
respective network interface:

```ocaml
(* IP Configuration, all you need besides dhcpd.conf. *)
let ipaddr = Ipaddr.V4.of_string_exn "192.168.1.5"
```

You must also provide a `files/dhcpd.conf` which is a stripped down ISC DHCP
server configuration, an example is provided.

If you are using `xen`, you may need to edit `dhcp.xl` to customise the
bridge name.

It is worth noting that persistent storage for DHCP leases is not supported yet.
