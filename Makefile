# DevSecOps Platform Makefile

# Variables
SHELL := /bin/bash
SCRIPT_DIR := $(shell pwd)

# Default target
.PHONY: help
help:
	@echo "DevSecOps Platform Make Targets:"
	@echo "---------------------------------"
	@echo "setup           : Run the full setup script"
	@echo "dev             : Run in development mode using Docker Compose"
	@echo "dev-siem        : Run development mode with SIEM components"
	@echo "clean           : Clean up all resources"
	@echo "clean-siem      : Clean up SIEM resources only"
	@echo "deploy-siem     : Deploy SIEM components only"
	@echo "deploy-full     : Deploy the full platform with SIEM"
	@echo "test            : Run tests for the Flask application"
	@echo "docker-build    : Build all Docker images"
	@echo "update-dashboards: Update the Grafana dashboards"
	@echo ""
	@echo "Run 'make <target>' to execute a specific target"

# Setup targets
.PHONY: setup
setup:
	@echo "Running setup script..."
	@./setup.sh

.PHONY: dev
dev:
	@echo "Starting development environment..."
	@docker compose up -d
	@echo "Development environment started!"
	@echo "Access URLs:"
	@echo "  - Flask App: http://localhost:5000"
	@echo "  - SonarQube: http://localhost:9000"
	@echo "  - Grafana:   http://localhost:3000"
	@echo "  - Loki:      http://localhost:3100"

.PHONY: dev-siem
dev-siem:
	@echo "Starting development environment with SIEM components..."
	@docker compose -f docker-compose.siem.yml up -d
	@echo "Development environment with SIEM started!"
	@echo "Access URLs:"
	@echo "  - Flask App: http://localhost:5000"
	@echo "  - SonarQube: http://localhost:9000"
	@echo "  - Grafana:   http://localhost:3000"
	@echo "  - Loki:      http://localhost:3100"
	@echo "  - Webhook:   http://localhost:8080/webhook"

.PHONY: clean
clean:
	@echo "Cleaning up resources..."
	@bash -c "source ./setup.sh && cleanup_all"

.PHONY: clean-siem
clean-siem:
	@echo "Cleaning up SIEM resources..."
	@bash -c "source ./setup.sh && source ./siem/siem-functions.sh && cleanup_siem"

.PHONY: deploy-siem
deploy-siem:
	@echo "Deploying SIEM components..."
	@bash -c "source ./setup.sh && source ./siem/siem-functions.sh && deploy_siem"

.PHONY: deploy-full
deploy-full:
	@echo "Deploying full platform with SIEM..."
	@bash -c "source ./setup.sh && show_main_menu && echo '11' && read -t 1"

# Test and build targets
.PHONY: test
test:
	@echo "Running tests..."
	@cd app && python -m pytest tests/

.PHONY: docker-build
docker-build:
	@echo "Building Docker images..."
	@docker build -t flask-k8s-app:latest ./app
	@docker build -t jenkins-custom:latest ./jenkins

.PHONY: update-dashboards
update-dashboards:
	@echo "Updating Grafana dashboards..."
	@bash -c "source ./setup.sh && source ./siem/siem-functions.sh && microk8s kubectl delete configmap -n monitoring siem-dashboard siem-alerts --ignore-not-found && microk8s kubectl create configmap siem-dashboard -n monitoring --from-file=siem-dashboard.json=siem/dashboards/siem-dashboard.json && microk8s kubectl create configmap siem-alerts -n monitoring --from-file=alert-rules.json=siem/dashboards/alert-rules.json && microk8s kubectl annotate configmap siem-dashboard -n monitoring grafana_dashboard=1 --overwrite"
	@echo "Dashboards updated!"
