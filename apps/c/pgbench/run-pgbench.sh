#!/bin/bash

set -eu

[ -z "${PGHOST:-}" ] && export PGHOST=localhost
[ -z "${PGPORT:-}" ] && export PGPORT=5432
[ -z "${PGDATABASE:-}" ] && export PGDATABASE="local"
[ -z "${PGUSER:-}" ] && export PGUSER="root"
[ -z "${PGPASSWORD:-}" ] && export PGPASSWORD="1234"
[ -z "${PGBENCH_TESTTIME:-}" ] && export PGBENCH_TESTTIME="10"


for BENCHMARK in select-only simple-update tpcb-like; do
    for PROTOCOL in simple prepared; do
        # for CLIENTS in 1 10; do
        CLIENTS=2
        echo
        echo "$BENCHMARK $PROTOCOL, $CLIENTS clients"
        CMD="pgbench -n -T $PGBENCH_TESTTIME -b $BENCHMARK --protocol=$PROTOCOL --client=$CLIENTS"
        echo "cmd: $CMD"
        eval "$CMD"
        # done
    done
done
