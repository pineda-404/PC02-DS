# Makefile

.PHONY: help tools build test run pack clean

SHELL := /bin/bash
OUT_DIR := out
DIST := dist
RELEASE ?= v1.0.0-sprint3

help: ## Mostrar ayuda
	@echo "Targets disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		sed -E 's/^([a-zA-Z_-]+):.*?## (.*)/  make \1 \t- \2/'

tools: ## Verificar herramientas necesarias
	@echo "Verificando herramientas..."
	@command -v curl >/dev/null || { echo "ERROR: curl no está instalado"; exit 1; }
	@command -v awk >/dev/null || { echo "ERROR: awk no está instalado"; exit 1; }
	@command -v grep >/dev/null || { echo "ERROR: grep no está instalado"; exit 1; }
	@command -v bats >/dev/null || echo "ADVERTENCIA: bats no está instalado"
	@echo "Herramientas OK"

build: ## Preparar directorios de salida para métricas
	@echo "--> Preparando entorno"
	@mkdir -p $(OUT_DIR)
	@echo "Directorio $(OUT_DIR)/ creado"

test: tools ## Ejecutar pruebas automáticas con bats
	@echo "--> Ejecutando suite de pruebas..."
	@if command -v bats >/dev/null; then \
		bats tests/; \
	else \
		echo "ERROR: bats no está instalado. Instalar con: npm install -g bats"; \
		exit 1; \
	fi

run: build ## Ejecutar colector de métricas
	@echo "--> Recolectando métricas..."
	@bash src/collector.sh
	@echo ""
	@echo "Generando reporte..."
	@bash src/parser.sh
	@echo ""
	@echo "Calculando percentiles..."
	@bash src/latencia_percentiles.sh
	@echo ""
	@echo "=== Resultados ==="
	@cat $(OUT_DIR)/report.txt
	@echo ""
	@cat $(OUT_DIR)/percentiles.txt

pack: build test ## Generar paquete reproducible en dist/
	@echo "Generando paquete $(RELEASE)..."
	@mkdir -p $(DIST)
	@tar -czf $(DIST)/http-latency-monitor-$(RELEASE).tar.gz \
		src/ tests/ docs/ Makefile .env.example
	@echo "✓ Paquete: $(DIST)/http-latency-monitor-$(RELEASE).tar.gz"

clean: ## Limpiar archivos generados en el directorio de salida
	@echo "Limpiando..."
	@rm -rf $(OUT_DIR)/*
	@rm -rf $(DIST)
	@echo "Limpieza completada"