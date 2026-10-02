-- Creates one database per service that owns a PostgreSQL schema.
-- Local-dev simplification: one Postgres container, one DB per service
-- (see openspec/changes/monorepo-skeleton/design.md).

CREATE DATABASE ledger;
CREATE DATABASE accounts;
CREATE DATABASE identity;
CREATE DATABASE payments;
CREATE DATABASE statements;
