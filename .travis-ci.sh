PACKAGES="lwt ssl mirage cstruct ipaddr io-page crunch"

## different PPAs required to cover the test matrix

case "$OCAML_VERSION,$OPAM_VERSION" in
    4.01.0,1.1.0) ppa=avsm/ocaml41+opam11 ;;
    4.02.0,1.1.0) ppa=avsm/ocaml42+opam11 ;;
    4.01.0,1.2.0) ppa=avsm/ocaml41+opam12 ;;
    4.02.0,1.2.0) ppa=avsm/ocaml42+opam12 ;;
    *) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
esac

## install OCaml and OPAM

echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
export OPAMYES=1
echo OCaml version
ocaml -version
echo OPAM versions
opam --version
opam --git-version

git config --global user.name "Travis"
git config --global user.email travis@example.com

opam init git://github.com/ocaml/opam-repository > /dev/null 2>&1
opam remote add mirage-dev git://github.com/mirage/mirage-dev

eval `opam config env`

## install Mirage
opam install $PACKAGES

## execute the build

cd $TRAVIS_BUILD_DIR
make configure MODE=$MIRAGE_BACKEND
make depend
make build
