#!/usr/bin/env bash

set -euo pipefail

INPUT_CSV=${INPUT_CSV:-"out/raw_metrics.csv"}
OUTPUT_PERCENTILES="out/percentiles.txt"

# Verificar que existe el CSV
if [ ! -f "$INPUT_CSV" ]; then
    echo "ERROR: No existe $INPUT_CSV" >&2
    exit 1
fi

# Extraer tiempos, ordenarlos y guardar en archivo temporal
TEMP_FILE=$(mktemp)
trap "rm -f ${TEMP_FILE}" EXIT

# Extraer columna time_total, saltar header y errores (tiempo 0)
tail -n +2 "$INPUT_CSV" | cut -d',' -f3 | grep -v "^0$" | sort -n >"$TEMP_FILE"

# Contar total de muestras
total=$(wc -l <"$TEMP_FILE")

if [ "$total" -eq 0 ]; then
    echo "ERROR: No hay datos validos para calcular percentiles" >&2
    exit 1
fi

# Calcular posiciones de percentiles

pos_p50=$(awk -v t="$total" 'BEGIN {printf "%.0f", t * 0.50}')
pos_p95=$(awk -v t="$total" 'BEGIN {printf "%.0f", t * 0.95}')
pos_p99=$(awk -v t="$total" 'BEGIN {printf "%.0f", t * 0.99}')

# Ajustar si posicion es 0
[ "$pos_p50" -eq 0 ] && pos_p50=1
[ "$pos_p95" -eq 0 ] && pos_p95=1
[ "$pos_p99" -eq 0 ] && pos_p99=1

# Extraer valores en esas posiciones
p50=$(sed -n "${pos_p50}p" "$TEMP_FILE")
p95=$(sed -n "${pos_p95}p" "$TEMP_FILE")
p99=$(sed -n "${pos_p99}p" "$TEMP_FILE")

# Convertir a formato de milisegundos
p50_ms=$(awk -v t="$p50" 'BEGIN {printf "%.2f", t * 1000}')
p95_ms=$(awk -v t="$p95" 'BEGIN {printf "%.2f", t * 1000}')
p99_ms=$(awk -v t="$p99" 'BEGIN {printf "%.2f", t * 1000}')

echo "=== Metricas de Latencia ===" >"$OUTPUT_PERCENTILES"
echo "" >>"$OUTPUT_PERCENTILES"
echo "Total de muestras: $total" >>"$OUTPUT_PERCENTILES"
echo "" >>"$OUTPUT_PERCENTILES"
echo "Percentiles de latencia:" >>"$OUTPUT_PERCENTILES"
echo "  p50 (mediana): ${p50_ms}ms" >>"$OUTPUT_PERCENTILES"
echo "  p95: ${p95_ms}ms" >>"$OUTPUT_PERCENTILES"
echo "  p99: ${p99_ms}ms" >>"$OUTPUT_PERCENTILES"

echo "Los datos generados estan en: $OUTPUT_PERCENTILES"
