# Contrato de Salidas

Este documento describe qué archivos genera nuestros scripts y cómo validarlos.

---

## Archivos en `out/`

### 1. `raw_metrics.csv`

**Qué es:** Datos crudos de cada URL consultada.

**Formato:**

```csv
url,status_code,time_total,time_connect,time_starttransfer
https://example.com,200,0.345,0.156,0.298
https://google.com,404,0.412,0.187,0.389
```

**Columnas:**

- `url`: URL consultada
- `status_code`: Código HTTP (200, 404, 500, etc. o 000 si falló)
- `time_total`: Tiempo total en segundos
- `time_connect`: Tiempo de conexión TCP en segundos
- `time_starttransfer`: Tiempo hasta primer byte en segundos

**Cómo validar:**

```bash
# Ver si existe
test -f out/raw_metrics.csv

# Ver contenido
cat out/raw_metrics.csv

# Contar líneas (debe ser N+1 donde N = número de URLs)
wc -l out/raw_metrics.csv

# Buscar código 200
grep ",200," out/raw_metrics.csv
```

---

### 2. `report.txt`

**Qué es:** Reporte con distribución de códigos HTTP y URLs que tardan mucho.

**Formato:**

```
=== Reporte de Analisis ===

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  - https://example.com: 587.25ms
```

**Secciones:**

1. Cuántos códigos de cada tipo (200, 404, 500, etc.)
2. Qué URLs se pasaron del `BUDGET_MS`

**Cómo validar:**

```bash
# Ver si existe
test -f out/report.txt

# Ver contenido
cat out/report.txt

# Buscar distribución
grep "Distribucion de codigos HTTP" out/report.txt

# Buscar URLs lentas
grep "exceden umbral" out/report.txt
```

---

### 3. `percentiles.txt`

**Qué es:** Estadísticas de latencia (p50/p95/p99).

**Formato:**

```
=== Metricas de Latencia ===

Total de muestras: 10

Percentiles de latencia:
  p50 (mediana): 450.23ms
  p95: 890.45ms
  p99: 1200.67ms
```

**Qué significan:**

- **p50 (mediana):** 50% de las URLs fueron más rápidas que este valor
- **p95:** 95% de las URLs fueron más rápidas (solo el 5% más lento está arriba)
- **p99:** 99% de las URLs fueron más rápidas (solo el 1% más lento está arriba)

**Cómo validar:**

```bash
# Ver si existe
test -f out/percentiles.txt

# Ver contenido
cat out/percentiles.txt

# Verificar que tiene los percentiles
grep "p50" out/percentiles.txt
grep "p95" out/percentiles.txt
grep "p99" out/percentiles.txt
```

---

## Archivos en `dist/` (Sprint 3)

### 1. `proyecto-vX.Y.Z.tar.gz`

**Qué es:** Paquete comprimido con todo el proyecto.

**Contiene:**

- `src/` (scripts)
- `tests/` (pruebas Bats)
- `docs/` (documentación)
- `Makefile`

**Cómo validar:**

```bash
# Ver si existe
test -f dist/proyecto-v1.0.0.tar.gz

# Listar contenido sin extraer
tar -tzf dist/proyecto-v1.0.0.tar.gz

# Extraer
tar -xzf dist/proyecto-v1.0.0.tar.gz
```

---

## Variables que afectan las salidas

| Variable      | Efecto                                                             |
| ------------- | ------------------------------------------------------------------ |
| `TARGETS`     | Define qué URLs aparecen en `raw_metrics.csv`                      |
| `BUDGET_MS`   | Define qué URLs aparecen en la sección de umbrales de `report.txt` |
| `OUTPUT_FILE` | Cambia dónde se guarda el CSV                                      |

---

## Garantías

1. Si `make run` termina sin errores, todos los archivos deben existir.
2. Ejecutar `make run` dos veces con los mismos parámetros genera las mismas salidas (idempotencia).
3. El formato del CSV y los reportes no cambia entre ejecuciones.

---

## Ejemplo completo

```bash
# Generar salidas
TARGETS="https://example.com,https://google.com" BUDGET_MS=300 make run

# Validar
test -f out/raw_metrics.csv && echo "✓ CSV OK"
test -f out/report.txt && echo "✓ Reporte OK"
test -f out/percentiles.txt && echo "✓ Percentiles OK"

# Ver resultados
cat out/report.txt
cat out/percentiles.txt
```

---

## Notas

- Si una URL falla (timeout o error de red), se registra con código 000 y tiempos en 0.
- Los percentiles solo se calculan con URLs exitosas (ignora las que tienen tiempo 0).
- El reporte de umbrales puede estar vacío si ninguna URL excede `BUDGET_MS`.
