# Hefesto Boletines · listmonk + Supabase
Kit de listmonk 6.2.0, PostgreSQL de Supabase dedicado y archivos locales persistentes. Incluye Compose para Coolify, rol SQL, TLS verify-full, alta inicial de administrador, suspensión inicial de envíos, respaldo/restauración y una plantilla de boletín.

Funciones nativas: suscriptores, listas, segmentación, campañas, plantillas, estadísticas, bajas y procesamiento de rebotes según configuración. Es el producto listmonk original; no es un clon ni un SaaS con cobro de planes integrado. Complementa Mautic con una opción centrada en listas y boletines.

## Preparación
Requiere Linux, Docker + Compose v2, Python 3.11+, dominio HTTPS, proyecto Supabase exclusivo PostgreSQL 16/17 y CA válida. Un proveedor SMTP se configura después, desde listmonk; no se conecta automáticamente a Resend ni a tus cuentas.
```sh
python3 scripts/configure.py cliente-demo boletines.tudominio.cl
```
Seguir docs/supabase.md. Después:
```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d
```
Desde tu computador:
```sh
ssh -L 8094:127.0.0.1:8094 usuario@servidor
```
Abrir http://localhost:8094. Usuario admin; clave inicial ADMIN_PASSWORD en .env. Cambiarla y seguir docs/despliegue.md antes de publicar. No se ha enviado ningún mensaje.

## Estado y alcance
Compatibilidad revisada contra documentación/código: PostgreSQL, ssl_mode=verify-full y CA mediante db.params. Falta ejecutar instalación, SQL, SMTP y restauración con un Supabase real. ZIP revisado estáticamente; no desplegado.

Se utiliza Supabase solo como PostgreSQL: usuarios y medios los gestiona listmonk, sin Supabase Auth/Storage. La imagen instala ejemplos nativos de listas/suscriptores/campañas; eliminarlos desde la interfaz antes de importar datos reales. La plantilla Hefesto se carga manualmente; no hay campaña programada por el kit.

## Despliegue en Coolify (MVP Hefesto)

El kit se despliega desde `https://github.com/buguenocesar92/hefesto-boletines-listmonk-supabase`
usando el build pack Docker Compose. Coolify queda a cargo del dominio y TLS
vía Traefik. El servicio web expone `9000` y nunca publica puertos.

Variables nuevas (con su valor por defecto):

| Variable | Default | Notas |
| --- | --- | --- |
| `DB_NAME` | `postgres` | Base lógica a la que se conecta el kit. En el MVP compartido del Hefesto cada app usa `mvp_<slug>` para mantenerse aislada dentro del mismo Postgres. |
| `DB_SSLMODE` | `verify-full` | Modo TLS para `psql` y para el driver de listmonk. Para red interna donde Postgres va sin TLS, fijar `disable`; en ese caso el certificado CA no es obligatorio (la carpeta `certs/` queda vacía salvo el README). |

Variables existentes obligatorias: `POSTGRES_HOST`, `POSTGRES_USERNAME`
(default `listmonk_app`), `POSTGRES_PASSWORD`, `ADMIN_PASSWORD`,
`NEWS_HOST`, `SUPABASE_DEDICATED_CONFIRMED=true`,
`SUPABASE_DATA_API_DISABLED=true`, `DELIVERY_ENABLED=false`.

`bash scripts/coolify-check.sh` renderiza los composes con valores ficticios
no secretos y verifica que respeten el contrato (sin `ports`, `container_name`,
`privileged`, `cap_add`, `devices`, `network_mode`/`pid`/`ipc` host, mounts
fuera del repo o `docker.sock`, ni `name:` con valor literal) y que `mvp_prueba`
y `disable` aparezcan efectivamente cuando se quiere simular el modo compartido
de Supabase.
