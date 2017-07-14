#!/bin/bash
# run the tests given as arguments

FAILED=
# bash iterates over "$@" as default
for test; do
    ( iverilog -o ${test}vp ${test%%-*}.v $test && vvp -N ${test}vp ) || export FAILED="$FAILED $test"
done

if [ ! -z "$FAILED" ]; then
    echo "#ERR: failed tests: $FAILED"
    exit 1
else
    exit 0
fi
													
													
