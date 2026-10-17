#!/usr/bin/env python3
import hashlib,json,os,subprocess,sys,tarfile
from pathlib import Path,PurePosixPath
root=Path(__file__).resolve().parents[1];os.chdir(root)
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/restore_uploads.py /ruta/respaldo')
p=Path(sys.argv[1]).resolve();m=json.loads((p/'manifest.json').read_text());a=p/'uploads.tar.gz'
if m.get('status')!='completed' or m.get('version')!='6.2.0':raise SystemExit('Manifest inválido')
with a.open('rb') as f:
    if hashlib.file_digest(f,'sha256').hexdigest()!=m['sha256']['uploads.tar.gz']:raise SystemExit('Hash incorrecto')
with tarfile.open(a) as tf:
    seen=set()
    for member in tf:
        name=PurePosixPath(member.name)
        if name.is_absolute() or '..' in name.parts or not(member.isfile() or member.isdir()) or str(name) in seen:raise SystemExit('Ruta/tipo no admitido')
        seen.add(str(name))
def dc(*a,**kw):return subprocess.run(['docker','compose',*a],check=True,**kw)
if dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('Detener app')
found=dc('run','--rm','--no-deps','-T','--entrypoint','find','app','/listmonk/uploads','-mindepth','1','-maxdepth','1',capture_output=True,text=True).stdout.strip()
if found:raise SystemExit('Volumen no vacío; no se sobrescribe')
with a.open('rb') as f:dc('run','--rm','--no-deps','-T','--user','0','--entrypoint','tar','app','-xzf','-','-C','/listmonk/uploads',stdin=f)
print('Archivos restaurados. El entrypoint normal ajustará propietario al iniciar.')
