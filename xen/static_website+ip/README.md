This is a custom static website that reads from the kernel command line
instead of hardcoding an IP address.

Example xl:

```
name = 'www2'
kernel = '/home/avsm/src/git/avsm/mirage-skeleton/xen/static_website+ip/mir-www.xen'
builder = 'linux'
memory = 256
extra = "ip=10.11.12.50 gateway=10.11.12.1 netmask=255.255.255.0"
vif = [ 'bridge=xenbr0']
```
