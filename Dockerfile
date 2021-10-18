FROM ocaml/opam:alpine-3.13
RUN sudo cp /usr/bin/opam-2.1 /usr/bin/opam
RUN opam list # to update the cache
RUN cd /home/opam/opam-repository && git pull origin master --ff-only
RUN opam update
RUN opam remote add mirage-dev https://github.com/mirage/mirage-dev.git
RUN opam install mirage.4.0.0 opam-monorepo.0.2.6 --download-only
RUN opam install mirage.4.0.0
RUN opam install opam-monorepo.0.2.6
COPY . /src
WORKDIR /src
RUN sudo chown opam -R /src
ARG MODE=spt
RUN opam exec -- make configure
RUN opam exec -- make lock
RUN opam exec -- make depends
RUN opam exec -- make pull
RUN opam exec -- make build
RUN opam exec -- make clean