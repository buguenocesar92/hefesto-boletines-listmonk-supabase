#!/bin/sh
set -eu
psql --no-psqlrc -v ON_ERROR_STOP=1 -v site_url="https://$NEWS_HOST" <<'SQL'
UPDATE settings SET value=to_jsonb(:'site_url'::text), updated_at=now() WHERE key='app.root_url';
UPDATE settings SET value='"/listmonk/uploads"'::jsonb, updated_at=now() WHERE key='upload.filesystem.upload_path';
SQL
if [ "$DELIVERY_ENABLED" != true ]; then
  psql --no-psqlrc -v ON_ERROR_STOP=1 -f /opt/hefesto/disable-delivery.sql
fi
