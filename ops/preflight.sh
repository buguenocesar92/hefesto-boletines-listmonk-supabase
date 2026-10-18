#!/bin/sh
set -eu
[ "$SUPABASE_DEDICATED_CONFIRMED" = true ] || { echo 'Confirme proyecto Supabase exclusivo'; exit 1; }
[ "$SUPABASE_DATA_API_DISABLED" = true ] || { echo 'Desactive Data API y confirme variable'; exit 1; }
# Si la conexión es sin TLS, no exigimos la CA del servidor de Postgres.
# Usamos PGSSLMODE (heredado de x-db-env) en lugar de DB_SSLMODE porque este
# script corre en un contenedor donde sólo PGSSLMODE está exportado.
[ "${PGSSLMODE:-verify-full}" = "disable" ] || [ -s "$PGSSLROOTCERT" ] || { echo 'Falta certificado CA'; exit 1; }
export PGCONNECT_TIMEOUT=15
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /opt/hefesto/preflight.sql
