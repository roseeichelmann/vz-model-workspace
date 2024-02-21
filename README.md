# VZ Model Workspace

- Start the database

  `docker compose up -d postgis`

  - connect on localhost on 5432
  - username: `vz`
  - password: `vz`
  - it trusts all connections, so the password is optional-ish

- Fire up the Adminer to inspect DB contents via a web UI
  `docker compose up -d adminer`

  - connect with a browser on 8080
  - use the DB credentials

- If you want a python container with `psycopg2` installed, run
  `docker compose run python`
  - that should dump you in a shell where the `python` directory is bind-mounted on `/application`
