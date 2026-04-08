# README

## Run with Docker (development)

This app uses **PostgreSQL** via a `db` service in `docker-compose.yml`.

### Start

```bash
docker compose up --build
```

Then open `http://localhost:3000`.

### Seed data (optional)

```bash
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails db:seed
```

### Run tests

```bash
docker compose exec web bin/rails test
```

## Production Docker image

There is also a production-oriented `Dockerfile` used for deployment.

## Deploy (Render / any PaaS)

If you see `ActiveSupport::MessageEncryptor::InvalidMessage` during deploy, it means Rails could not decrypt `config/credentials.yml.enc`.

Set this environment variable in your hosting dashboard:

- `RAILS_MASTER_KEY`: copy/paste the exact contents of `config/master.key` from your local machine (do not commit this file)

For PostgreSQL, also set:

- `DATABASE_URL` (Render provides this automatically when you attach a Postgres database)

Then redeploy.
