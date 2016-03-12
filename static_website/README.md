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
$ sudo xl create -c www.xl
```

Note you may need to edit `www.xl` to customise the bridge name.
