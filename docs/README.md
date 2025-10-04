# Proyecto: Registro de Latencias y Códigos HTTP con contratos

Monitor en Bash que consulta URLs y calcula métricas de latencia y distribución de códigos HTTP. Proyecto para el curso de Desarrollo de Software.

---

## Requisitos

- `bash`
- `curl`
- `awk`, `grep`, `sed`, `cut`, `sort`, `uniq`
- `bats` (para tests)
- `bc`

Instalar bats:

```bash
sudo apt install bats  # Linux
brew install bats-core # macOS
```

---

## Variables de entorno

| Variable      | Descripción                           | Default               | Ejemplo                                            |
| ------------- | ------------------------------------- | --------------------- | -------------------------------------------------- |
| `TARGETS`     | URLs a consultar (separadas por coma) | `https://google.com`  | `TARGETS="https://example.com,https://google.com"` |
| `TIMEOUT`     | Tiempo máximo de espera (segundos)    | `5`                   | `TIMEOUT=10`                                       |
| `BUDGET_MS`   | Umbral de tiempo aceptable (ms)       | `500`                 | `BUDGET_MS=300`                                    |
| `OUTPUT_FILE` | Archivo CSV de salida                 | `out/raw_metrics.csv` | -                                                  |

### Usando archivo .env

Puedes crear un archivo `.env` con las variables:

```bash
TARGETS=https://google.com,https://example.com
BUDGET_MS=500
TIMEOUT=5
```

Los scripts lo cargan automáticamente si existe.

---

## Uso

```bash
# Verificar herramientas
make tools

# Preparar entorno
make build

# Ejecutar todo
make run

# Con variables personalizadas
TARGETS="https://example.com" BUDGET_MS=300 make run

# Ejecutar tests
make test

# Limpiar
make clean
```

---

## Estructura

```
.
├── Makefile
├── .env (opcional)
├── src/
│   ├── collector.sh              # Colecta métricas con curl
│   ├── parser.sh                 # Analiza distribución de códigos y URLs que pasan el umbral
│   └── latencia_percentiles.sh  # Calcula p50/p95/p99
├── tests/
│   ├── test_collector.bats
│   ├── test_contracts.bats
│   └── test_parser.bats
├── docs/
│   ├── README.md
│   ├── bitacora-sprint-*.md
│   └── contrato-salidas.md
└── out/
    ├── raw_metrics.csv
    ├── report.txt
    └── percentiles.txt
```

---

## Archivos generados

### `out/raw_metrics.csv`

Datos crudos por URL:

```csv
url,status_code,time_total,time_connect,time_starttransfer
https://example.com,200,0.345,0.156,0.298
```

### `out/report.txt`

Distribución de códigos y URLs lentas:

```
=== Reporte de Analisis ===

Distribucion de codigos HTTP:
  Codigo 200: 2 URLs
  Codigo 404: 1 URLs

URLs que exceden umbral de 500ms:
  - https://example.com: 587.25ms
```

### `out/percentiles.txt`

Percentiles de latencia:

```
=== Metricas de Latencia ===

Total de muestras: 10

Percentiles de latencia:
  p50 (mediana): 450.23ms
  p95: 890.45ms
  p99: 1200.67ms
```

---

## Validación

```bash
# Ver si generó el CSV
test -f out/raw_metrics.csv && echo "OK"

# Buscar códigos 200
grep ",200," out/raw_metrics.csv

# Ver reporte
cat out/report.txt

# Ver percentiles
cat out/percentiles.txt
```

---

## Ejemplos

### Monitorear varias URLs

```bash
TARGETS="https://google.com,https://github.com,https://example.com" make run
```

### Cambiar umbral de latencia

```bash
BUDGET_MS=200 make run
cat out/report.txt  # Ver cuáles exceden 200ms
```

### Probar timeout

```bash
TARGETS="https://httpbin.org/delay/10" TIMEOUT=2 make run
# Debe registrar código 000 (error)
```

---

## Contratos por endpoint

Los contratos están en `tests/test_contracts.bats`. Definen qué esperamos de cada URL:

- Google debe responder 200 o 301
- GitHub debe ser rápido (< 2s)
- URLs 404 se deben registrar correctamente
- Timeouts no detienen la ejecución

```bash
make test  # Para validar contratos
```

---

## 12-Factor

**I. Base de código:** Un solo repo con Git

**III. Configuración:** Todo por variables de entorno

```bash
BUDGET_MS=300 make run  # Sin tocar código
```

**V. Build/Run/Release:**

- `make build` → prepara
- `make run` → ejecuta
- `make pack` → empaqueta

---

## Decisiones técnicas

### Por qué usamos `-L` en curl

Para seguir redirecciones y obtener el código final (200, 404, 500). Esto hace que no veamos códigos 301/302 intermedios, pero cumple con lo pedido en la pauta.

### Por qué `< <(...)` en lugar de pipe

Los pipes crean subshells y las variables no persisten:

```bash
# Mal
echo "hola" | while read x; do contador=$((contador+1)); done
echo $contador  # 0 (se perdió)

# Bien
while read x; do contador=$((contador+1)); done < <(echo "hola")
echo $contador  # 1
```

### Cálculo de percentiles

Usamos `sort` para ordenar tiempos, calculamos la posición (total \* 0.50 para p50), y extraemos con `sed`. Es más simple que usar estadísticas complejas.

---

## Problemas comunes

**"bats: command not found"**
→ Instalar bats (ver Requisitos)

**"bc: command not found"**
→ `sudo apt install bc` (Linux) o viene incluido en macOS

**Muchos timeouts**
→ Aumentar TIMEOUT: `TIMEOUT=15 make run`

**CSV vacío**
→ Verificar que las URLs son accesibles: `curl -I <url>`

---

## Notas

- Los archivos temporales de curl se limpian automáticamente con `trap`
- El script sigue funcionando aunque haya errores en algunas URLs
- Los tests usan AAA (Arrange-Act-Assert) y RGR (Rojo-Verde-Refactor)
- Ver `docs/contrato-salidas.md` para más detalles de las salidas
