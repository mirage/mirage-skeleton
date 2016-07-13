A simple DNS server that serves the static DNS data found in the `data/test.zone` file.

It also behaves as a DNS client, resolving `dark.recoil.org`.

To test under Unix:

```
$ mirage configure -t unix --net=socket
$ make
$ sudo ./mir-dns
Manager: connect
Manager: configuring
2016-03-12 12:27.40: INF [server] Loading 3107 bytes of zone data
Warning (<string> line 47): Converting MD to MX
Warning (<string> line 48): Converting MF to MX
2016-03-12 12:27.40: INF [server] DNS server listening on UDP port 53
2016-03-12 12:27.43: INF [client] Starting client resolver
2016-03-12 12:27.43: INF [client] Got resolver response, length 49
2016-03-12 12:27.43: INF [client] Got IPS: 89.16.177.154
```

You can test the server using `nslookup`, e.g.

    $ nslookup mail.d1.signpo.st 127.0.0.1
    Server:		127.0.0.1
    Address:	127.0.0.1#53

    Name:	mail.d1.signpo.st
    Address: 127.0.0.94

