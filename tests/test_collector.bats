setup() {
    export OUTPUT_FILE="out/test_metrics.csv"
    mkdir -p out
}

teardown() {
    rm -f "$OUTPUT_FILE" #
}

@test "collector genera CSV con header y registra codigo 200" {
    # Arrange
    export TARGETS="https://google.com"
    # Act
    run bash src/collector.sh
    # Assert
    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ] #
    # Verificar header
    header=$(head -n1 "$OUTPUT_FILE") #
    [ "$header" = "url,status_code,time_total,time_connect,time_starttransfer" ]
    # Verificar que registro codigo 200
    grep -q ",200," "$OUTPUT_FILE" #
}