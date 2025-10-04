# Bitácora Sprint 1
**Proyecto:** 1 - Registro de latencias y códigos HTTP con contratos
**Equipo:** Diego Pineda García, Mateo Torres Fuero

**Video Sprint 1:** https://youtu.be/_uD9H9xt_rI

**Objetivo:** Establecer base de código, configuración por variables de entorno, colector básico HTTP, y prueba representativa.

---

## División de Responsabilidades

### Alumno 1: Diego Pineda - Lógica principal y script collector
- **Rama:** `develop`
- **Responsabilidades:** 
  - Estructura del repositorio
  - Implementación del script collector `src/collector.sh`
  - Implementación de variables de entorno

### Alumno 2: Mateo Torres - Automatización y Testing
- **Rama:** `Makefile/Mateo` `test/Mateo`
- **Responsabilidades:**
  - Creación del Makefile inicial
  - Implementación de `tests/test_collector.bats`
  - Documentación inicial

---

## Configuración e Implementación inicial

### 1. Configuración Inicial del Repositorio [DiegoPineda]

**Crear estructura base del proyecto** 
```bash
mkdir -p src tests docs
touch Makefile
git init
git checkout -b develop
```

**Resultado:**
```
Directorio creado exitosamente con estructura:
├── src/
├── tests/
├── docs/
└── Makefile
```

---

### 2. Implementación de collector.sh [DiegoPineda]

- **Propósito:** Consultar una lista de URLs mediante peticiones HTTP/HTTPS y registrar métricas de latencia y códigos de estado en formato CSV
- **Funcionalidades:**
  - Colecta de métricas HTTP
  - Manejo robusto de errores
  - Salida estructurada

**Prueba de funcionamiento:**
```bash
./src/collector.sh
```

**Salida:**
```
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 3
```

---

### 3. Creación del Makefile Inicial [MateoTorres]
- **Propósito:** Automatización de tareas principales.
- **Funcionalidades implementadas:**
  - Target `tools`: Verificar herramientas.
  - Target `build`: Preparar directorios de salida para métricas.
  - Target `test`: Ejecutar pruebas automáticas con bats.
  - Target `run`: Ejecutar colector de métricas.
  - Target `clean`: Limpiar archivos generados en el directorio de salida.


**Prueba de funcionamiento:**
```bash
make run
```

**Salida:**
```
--> Preparando directorios...
--> Ejecutando colector de métricas...
Metricas guardadas en: out/raw_metrics.csv
Total de URLs: 3
```

---

### 4. Prueba `tests/test_collector.bats` [MateoTorres]

- **Propósito:** Validación del script collector.sh siguiendo metodología AAA/RGR.
- **Setup():** Configura variable de entorno `OUTPUT_FILE` y crea directorio `out/` antes de cada test.
- **Teardown():** Limpia archivo de salida `$OUTPUT_FILE` después de cada test para garantizar independencia.
- **Test implementado:**
  - Arrange: Pepara variable de entorno `TARGETS`
  - Act: ejecuta el script
  - Assert: verifica el estado de salida, creación de `$OUTPUT_FILE`, el header y el código 200.

**Prueba de funcionamiento:**
```bash
bats tests/test_collector.bats
```

**Salida:**
```
test_collector.bats
 ✓ collector genera CSV con header y registra codigo 200

1 test, 0 failures
```

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
- Código HTTP: 200 (OK)
- Tiempo total: 0.59 segundos
- Tiempo de conexión: 0.31 segundos
- Tiempo hasta primer byte: 0.57 segundos

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

## Próximos pasos (Sprint 2)

- Implementar cálculo de métricas p50/p95/p99
- Agregar parser con toolkit Unix (awk, sort, etc.)
- Definir contratos por endpoint
- Ampliar suite Bats con casos negativos (timeout, 404, 500)
- Agregar manejo de señales con trap
