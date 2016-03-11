On Unix, do:

```
$ mirage configure --unix --net=socket
$ make
$ ./mir-www
```

This will run the website on localhost on port 8080, so you should be
able to visit [http://localhost:8080](http://localhost:8080) and see the
content from htdocs directory.

For a Xen DHCP kernel, do:

```
$ mirage configure --xen --dhcp=true
$ make
$ ./mir-www
```

edit `www.xl` to add a VIF, e.g. via:

```
vif = ['bridge=xenbr0']
```

And then run the VM via `xl create -c www.xl`

TLS
---

In order to get tls working for you service please take a look at the examples in the [mirage part of ocaml-tls](https://github.com/mirleft/ocaml-tls/tree/master/mirage).
[mirage-seal](https://github.com/mirage/mirage-seal) is another good starting point.
