#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${BLUEMAP_DB_JDBC_URL:-}" ]]; then
  echo "BLUEMAP_DB_JDBC_URL is not set" >&2
  exit 1
fi

cd /app

sql_file="/app/config/storages/sql.conf"
if [[ ! -f "${sql_file}" ]]; then
  echo "Failed to find ${sql_file}" >&2
  exit 1
fi

# Inject the runtime JDBC url into the config before launching BlueMap
perl -0pi -e 's/(connection-url:\s*)".*?"/$1 . "\"" . $ENV{BLUEMAP_DB_JDBC_URL} . "\""/e' "${sql_file}"

exec java -jar bluemap-cli.jar -w -r
