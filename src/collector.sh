#!/usr/bin/env bash

set -euo pipefail

TARGETS=${TARGETS:-"https://google.com"}
TIMEOUT=${TIMEOUT:-5}
OUTPUT_FILE=${OUTPUT_FILE:-"out/raw_metrics.csv"}
# Funcion para recolectar metricas de la URL
collector_metricas() {
    local url=$1
    local format_file
    format_file=$(mktemp)

    # Formato para curl -w
    cat >"$format_file" <<'EOF'
%{http_code},%{time_total},%{time_connect},%{time_starttransfer}
EOF

    echo "Consultando: $url"
    # Hacer peticion y capturar metricas
    local metricas
    metricas=$(curl -L -w "@$format_file" -o /dev/null -s --max-time "$TIMEOUT" "$url" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "$url,$metricas"
    else
        # Si el comando falló, manejamos el error.
        echo "$url,000,0,0,0"
    fi

    rm -f "$format_file"
}

# Escribir header del CSV
echo "url,status_code,time_total,time_connect,time_starttransfer" >"$OUTPUT_FILE"

# Procesar cada URL
IFS=',' read -ra URL_ARRAY <<<"$TARGETS"

for url in "${URL_ARRAY[@]}"; do
    # Remover espacios
    url=$(echo "$url" | xargs)

    metricas=$(collector_metricas "$url")
    echo "${metricas}" >>"$OUTPUT_FILE"
done

echo "Metricas guardadas en: $OUTPUT_FILE"
echo "Total de URLs: ${#URL_ARRAY[@]}"
