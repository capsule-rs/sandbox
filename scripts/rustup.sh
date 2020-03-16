#!/usr/bin/env bash

## Version we recommend.
RUSTUP_TOOLCHAIN=${1:-stable}

## Note: make sure cargo is your PATH or sourced via `source $HOME/.cargo/env`.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUSTUP_TOOLCHAIN \
  && source $HOME/.cargo/env \
  && rustup component add rust-src \
  && rustup default $RUSTUP_TOOLCHAIN \
  && rm -rf .cargo/registry
