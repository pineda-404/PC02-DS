#!/usr/bin/env bash

set -euo pipefail

# Cargar .env si existe
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

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

# URLs que exceden umbral
echo "URLs que exceden umbral de ${BUDGET_MS}ms:" >>"$OUTPUT_REPORT"
excede=0

# Lee los valores de $INPUT_CSV
while IFS=',' read -r url _ time_total rest; do
    [[ "$time_total" == "0" ]] && continue

    time_ms=$(awk -v t="$time_total" 'BEGIN {printf "%.2f", t * 1000}')

    if (($(awk -v t="$time_ms" -v b="$BUDGET_MS" 'BEGIN {print (t > b)}'))); then
        echo "  - $url: ${time_ms}ms" >>"$OUTPUT_REPORT"
        excede=$((excede + 1))
    fi
done < <(tail -n +2 "$INPUT_CSV")

if [ "$excede" -eq 0 ]; then
    echo "  Ninguna URL excede el umbral" >>"$OUTPUT_REPORT"
fi
