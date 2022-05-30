# clairBuoyant

All clairBuoyant services started from a single repository.

_Keep in mind this repository is for local development only and is not meant to be deployed on any production environment!_

## Development with Docker

1. Clone repository onto your local machine and update submodules:

   ```bash
   git clone git@github.com:clairBuoyant/devBuoyant.git
   cd devBuoyant
   git submodule init && git submodule update
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

   - Swagger docs at [localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs).

   - Web will be available at [localhost:8000](http://localhost:8000/).

#### Additional Commands

You can stop the build at specific stages with the `--target` option:

```bash
docker build --name clairbuoyant-server --file server Dockerfile --target <stage>
```

For example, we can stop at the test stage like so:

```bash
docker build --tag clairbuoyant-server --file server/Dockerfile --target test
```

**NOTE**: if target is not specified, docker will build with the 'production' image since it was the last image defined.

We could then get a shell inside the container with:

```bash
docker run -it clairbuoyant-server:latest bash
```
