#!/usr/bin/env bash

set -euo pipefail

INPUT_CSV=${INPUT_CSV:-"out/raw_metrics.csv"}
OUTPUT_REPORT="out/report.txt"
BUDGET_MS=${BUDGET_MS:-500}

# Verificar que existe el CSV
if [ ! -f "$INPUT_CSV" ]; then
    echo "ERROR: No existe $INPUT_CSV" >&2
    exit 1
fi

# Crear reporte
echo "---Reporte de Analisis---" >"$OUTPUT_REPORT"
echo "" >>"$OUTPUT_REPORT"

# Distribucion de codigos HTTP
echo "Distribucion de codigos HTTP:" >>"$OUTPUT_REPORT"
tail -n +2 "$INPUT_CSV" | cut -d',' -f2 | sort | uniq -c | while read count code; do
    echo "  Codigo $code: $count URLs" >>"$OUTPUT_REPORT"
done
echo "" >>"$OUTPUT_REPORT"
