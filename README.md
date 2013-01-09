Prerequisites
=============

- Install latest OPAM from <http://github.com/OCamlPro/opam> and the `cmdliner`
  branch via `git clone -b cmdliner git://github.com/OCamlPro/opam

- Run `opam init` to set up your repository. If you want to develop packages,
  then fork <git://github.com/OCamlPro/opam-repository> and run `opam init <path>` 
  to that repository instead.

- Install the forked OASIS via `opam install oasis-mirage`.

- `opam switch 4.00.1+mirage-xen` to get the right compiler version.

Basic
=====

The hello world skeleton in `basic` just starts up a Xen kernel that prints
"hello world" with a short pause between words.  You can try it out by `cd
basic && make && make run`.  Here's some more detail about how it all fits
together:

The build under UNIX is the standard one.  Use either the `system` compiler
variant in OPAM, or the `4.00.1+mirage-unix` (which configures the networking
stack to serve TCP/IP from userspace instead of using kernel sockets). Create
an `_oasis` file with the `Executable` section that points to the final module,
and use `oasis setup` and `ocaml setup.ml -build` as your normally would.

Linking a Xen kernel is a two stage process. Firstly, the OCaml compiler must
link all the OCaml modules into a standalone compiled object file.  This is
done via the `output-obj` flag, and is supported in the `oasis-mirage` package
via the "native_object" `CompiledObject` field.

This target will output a file with the `.nobj.o` suffix, which can be linked
with a runtime to produce a kernel binary.  This is done by running the
`mir-build` script that is included in the `mirage-platform` distribution:
`mir-build -o <kernel> <input.nobj.o>`

OASIS can be configured to automatically run this extra step via the
`PostBuildCommand`, which in the hello world example runs `gen_xen.sh`.
Since Xen kernels can only be built on 64-bit Linux, this script silently
passes if the `nobj.o` file isn't built (e.g., on the UNIX backend).
