On Unix, do:

```
$ env NET=socket mirage configure --unix
$ make depend
$ make
$ make run
```

This will run the website on localhost on port 8080, so you should be
able to visit [http://localhost:8080](http://localhost:8080) and see the
content from htdocs directory.

For a Xen DHCP kernel, do:

```
$ env DHCP=true mirage configure --xen
$ make
$ make run
```

edit `www.xl` to add a VIF, e.g. via:

```
vif = ['bridge=xenbr0']
```

And then run the VM via `xl create -c www.xl`
