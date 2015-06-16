#!/bin/bash

echo "****** CREATING DATABASE ******"

echo "starting postgres ..."
gosu postgres pg_ctl -w start
echo "done."

echo "bootstrapping the postgres db"
gosu postgres pg_restore --host localhost --port 5432 --username "postgres" \
  --dbname "sige" --no-password  --no-owner --no-privileges --no-tablespaces \
  --verbose "/docker-entrypoint-initdb.d/database.backup"
echo "done."

echo "stopping postgres ..."
gosu postgres pg_ctl stop
echo "done."

echo ""
echo "****** DATABASE CREATED ******"
