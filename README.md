Prerequisites
=============

- Install latest OPAM from <http://github.com/OCamlPro/opam>

- Install the `mirari` package with OPAM.

=====

The hello world skeleton in `basic` just starts up a Xen kernel that
prints "hello world" with a short pause between words.  You can try it
out by `cd basic && make && make run`. This will make an unikernel
using the "unix-socket" backend.

To use the "unix-direct" or "xen" backends, use respectively:

$ B=--unix make

$ B=--xen make


