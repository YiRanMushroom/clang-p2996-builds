# Build environment for the x86_64 Windows (mingw-w64, UCRT) package.
# Same package set as llvm-mingw's own Dockerfile.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
      git wget bzip2 file unzip libtool pkg-config cmake build-essential \
      automake nasm gettext autopoint python3 ninja-build ca-certificates \
      curl less zip xz-utils && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN git config --global user.name "clang-p2996-builds" && \
    git config --global user.email root@localhost && \
    git config --global --add safe.directory '*'
WORKDIR /work
