#!/bin/sh -e

# TODO: generate random env values for local development

# Build and run containers
docker-compose up -d

# Hack to wait for postgres container to be up before running alembic migrations
sleep 10;

# Run migrations
docker-compose run --rm backend alembic upgrade head

# Create initial data
docker-compose run --rm backend python3 server/seed_initial_data.py

# Uncomment to load geodata
# docker-compose run --rm postgres ./db_scripts/load_geodata.sh
