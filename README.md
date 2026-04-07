# README

## Run with Docker (development)

This app uses **SQLite** (stored in `storage/`), so you don’t need a separate DB container.

### Start

```bash
docker compose up --build
```

Then open `http://localhost:3000`.

### Seed data (optional)

```bash
docker compose exec web bin/rails db:seed
```

### Run tests

```bash
docker compose exec web bin/rails test
```

## Production Docker image

There is also a production-oriented `Dockerfile` used for deployment.
