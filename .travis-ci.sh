PACKAGES="lwt ssl"

## different PPAs required to cover the test matrix

case "$OCAML_VERSION" in
    3.12.1) ppa=avsm/ocaml312+opam11 ;;
    4.00.1) ppa=avsm/ocaml40+opam11 ;;
    4.01.0) ppa=avsm/ocaml41+opam11 ;;
    *) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
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

uname -a

opam init
eval `opam config env`

opam remote add -k git \
    mirage-split https://github.com/mirage/opam-repository#mirage-1.1.0

## install Mirage

opam install $PACKAGES mirage mirage-$MIRAGE_BACKEND

## execute the build

cd $TRAVIS_BUILD_DIR
MODE=$MIRAGE_BACKEND make configure
make build
