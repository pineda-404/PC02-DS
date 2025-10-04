# Bitácora Sprint 2

**Proyecto:** 1 - Registro de latencias y códigos HTTP con contratos
**Equipo:** Diego Pineda García, Mateo Torres Fuero

**Video Sprint 2:** https://youtu.be/Nylel6rmd4U

**Objetivo:** Implementar análisis de métricas, parser con toolkit Unix, contratos por endpoint, y ampliar suite de pruebas con casos negativos.

---

## División de Responsabilidades

### Alumno 1: Diego Pineda - Parser y análisis de métricas

- **Rama:** `scripts/diego-pineda`
- **Responsabilidades:**
  - Implementación del script `src/parser.sh`
  - Cálculo de métricas estadísticas
  - Generación de reportes con toolkit Unix (awk, sort, uniq)

### Alumno 2: Mateo Torres - Contratos y testing avanzado

- **Rama:** `test/Mateo` `Makefile/Mateo`
- **Responsabilidades:**
  - Implementación de `tests/test_contracts.bats`
  - Casos de prueba negativos (timeout, 404, 500)
  - Validación de contratos por endpoint

---

## Implementación Sprint 2

### 1. Implementación de parser.sh [DiegoPineda]

**Propósito:** Analizar CSV de métricas y generar reporte con distribución de códigos HTTP y URLs que exceden umbral de latencia.

**Funcionalidades implementadas:**

- Lectura y procesamiento de `out/raw_metrics.csv`
- Distribución de códigos HTTP usando `cut`, `sort`, `uniq -c`
- Detección de URLs que exceden `BUDGET_MS` (umbral configurable)
- Conversión de tiempo total de segundos a milisegundos
- Generación de reporte en `out/report.txt`

**Decisiones técnicas:**

- Usar `tail -n +2` para saltar header del CSV
- `cut -d',' -f2` para extraer columna de status codes
- `awk` para convertir segundos a milisegundos y comparaciones flotantes
- Variable `BUDGET_MS` configurable vía entorno (default: 500ms)

**Prueba de funcionamiento:**

```bash
$ export BUDGET_MS=500
$ bash src/parser.sh
```

**Salida generada en `out/report.txt`:**

```
---Reporte de Analisis---

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  - https://google.com: 590.01ms
  Ninguna URL excede el umbral
```

---

### 2. Implementación de cleanup con trap [DiegoPineda]

**Propósito:** Garantizar limpieza de archivos temporales incluso si el script se interrumpe abruptamente.

**Decisiones técnicas:**

- **Decisión:** Usar `trap` para capturar señales EXIT, INT (Ctrl+C), TERM
- **Justificación:** 12-Factor IX (Disposability) - el proceso debe terminar limpiamente
- **Implementación:** Función `cleanup()` que elimina archivos temporales de curl

**Código implementado (líneas 8-11):**

````bash
cleanup() {
    rm -f /tmp/curl_format_* 2>/dev/null || true
}
trap cleanup EXIT INT TERM

---

### 3. Integración parser en Makefile [MateoTorres]

**Modificación del target `run`:**
```makefile
run: build
	@echo "--> Recolectando métricas..."
	@bash src/collector.sh
	@echo ""
	@echo "Generando reporte..."
	@bash src/parser.sh
	@echo ""
	@echo "=== Resultados ==="
	@cat $(OUT_DIR)/report.txt
````

**Prueba de integración:**

```bash
$ make clean
$ make run

--> Preparando entorno
Directorio out/ creado
--> Recolectando métricas...
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 3

Generando reporte...

=== Resultados ===
---Reporte de Analisis---

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  Ninguna URL excede el umbral
```

---

### 4. Implementación de test_contracts.bats [MateoTorres]

**Propósito:** Validar contratos específicos por endpoint y casos negativos.

**Tests implementados:**

#### Test 1: Contrato positivo - Google responde exitosamente

```bash
@test "contrato: Google debe responder exitosamente (200 o 301)" {
    export TARGETS="https://www.google.com"
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    code=$(awk -F',' 'NR==2 {print $2}' "$OUTPUT_FILE")
    [[ "$code" == "200" ]] || [[ "$code" == "301" ]]
}
```

**Justificación:** Google puede responder con 200 (OK) o 301 (redirección permanente) dependiendo de la región.

#### Test 2: Contrato de performance - GitHub debe ser rápido

```bash
@test "contrato: GitHub debe ser rapido (< 2s)" {
    export TARGETS="https://github.com"
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    latency=$(awk -F',' 'NR==2 {print $3}' "$OUTPUT_FILE")
    (($(echo "$latency < 2.0" | bc -l)))
}
```

**Justificación:** Validar latencia para endpoints críticos.

#### Test 3: Caso negativo - URL 404

```bash
@test "contrato negativo: URL 404 debe registrarse correctamente" {
    export TARGETS="https://www.google.com/404"
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    grep -q ",404," "$OUTPUT_FILE"
}
```

**Justificación:** Verificar manejo correcto de errores HTTP.

#### Test 4: Caso negativo - Timeout

```bash
@test "contrato negativo: timeout no debe detener ejecucion" {
    export TARGETS="https://httpbin.org/delay/10"
    export TIMEOUT=2
    run bash src/collector.sh

    [ "$status" -eq 0 ]
    grep -q ",000," "$OUTPUT_FILE"
}
```

**Justificación:** El sistema debe ser resiliente ante timeouts y continuar procesando otras URLs.

---

### 5. Actualización del target test [MateoTorres]

**Modificación en Makefile:**

```makefile
test: tools
	@echo "--> Ejecutando suite de pruebas..."
	@if command -v bats >/dev/null; then \
		bats tests/; \
	else \
		echo "ERROR: bats no está instalado. Instalar con: npm install -g bats"; \
		exit 1; \
	fi
