# Makefile

.PHONY: tools build test run clean

SHELL := /bin/bash
OUT_DIR := out

tools: ## Verificar herramientas necesarias
	@echo "Verificando herramientas..."
	@command -v curl >/dev/null || { echo "ERROR: curl no instalado"; exit 1; }
	@command -v awk >/dev/null || { echo "ERROR: awk no instalado"; exit 1; }
	@command -v bats >/dev/null || echo "ADVERTENCIA: bats no instalado"
	@echo "Herramientas OK"

build: ## Preparar directorios de salida para métricas
	@echo "--> Preparando directorios..."
	@mkdir -p $(OUT_DIR)

test: tools ## Ejecutar pruebas automáticas con bats
	@echo "--> Ejecutando pruebas..."
	@bats tests/

run: build ## Ejecutar colector de métricas
	@echo "--> Ejecutando colector de métricas..."
	@bash src/collector.sh

clean: ## Limpiar archivos generados en el directorio de salida
	@echo "Limpiando..."
	@rm -rf $(OUT_DIR)/*
	@echo "Limpieza OK"