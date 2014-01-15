## declare required packages

OPAM_PACKAGES="mirage mirage-net cow mirage-fs mirari cohttp"

## different PPAs required to cover the test matrix

case "$OCAML_VERSION,$OPAM_VERSION" in
    3.12.1,1.0.0) ppa=avsm/ocaml312+opam10 ;;
    3.12.1,1.1.0) ppa=avsm/ocaml312+opam11 ;;
    4.00.1,1.0.0) ppa=avsm/ocaml40+opam10 ;;
    4.00.1,1.1.0) ppa=avsm/ocaml40+opam11 ;;
    4.01.0,1.0.0) ppa=avsm/ocaml41+opam10 ;;
    4.01.0,1.1.0) ppa=avsm/ocaml41+opam11 ;;
    *) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
esac

## determine Mirage backend

case "$MIRAGE_BACKEND" in
    unix-socket) mirage_pkg="mirage-unix mirage-net-socket" ;;
    unix-direct) mirage_pkg="mirage-unix mirage-net-direct" ;;
    xen) mirage_pkg="mirage-xen" ;;
    *)
        echo Unknown backend $MIRAGE_BACKEND
        exit 1
        ;;
esac

## install OCaml and OPAM

echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
export OPAMYES=1
export OPAMVERBOSE=1
echo OCaml version
ocaml -version
echo OPAM versions
opam --version
opam --git-version

opam init
eval `opam config env`

## install Mirage

opam pin mirage git://github.com/avsm/mirage

opam install $mirage_pkg ${OPAM_PACKAGES}

## execute the build

cd $TRAVIS_BUILD_DIR
make configure
make build
