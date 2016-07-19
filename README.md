[![Build Status](https://travis-ci.org/mirage/mirage-skeleton.png?branch=master)](https://travis-ci.org/mirage/mirage-skeleton)

Prerequisites
=============

- Install latest OPAM (at least 1.1.0), following instructions at
<http://opam.ocaml.org/>

- Install the `mirage` package with OPAM, updating your package first if
necessary:

```
    $ opam update -u
    $ opam install mirage
    $ eval `opam config env`
```

- Please ensure that your Mirage command-line version is at least 2.7.0 before
proceeding:

```
    $ mirage --version
    2.7.0
```

Configure, Build, Run
=====================

Each example is invoked in the same way:

    $ make ${example}-configure
    $ make ${example}-build

So to configure the hello example, run `make hello-configure`, and to build it, run `make hello-build`.
The binaries built in the process can then be found in the example's directory:

    $ cd hello/
    $ ./mir-console
    Hello World!
    Hello World!
    ...

If you want to clean up afterwards, the usual does the trick:

    $ make ${example}-clean

Some global targets are also provided in the `Makefile`:

    $ make all                   ## equivalent to ...
    $ make configure build
    $ make clean

Details
-------

The `Makefile` simply invokes sample-specific `sample/Makefile`. Each of those
invokes the `mirage` command-line tool to configure, build and run the sample,
passing flags and environment as directed. The `mirage` command-line tool
assumes that the [OPAM](http://opam.ocaml.org/) package manager is present and
is used to manage installation of an OCaml dependencies.

The `mirage` command-line tool supports four commands, each of which either
uses `config.ml` in the current directory or supports passing a `config.ml`
directly.

### To configure a unikernel before building:

    $ mirage configure [-f config.ml] [-t unix|-t xen]

The boot target is selected via `-t unix` or `-t xen`. The default is selected
based on the presence of target-specific packages, e.g., `mirage-unix` or
`mirage-xen`.

### To build a unikernel:

    $ make

The output will be created next to the `config.ml` file used.

### To run a unikernel:

    $ make run

This will either execute the native binary created (if on `-t unix`) or create
a default `.xl` configuration file (if on `-t xen`). In the latter case you
will need to edit the generated configuration file appropriately if you wish
to use block or network devices.

### To clean up after building a unikernel:

    $ make clean

Experimental Modules
--------------------

The unikernels in this repository can also be used as a test suite for Mirage.  The `master` branch should work with packages released in the main opam repository, and the `mirage-dev` branch will work with packages held in a staging repository for experimental Mirage packages.  To use the staging repository:

    $ opam remote add mirage-dev git://github.com/mirage/mirage-dev

Then upgrade packages and build the `mirage-dev` branch of mirage-skeleton.
