# clairBuoyant

All clairBuoyant services started from a single repository.

_This repository is for local development only and is not meant to be deployed on any production environment!_

## Development

If you would like to help develop any of clairBuoyant's services such as [server](https://www.github.com/clairBuoyant/server) or [web](https://www.github.com/clairBuoyant/web), we recommend setting up those projects individually outside of docker.

## Development with Docker

1. Clone repository on your local machine and update submodules:

   ```bash
   git clone git@github.com:clairBuoyant/devBuoyant.git
   cd devBuoyant
   git submodule update --init --recursive
   ```

2. Build containers for development and seed initial data:

   ```bash
   ./scripts/build.sh
   ```

3. Once you've built your containers, run this command to manage your development environment with hot reloading:

   ```bash
   docker-compose up -d
   ```

   - API will be available at [localhost:8000/api/v1](http://localhost:8000/api/).

   - API docs will be available at [localhost:8000/api/docs](http://localhost:8000/api/docs).

   - UI will be available at [localhost:8000](http://localhost:8000/).
