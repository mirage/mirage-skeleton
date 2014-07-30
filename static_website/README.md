Put static files into the htdocs/ directory.

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
