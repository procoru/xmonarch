#!/bin/bash

set -e

: ${OPT_LEVEL:=""}

function compare() {
  local size=$1
  local func=$2

  local input=$(mktemp)
  local out0=$(mktemp)
  local out1=$(mktemp)
  trap "rm -f $input $out0 $out1" EXIT

  cat /dev/urandom | head -c $size | base64 > $input
  cat $input | ./hash $func > $out0
  cat $input | node ./hash.js $func > $out1

  diff $out0 $out1

  rm $input $out0 $out1
}

function build_and_run() {
  for run in {1..10}; do
    size1=$((1 + RANDOM % 128))
    size2=$((129 + RANDOM % 1000000))
    for size in 10 $size1 $size2 39; do
      for algo in keccak jh blake skein groestl; do
        echo "run=$run opt-level=\"$OPT_LEVEL\" size=$size algo=$algo"
        compare $size $algo
      done
      echo "run=$run opt-level=\"$OPT_LEVEL\" size=200 algo=oaes_key_omport_data"
      compare 200 oaes_key_import_data
      echo "run=$run opt-level=\"$OPT_LEVEL\" size=200 algo=keccakf"
      compare 200 keccakf
    done
  done
  for vecfile in blake groestl jh keccak keccakf oaes_key_import_data skein cryptonight; do
    echo "testing vecs/$vecfile vectors"
    cat vecs/${vecfile}.json | ./vectest
    cat vecs/${vecfile}.json | node ./vectest.js
  done
}

build_and_run