```

**Ahora ejecuta todos los tests en `tests/`:**

```bash
$ make test

--> Ejecutando suite de pruebas...
test_collector.bats
 ✓ collector genera CSV con header y registra codigo 200

test_contracts.bats
 ✓ contrato: Google debe responder exitosamente (200 o 301)
 ✓ contrato: GitHub debe ser rapido (< 2s)
 ✓ contrato negativo: URL 404 debe registrarse correctamente
 ✓ contrato negativo: timeout no debe detener ejecucion

5 tests, 0 failures
```

---

## Comandos ejecutados

### 1. Ejecución completa del pipeline

```bash
$ make clean
Limpiando...
Limpieza completada

$ make run
--> Preparando entorno
Directorio out/ creado
--> Recolectando métricas...
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 3

Generando reporte...

=== Resultados ===
---Reporte de Analisis---

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  Ninguna URL excede el umbral
```

---

### 2. Validación del reporte generado

```bash
$ cat out/report.txt

---Reporte de Analisis---

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  Ninguna URL excede el umbral
```

---

### 3. Prueba con umbral más bajo

```bash
$ export BUDGET_MS=300
$ bash src/parser.sh
$ cat out/report.txt

---Reporte de Analisis---

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 300ms:
  - https://google.com: 590.01ms
  - https://example.com: 345.20ms
```

El parser detecta correctamente URLs que exceden el umbral configurable.

---

### 4. Validación de caso negativo: timeout

```bash
$ export TARGETS="https://httpbin.org/delay/10"
$ export TIMEOUT=2
$ bash src/collector.sh

Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 1

$ cat out/raw_metrics.csv
url,status_code,time_total,time_connect,time_starttransfer
https://httpbin.org/delay/10,000,0,0,0
```

El sistema maneja timeouts sin interrumpir la ejecución (código 000).

---

### 5. Validación de caso negativo: 404

```bash
$ export TARGETS="https://httpbin.org/status/404"
$ bash src/collector.sh

$ grep ",404," out/raw_metrics.csv
https://httpbin.org/status/404,404,0.234567,0.123456,0.189012
```

Los códigos HTTP no exitosos se registran correctamente.

---

## Decisiones técnicas

### 1. Parser con toolkit Unix

- **Decisión:** Usar `awk`, `cut`, `sort`, `uniq` en lugar de Python/Node.js
- **Justificación:** Cumple con 12-Factor XI (Logs como streams), procesamiento eficiente de CSVs
- **Evidencia:** `tail -n +2 "$INPUT_CSV" | cut -d',' -f2 | sort | uniq -c`

### 2. Conversión de tiempo a milisegundos

- **Decisión:** Usar `awk` para multiplicar por 1000
- **Justificación:** Formato más legible para humanos (590ms vs 0.59s)
- **Implementación:** `awk -v t="$time_total" 'BEGIN {printf "%.2f", t * 1000}'`

### 3. Contratos por endpoint

- **Decisión:** Tests específicos por servicio (Google, GitHub)
- **Justificación:** Validar comportamiento esperado de servicios externos
- **Ejemplo:** GitHub debe responder en < 2 segundos

### 4. Manejo de timeouts

- **Decisión:** Registrar `000` para timeouts, no detener ejecución
- **Justificación:** Resiliencia del sistema (12-Factor IX: Disposability)
- **Evidencia:** `if [ $? -eq 0 ]; then ... else echo "...,000,0,0,0"; fi`

### 5. Configuración de umbral via entorno

- **Decisión:** `BUDGET_MS` configurable (default: 500ms)
- **Justificación:** 12-Factor III (Config), permite ajustar SLA sin cambiar código
- **Implementación:** `BUDGET_MS=${BUDGET_MS:-500}`

---

## Próximos pasos (Sprint 3)

- Implementar cálculo de percentiles (p50/p95/p99)
- Implementar caché incremental
- Mejorar reporte
