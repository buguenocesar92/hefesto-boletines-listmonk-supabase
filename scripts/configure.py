#!/usr/bin/env python3
import os,re,secrets,sys,uuid
from pathlib import Path
host=r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}'
if len(sys.argv)!=3 or not re.fullmatch(r'[a-z][a-z0-9-]{2,39}',sys.argv[1]) or not re.fullmatch(host,sys.argv[2]):
    raise SystemExit('Uso: python3 scripts/configure.py cliente-demo boletines.tudominio.cl')
r=Path(__file__).resolve().parents[1];prefix='hefesto-boletines-'+sys.argv[1]
v={'COMPOSE_PROJECT_NAME':prefix,'VOLUME_PREFIX':prefix,'NEWS_HOST':sys.argv[2],
'POSTGRES_HOST':'CAMBIAR_HOST_SUPABASE','POSTGRES_USERNAME':'listmonk_app','POSTGRES_PASSWORD':secrets.token_hex(32),
'ADMIN_PASSWORD':secrets.token_hex(24),'SUPABASE_DEDICATED_CONFIRMED':'false','SUPABASE_DATA_API_DISABLED':'false','DELIVERY_ENABLED':'false',
# DB_NAME y DB_SSLMODE se exponen en el .env para hacer explícitas las dos
# novedades del contrato Coolify (base lógica propia y modo TLS parametrizable).
# En despliegue dedicado quedan en sus defaults (postgres / verify-full).
'DB_NAME':'postgres','DB_SSLMODE':'verify-full'}
try:fd=os.open(r/'.env',os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
except FileExistsError:raise SystemExit('.env ya existe; no se modificó')
with os.fdopen(fd,'w') as f:
    for k,value in v.items():f.write(k+"='"+value+"'\n")
print('.env creado. Preparar rol DB, host y certificado según docs/supabase.md. No se conecta automáticamente.')
