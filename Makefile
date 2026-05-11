# DriftDater — convenience commands
# Usage: make <target>

.PHONY: help install db-init db-migrate db-upgrade seed run-backend run-frontend dev reset-db

help:
	@echo ""
	@echo "  DriftDater Development Commands"
	@echo "  ================================"
	@echo "  make install       Install all Python & Node dependencies"
	@echo "  make db-init       Initialise Flask-Migrate"
	@echo "  make db-migrate    Create a new migration"
	@echo "  make db-upgrade    Apply pending migrations"
	@echo "  make seed          Populate DB with fake data"
	@echo "  make run-backend   Start Flask on :8080"
	@echo "  make run-frontend  Start Vite on :5173"
	@echo "  make reset-db      Drop & recreate SQLite dev DB"
	@echo ""

install:
	pip install -r requirements.txt
	npm install

db-init:
	flask --app app db init

db-migrate:
	flask --app app db migrate -m "auto"

db-upgrade:
	flask --app app db upgrade

seed:
	python seed.py

run-backend:
	flask --app app --debug run --port 8080

run-frontend:
	npm run dev

reset-db:
	rm -f app/driftdater.db
	flask --app app db upgrade
	python seed.py
