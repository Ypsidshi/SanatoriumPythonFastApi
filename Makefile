.DEFAULT_GOAL := help

.PHONY: help up down logs init run test clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  %-6s %s\n", $$1, $$2}'

up: ## Start SQL Server + API in Docker (http://localhost:8000/docs)
	docker compose up --build -d

down: ## Stop the stack and drop the database volume
	docker compose down -v

logs: ## Follow the API logs
	docker compose logs -f api

init: ## Re-apply sql/*.sql to the running database
	docker compose run --rm db-init

run: ## Run the API locally against DATABASE_URL from .env
	uvicorn app.main:app --reload

test: ## Run the smoke tests against a running API
	pytest -q tests

clean: ## Remove local Python caches
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
