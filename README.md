# SprintSight — Deployment

Backend + PostgreSQL, orchestrated with Docker Compose. Images are stored in
Cloudinary, so the only persistent volume is the database.

## Structure

```
deploy/
├── docker-compose.yml      ← the stack definition (run commands from here)
├── .env                    ← secrets (create from .env.example, gitignored)
├── .env.example
├── db/
│   └── init-scripts/
│       └── 01-extensions.sql   ← runs once on DB first-init
├── backend/                ← Spring Boot project: pom.xml, src/, Dockerfile
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── frontend/               ← (added later)
└── prediction/             ← (added later)
```

Current scope: **backend + database only**. `frontend/` and `prediction/`
become additional services in `docker-compose.yml` when you're ready.

## Setup

```bash
cd deploy
cp .env.example .env
# edit .env: set DB_PASSWORD, JWT_SECRET (openssl rand -base64 64),
#            and the three CLOUDINARY_* values
docker compose up --build
```

Backend → http://localhost:8080
Database → localhost:5432

## What goes where

| Path | Holds |
|------|-------|
| `deploy/docker-compose.yml` | service definitions; all relative paths resolve from here |
| `deploy/.env` | every secret and config value |
| `deploy/db/init-scripts/` | SQL/shell run **once** on DB first-init (extensions, roles) |
| `deploy/backend/` | the full Spring Boot project including its Dockerfile |

The compose `backend` service builds from `./backend` (context), so `pom.xml`
and `src/` must live directly under `deploy/backend/` alongside the Dockerfile.

## "Run scripts when the database is created"

`./db/init-scripts` is mounted into the Postgres container's
`/docker-entrypoint-initdb.d/`. Postgres runs everything there, alphabetically,
**the first time** an empty data volume initializes.

- Runs once, on first init.
- Skipped on every later `up`.
- To re-run (after editing a script): `docker compose down -v` (wipes the
  volume), then `docker compose up`.

Use `01-`, `02-` prefixes to order multiple scripts.

**Init scripts = DB-level setup (extensions). Flyway = table schema.** Keep
table DDL in Flyway migrations (run on app startup, version-tracked), not in
init scripts. If you're not on Flyway yet, set `DDL_AUTO=update` in `.env`.

## Networking notes

- An explicit `sprintsight` bridge network is declared so the future
  `frontend` and `prediction` services can join it and reach backend/db by
  service name.
- Inside the network, the backend reaches the DB at host **`postgres`** (the
  service name), not `localhost`. From your host machine you use
  `localhost:5432` via the published port.
- When `prediction/` arrives: if the backend calls it, it'll reach it at
  `http://prediction:<port>` over this same network.

## Common commands

```bash
docker compose up --build         # build + start
docker compose up -d              # detached
docker compose logs -f backend    # tail backend
docker compose logs -f postgres   # tail database
docker compose ps                 # status
docker compose down               # stop, keep DB data
docker compose down -v            # stop, DELETE DB data (re-runs init scripts)
```

DB dump (backup):
```bash
docker compose exec postgres pg_dump -U sprintsight sprintsight > backup.sql
```

## Adding services later

- **frontend**: add a `frontend` service with `build: ./frontend`, put it on
  the `sprintsight` network, expose its port, and add its origin to
  `CORS_ALLOWED_ORIGINS`.
- **prediction**: add a `prediction` service with `build: ./prediction`, put
  it on the network; the backend calls it at `http://prediction:<port>`.

