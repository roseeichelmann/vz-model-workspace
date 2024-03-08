# VZ Two Layer Model Prototype

![Diagram of the two layer prototype.](diagram.png)

- CRIS users will insert and update into the tables that are prefixed with `cris_`
- Inserts to the `cris_` tables will trigger copying the record into their respective `crashes` or `units` table
- VZ users will make edits to the `crashes` and `units` tables
- The final "source of truth" are the `crashes` and `units` tables
- Columns that are prefixed with `vz_` were created by VZ and are not columns we receive from CRIS

## Database

- Start the database

```bash
docker compose up -d db
```

- connect on localhost on 5432
- username: `vz`
- password: `vz`
- database: `visionzero`
- it trusts all connections, so the password is optional-ish

## Adminer (DB UI)

- Fire up the Adminer to inspect DB contents via a web UI

```bash
docker compose up -d adminer
```

- connect with a browser on 8080
- use the DB credentials

## Testing

### Building up the database

- First you are going to copy the contents of the `build_tables.sql` file and execute these SQL commands within your DB tool. This will create all necessary tables, functions, and triggers.

### Importing seed data

- Import the crash, units, and locations seed data into their respective tables. Do it in the following order:

- `locations.csv` into `public.locations`
- `crashes.csv` into `public.cris_crashes`
- `units.csv` into `public.cris_units`

  - Delete the first column of the 'units.csv' `unit_id` before importing, the way I wrote my table the `unit_id` is a serial int that the DB takes care of. If you don't delete the first column there will be errors later.

- You should notice that the records you inserted into `public.cris_crashes` and `public.cris_units` were also copied into `public.crashes` and `public.units`, respectively.

### Test cases

- Using the `test_cases.sql` file, copy each sql command into your DB tool and execute them one at a time to inspect the results.
