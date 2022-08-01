#!/bin/sh -e

random_password () {
    date +%s | sha256sum | base64 | head -c 32 ; echo
}
set_username () {
    whoami
}

# TODO: guard for GitHub Actions
# how to handle setting .env in github actions and sharing creds
if [ ! -f server/.env ]
then
    touch server/.env
    echo "POSTGRES_DB=devbuoyant" >> server/.env
    echo "POSTGRES_PASSWORD=$(random_password)" >> server/.env
    echo "POSTGRES_USER=$(set_username)" >> server/.env
    echo "DATABASE_URL=postgresql+asyncpg://$(set_username):$(random_password)@localhost:5432/clairbuoyant" >> server/.env
    echo "PYTHON_ENV=development" >> server/.env
fi

# LOAD ENV VARIABLES
if [ -f server/.env ]; then
    export $(echo $(cat server/.env | sed 's/#.*//g'| xargs) | envsubst)
fi

# Install node_modules before caching in Docker
cd web && npm ci && cd -

# Build and run containers
COMPOSE_PROJECT_NAME=devbuoyant docker-compose up -d

# Hack to wait for postgres container to be up before running alembic migrations
sleep 10;

# Run migrations
docker-compose run --rm backend alembic upgrade head

# Create initial data
docker-compose run --rm backend python3 server/seed_initial_data.py

# Uncomment to load geodata
# docker-compose run --rm postgres ./db_scripts/load_geodata.sh
