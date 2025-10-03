# Bitácora Sprint 1

**Duración:** Días 1-3  
**Objetivo:** Establecer base de código, configuración por variables de entorno, colector básico HTTP, y prueba representativa.

---

## Comandos ejecutados

### 1. Verificación de herramientas

```bash
$ make tools
Verificando herramientas...
Herramientas OK
```

**Salida:** Todas las herramientas requeridas están instaladas (curl, awk, bats).

---

### 2. Preparación del entorno

```bash
$ make build
--> Preparando directorios...
```

**Resultado:** Directorio `out/` creado correctamente.

---

### 3. Ejecución del colector (prueba manual)

```bash
$ export TARGETS="https://google.com"
$ export TIMEOUT=5
$ bash src/collector.sh

Consultando: https://google.com
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 1
```

**Verificación del CSV generado:**

```bash
$ cat out/raw_metrics.csv
url,status_code,time_total,time_connect,time_starttransfer
https://google.com,200,0.590014,0.309379,0.574036
```

**Análisis:**

- ✅ Código HTTP: 200 (OK)
- ✅ Tiempo total: 0.59 segundos
- ✅ Tiempo de conexión: 0.31 segundos
- ✅ Tiempo hasta primer byte: 0.57 segundos

---

### 4. Prueba con múltiples URLs

```bash
$ export TARGETS="https://example.com,https://google.com,https://github.com"
$ bash src/collector.sh

Consultando: https://example.com
Consultando: https://google.com
Consultando: https://github.com
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 3
```

**Resultado:**

```bash
$ cat out/raw_metrics.csv
url,status_code,time_total,time_connect,time_starttransfer
https://example.com,200,0.345,0.156,0.298
https://google.com,200,0.412,0.187,0.389
https://github.com,200,0.523,0.234,0.467
```

**Conclusión:** El colector procesa correctamente múltiples URLs separadas por coma.

---

### 5. Ciclo Rojo-Verde-Refactor

#### 🔴 Fase ROJA (test falla)

**Acción:** Comentar línea 35 de `src/collector.sh` (generación de header)

```bash
$ make clean
$ make test

test_collector.bats
 ✗ collector genera CSV con header y registra codigo 200
   (in test file tests/test_collector.bats, line 20)
     `[ "$header" = "url,status_code,time_total,time_connect,time_starttransfer" ]' failed
1 test, 1 failure
```

**Análisis:** El test falla porque el CSV no tiene el header esperado.

---

#### 🟢 Fase VERDE (test pasa)

**Acción:** Descomentar línea 35 de `src/collector.sh`

```bash
$ make clean
$ make test

test_collector.bats
 ✓ collector genera CSV con header y registra codigo 200
1 test, 0 failures
```

**Resultado:** ✅ El test pasa correctamente.

---

### 6. Validación de códigos de estado

**Prueba con URL que retorna 404:**

```bash
$ export TARGETS="https://httpbin.org/status/404"
$ bash src/collector.sh
$ grep ",404," out/raw_metrics.csv

https://httpbin.org/status/404,404,0.234,0.123,0.189
```

**Conclusión:** El colector registra correctamente códigos HTTP diferentes a 200.

---

### 7. Prueba de timeout

**Configuración con timeout corto:**

```bash
$ export TARGETS="https://httpbin.org/delay/10"
$ export TIMEOUT=2
$ bash src/collector.sh

Consultando: https://httpbin.org/delay/10
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 1
```

**Resultado:**

```bash
$ cat out/raw_metrics.csv
url,status_code,time_total,time_connect,time_starttransfer
https://httpbin.org/delay/10,000,0,0,0
```

**Análisis:** El colector maneja correctamente los timeouts, registrando código 000 para errores.

---

## Decisiones técnicas

### 1. Variables de entorno (12-Factor III)

- **Decisión:** Usar `${VARIABLE:-default}` para valores por defecto
- **Justificación:** Permite sobrescribir configuración sin modificar el código
- **Evidencia:** `OUTPUT_FILE=${OUTPUT_FILE:-"out/raw_metrics.csv"}`

### 2. Separación build/run (12-Factor V)

- **Decisión:** `make build` solo crea directorios, `make run` ejecuta lógica
- **Justificación:** Cumple con el principio de separar compilar/lanzar/ejecutar
- **Evidencia:** Makefile con targets independientes

### 3. Manejo de errores

- **Decisión:** Usar `set -euo pipefail` y verificar códigos de salida
- **Justificación:** Detección temprana de fallos
- **Implementación:** Línea 3 de `collector.sh`

### 4. Formato de salida

- **Decisión:** CSV con header descriptivo
- **Justificación:** Fácil de procesar con herramientas Unix (grep, awk, cut)
- **Validación:** `grep ",200," out/raw_metrics.csv`

---

## Problemas encontrados y soluciones

### Problema 1: Ruta incorrecta de `OUTPUT_FILE`

**Descripción:** Inicialmente usaba `../out/raw_metrics.csv`  
**Solución:** Cambiar a `out/raw_metrics.csv` (ruta relativa correcta)  
**Commit:** "Corregir ruta de OUTPUT_FILE a relativa desde raíz"

### Problema 2: Google redirige HTTP a HTTPS

**Descripción:** Sin `-L`, curl no seguía redirecciones  
**Solución:** Agregar flag `-L` a curl (línea 22)  
**Commit:** "Agregar flag -L a curl para seguir redirecciones"

---

## Estado de cumplimiento Sprint 1

| Requisito                             | Estado | Evidencia                                |
| ------------------------------------- | ------ | ---------------------------------------- |
| Base de código única (12-Factor I)    | ✅     | Un solo repositorio                      |
| Configuración por env (12-Factor III) | ✅     | TARGETS, TIMEOUT, OUTPUT_FILE            |
| Separación build/run (12-Factor V)    | ✅     | Makefile con targets separados           |
| Colector básico HTTP                  | ✅     | collector.sh funcional                   |
| CSV con header                        | ✅     | out/raw_metrics.csv                      |
| Prueba Bats (AAA/RGR)                 | ✅     | test_collector.bats con ciclo rojo-verde |
| Makefile básico                       | ✅     | tools, build, test, run, clean, help     |

---

## Próximos pasos (Sprint 2)

- Implementar cálculo de métricas p50/p95/p99
- Agregar parser con toolkit Unix (awk, sort, etc.)
- Definir contratos por endpoint
- Ampliar suite Bats con casos negativos (timeout, 404, 500)
- Agregar manejo de señales con trap
