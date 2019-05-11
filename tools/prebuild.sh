#!/usr/bin/env bash

# Input params
#   $SRCROOT # well, maybe we should find a way to pass it

set -x

git submodule update --remote --merge

ROOT_SOURCE="$PWD/.."

MODEL_ROOT="$ROOT_SOURCE/submodules/modelAPI"
MODEL_DIR="$ROOT_SOURCE/model/modelAPI"


if [ ! -d "$MODEL_DIR" ]; then
    mkdir -p "$MODEL_DIR"
        [ $? -eq 0 ] || exit 1

fi

cd "$MODEL_DIR"
cmake -G Xcode "$MODEL_ROOT/modelAPI"
