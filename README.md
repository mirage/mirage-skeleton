Prerequisites
=============

- Install latest OPAM from <http://github.com/OCamlPro/opam>

- Install the `mirage` package with OPAM.

=====

The hello world skeleton in `basic` just starts up a Xen kernel that
prints "hello world" with a short pause between words.  You can try it
out by:

```
mirage configure basic/config.ml --socket
mirage build basic/config.ml
mirage run basic/config.ml
```

This will make an unikernel using the "unix-socket" backend.

To use the "xen" backend, use:
```
mirage configure basic/config.ml --xen
mirage build basic/config.ml
mirage run basic/config.ml --xen
```
