# Build environment for the x86_64 Linux package.
# Ubuntu 20.04 keeps the glibc requirement of the produced binaries at 2.31.
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
      ca-certificates git python3 python3-pip build-essential \
      clang-12 lld-12 xz-utils && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/ld.lld-12 /usr/local/bin/ld.lld

# LLVM needs CMake >= 3.20; focal ships 3.16.
RUN python3 -m pip install --no-cache-dir --upgrade "pip<25" && \
    python3 -m pip install --no-cache-dir "cmake>=3.20,<4" ninja

RUN git config --global --add safe.directory '*'
WORKDIR /work
