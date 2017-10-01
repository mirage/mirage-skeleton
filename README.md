[![Build Status](https://travis-ci.org/mirage/mirage-skeleton.svg?branch=master)](https://travis-ci.org/mirage/mirage-skeleton)

# mirage-skeleton

This repository is a collection of **tutorial code** referred to from [the Mirage
website](https://mirage.io), **example code** for using specific devices like
filesystems and networks, and **higher-level applications** like
DHCP, DNS, and Web servers.

* `tutorial/` contains the tutorial content.
* `device-usage/` contains examples showing specific devices.
* `applications/` contains the higher-level examples, which may use several
  different devices.

## Prerequisites

- Install latest OPAM (at least 1.2.2), following instructions at
<https://opam.ocaml.org/>

- Install the `mirage` package with OPAM, updating your package first if
necessary:

```
    $ opam update -u
    $ opam install mirage
    $ eval `opam config env`
```

- Please ensure that your Mirage command-line version is at least 3.0.0 before
proceeding:

```
    $ mirage --version
    3.0.5
```

## Configure, Build, Run

Each unikernel lives in its own directory, and can be configured, built, and run
from that location.  For example:

```
    $ cd applications/static_website_tls
    $ mirage configure -t unix # initial setup for UNIX backend
    $ make depend # install dependencies
    $ make # build the program
    $ ./https # run the program
```

If you want to clean up `mirage`'s artifacts after building, `mirage clean`
will do the trick:

```
    $ cd applications/static_website_tls
    $ mirage clean
```

There is also a top-level `Makefile` at the root of this repository with
convenience functions for configuring, building, and running all of the examples
in one step.

```
    $ make all                   ## equivalent to ...
    $ make configure build
    $ make clean
```

### Details


The `Makefile` simply invokes sample-specific `sample/Makefile`. Each of those
invokes the `mirage` command-line tool to configure, build and run the sample,
passing flags and environment as directed. The `mirage` command-line tool
assumes that the [OPAM](https://opam.ocaml.org/) package manager is present and
is used to manage installation of an OCaml dependencies.

The `mirage` command-line tool supports four commands, each of which either
uses `config.ml` in the current directory or supports passing a `config.ml`
directly.

#### To configure a unikernel before building:

    $ mirage configure -t [ukvm|kvm|qubes|macosx|unix|xen]

The boot target is selected via the `-t` flag. The default target is `unix`.
Depending on what devices are present in `config.ml`, there may be additional
configuration options for the unikernel.  To list the options,

```
    $ mirage help configure
```

and see the section labeled `UNIKERNEL PARAMETERS`.

#### To install dependencies

After running `mirage configure`:

```
    $ make depend
```

to install the list of dependencies discovered in the `mirage configure` phase.

#### To build a unikernel:

    $ make

The output will be created next to the `config.ml` file used.

#### To run a unikernel:

The mechanics of running the generated artifact will be dependent on the backend
used.  For details, see
[solo5's readme for Ukvm and Virtio](https://github.com/solo5/solo5),
[the qubes-test-mirage repository's readme for Qubes](https://github.com/talex5/qubes-test-mirage), or
[the MirageOS website instructions on booting Xen unikernels](https://mirage.io/tmpl/wiki/xen-boot).

For the `Macosx` and `Unix` backends, running as a normal process should suffice.

For summaries
by backend that assume the `hello` example, see below:

Unix:

```
    $ cd hello
    $ mirage configure -t unix
    $ make depend
    $ make
    $ ./hello
```

Xen:

```
    $ cd hello
    $ mirage configure -t xen
    $ make depend
    $ make
    $ sudo xl create xen.xl -c
```

Ukvm:

```
    $ cd hello
    $ mirage configure -t ukvm
    $ make depend
    $ make
    $ ./ukvm-bin hello.ukvm
```

Virtio:

```
    $ cd hello
    $ mirage configure -t virtio
    $ make depend
    $ make
    $ solo5-run-virtio ./https.virtio
```

Macosx:

```
    $ cd hello
    $ mirage configure -t macosx
    $ make depend
    $ make
    $ ./hello
```

Qubes:

Some specific setup in the QubesOS manager is necessary to be able to easily run
MirageOS unikernels -- please see [the qubes-test-mirage readme](https://github.com/talex5/qubes-test-mirage) for details.

```
    $ cd hello
    $ mirage configure -t qubes
    $ make depend
    $ make
    $ ~/test-unikernel hello.xen unikernel-test-vm
```

#### To clean up after building a unikernel:

    $ make clean

