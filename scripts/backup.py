#!/usr/bin/env python3
import os,datetime,subprocess,hashlib,json
from pathlib import Path
p=Path(__file__).resolve().parents[1];os.chdir(p);os.umask(0o077)
def dc(*args,**kw):return subprocess.run(['docker','compose',*args],check=True,**kw)
if not (p/'.env').is_file():raise SystemExit('Falta .env')
if not dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('listmonk no esta activo en este contexto')
b=p/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');b.mkdir(parents=True)
try:
 dc('stop','app')
 with (b/'public.dump').open('wb') as out:
  dc('run','--rm','--no-deps','-T','--entrypoint','pg_dump','dbtools','--format=custom','--schema=public','--no-owner','--no-acl',stdout=out)
 with (b/'uploads.tar.gz').open('wb') as out:
  dc('run','--rm','--no-deps','-T','--user','0','--entrypoint','tar','app','-czf','-','-C','/listmonk/uploads','.',stdout=out)
 for n in ['.env','compose.yaml']:(b/n).write_bytes((p/n).read_bytes())
 hashes={}
 for n in ['public.dump','uploads.tar.gz','.env','compose.yaml']:
  with (b/n).open('rb') as f:hashes[n]=hashlib.file_digest(f,'sha256').hexdigest()
 (b/'manifest.json').write_text(json.dumps({'version':'6.2.0','status':'completed','sha256':hashes},indent=2))
finally:dc('start','app')
print(f'Respaldo de suscriptores y campañas: {b}. Guardar también este kit y la CA; cifrar y copiar fuera del VPS.')
