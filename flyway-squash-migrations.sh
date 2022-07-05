#!/usr/bin/env bash

echo "Please read the README.md before executing this script."
echo ""
echo "As preparation you will now be asked for your database connection details."
read -r -p "Host: (localhost)" HOST
read -r -p "Port: (5432)" PORT
read -r -p "Username: (postgres)" USERNAME
read -r -p "Database name: (postgres)" DB_NAME
HOST="${HOST:=localhost}"
PORT="${PORT:=5432}"
USERNAME="${USERNAME:=postgres}"
DB_NAME="${DB_NAME:=postgres}"

CURRENT_DAY="$(date +%d)"
CURRENT_MONTH="$(date +%m)"
CURRENT_YEAR="$(date +%Y)"

echo ""
read -r -p "Do you wish to create a squashed migration in the current directory?"$'\n'"<yes/no>: " EXECUTE_DUMP
if [[ $EXECUTE_DUMP == "y" || $EXECUTE_DUMP == "Y" || $EXECUTE_DUMP == "yes" || $EXECUTE_DUMP == "Yes" ]]
then
  OUTPUT_NAME=V1__squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR}.sql

  echo "Deleting SQL files in current directory."
  find . -name '*.sql' -delete
  echo "Dumping current database schema to ${OUTPUT_NAME} in current directory with pg_dump."
  echo "You will be asked for the database password."
  pg_dump --host="$HOST" --port="$PORT" --username="$USERNAME" --schema-only --no-owner --exclude-table=flyway_schema_history* "$DB_NAME" > "$OUTPUT_NAME"
  echo "If no errors occurred your ${OUTPUT_NAME} squashed migration script should be ready!"
fi

echo ""
read -r -p "Do you wish to prepare this database for the squashed migration?"$'\n'"<yes/no>: " EXECUTE_SQL
if [[ $EXECUTE_SQL == "y" || $EXECUTE_SQL == "Y" || $EXECUTE_SQL == "yes" || $EXECUTE_SQL == "Yes" ]]
then
  RENAME_INDEX_QUERY="ALTER INDEX IF EXISTS flyway_schema_history_s_idx RENAME TO flyway_schema_history_s_idx_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR};"
  RENAME_PRIMARY_KEY_QUERY="ALTER TABLE flyway_schema_history RENAME CONSTRAINT flyway_schema_history_pk TO flyway_schema_history_pk_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR};"
  RENAME_TABLE_QUERY="ALTER TABLE IF EXISTS flyway_schema_history RENAME TO flyway_schema_history_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR};"

  echo ""
  echo "You will be asked several times for the database password."
  echo ""
  echo "Renaming old flyway_schema_history_s_idx index to flyway_schema_history_s_idx_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR}."
  psql --host="$HOST" --port="$PORT" --username="$USERNAME" --dbname="$DB_NAME" --command="$RENAME_INDEX_QUERY"
  echo "Renaming old flyway_schema_history_pk primary key to flyway_schema_history_pk_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR}."
  psql --host="$HOST" --port="$PORT" --username="$USERNAME" --dbname="$DB_NAME" --command="$RENAME_PRIMARY_KEY_QUERY"
  echo "Renaming old flyway_schema_history table to flyway_schema_history_squash_${CURRENT_DAY}_${CURRENT_MONTH}_${CURRENT_YEAR}."
  psql --host="$HOST" --port="$PORT" --username="$USERNAME" --dbname="$DB_NAME" --command="$RENAME_TABLE_QUERY"
  echo ""
  echo "If no errors occurred this database is ready for flyway to execute flyway:baseline to create a new flyway_schema_history table with a squashed migration file!"
  echo ""
  echo "IMPORTANT: Update baselineOnMigrate to true and baselineVersion to 1.1 in your flyway configuration before you run flyway on this database again. (https://flywaydb.org/documentation/configuration/parameters/baselineOnMigrate)"
  echo "If you use spring data with flyway you will have to edit application properties like spring.flyway.baseline-on-migrate and spring.flyway.baseline-version."
fi

echo ""
echo "End of script, exiting!"
exit 0
