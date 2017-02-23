### DHCP server

This is a standalone example of a DHCP server using
[charrua-core](http://www.github.com/haesbaert/charrua-core).

It creates a DHCP server.

You need to edit `dhcp_config.ml` to setup the options being offered by the
server.

If you are using `xen`, don't forget to add the vif to `dhcp.xl`.
