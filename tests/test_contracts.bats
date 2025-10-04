#!/usr/bin/env bats
# tests/test_contracts.bats
# Valida contratos especificos por endpoint

setup() {
    export OUTPUT_FILE="out/test_metrics.csv"
    mkdir -p out
}

teardown() {
    rm -f "$OUTPUT_FILE"
}

@test "contrato: Google debe responder exitosamente (200 o 301)" {
    export TARGETS="https://www.google.com"
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    code=$(awk -F',' 'NR==2 {print $2}' "$OUTPUT_FILE")
    [[ "$code" == "200" ]] || [[ "$code" == "301" ]]
}

@test "contrato: GitHub debe ser rapido (< 2s)" {
    export TARGETS="https://github.com"
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    latency=$(awk -F',' 'NR==2 {print $3}' "$OUTPUT_FILE")
    (($(echo "$latency < 2.0" | bc -l)))
}
