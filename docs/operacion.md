# Backups y recuperación
## Respaldo
```sh
python3 scripts/backup.py
```
Usar el mismo proyecto Compose del servicio real. Recomendado pausar campañas y esperar tareas en curso antes de mantenimiento. El script detiene app, vuelca public con pg_dump, copia uploads y configuración, genera hashes y reinicia app. Las campañas que estaban activas pueden reanudarse en el origen: pausarlas antes si no se desea. El backup no incluye esquemas internos Supabase ni servicios SMTP externos.

Solo usar carpeta con manifest completed. Contiene datos personales, claves y posiblemente credenciales SMTP; cifrar, transferir fuera del VPS y proteger la clave de recuperación. Guardar también este ZIP y CA. No se ha instalado un cron ni repositorio externo. Definir retención por contrato y probar restauración periódicamente.

## Recuperación en destino vacío
1. Preparar proyecto Supabase nuevo con rol/pgcrypto y .env de destino; COMPOSE_PROJECT_NAME/VOLUME_PREFIX nuevos. Usar misma imagen; DELIVERY_ENABLED=false y dominio de ensayo. No arrancar prepare/app antes de restaurar, porque instalarían tablas nuevas.
2. Ejecutar `docker compose run --rm preflight`, luego `python3 scripts/restore_db.py /ruta/backup` y `python3 scripts/restore_uploads.py /ruta/backup`.
3. restore_db verifica dump, exige public sin tablas y restaura sin DROP ni propietarios/ACL. Después deshabilita SMTP/messengers y cambia running a paused, scheduled a draft con send_at vacío. Es una modificación INTENCIONAL de la copia restaurada para evitar envíos automáticos. No altera el respaldo ni el origen.
4. restore_uploads exige volumen vacío y rechaza enlaces/rutas peligrosas. Si algo falla parcialmente, no iniciar app: usar destinos nuevos o reparar bajo control. No sobrescribir origen. Verificar también que no haya prepare activo en el destino durante restauración.
5. Arrancar con `docker compose up -d`. Revisar root_url del destino, medios, cuentas, MFA, suscriptores, estado de bajas/blocklist, listas, campañas y plantillas. No reactivar SMTP ni campañas hasta aprobación del responsable de envío. Este flujo no cambia servicios de correo externos.
6. Corte final: pausar importaciones/envíos/formularios del origen, obtener copia final, restaurar en destino nuevo y cambiar DNS tras aceptación. Reconciliar bajas y confirmaciones recibidas durante mantenimiento; no reimportar contactos dados de baja. Mantener origen detenido para no duplicar envíos.

## Actualizaciones y entrega
Ensayar nuevas versiones en copia con entregas desactivadas; las migraciones alteran esquema. Rollback implica restaurar versión y backup compatibles. Registrar digest de herramientas postgres:17-alpine y versión del servidor. Entregar kit, dominio/DNS, CA, proyecto Supabase/rol, volumen, credenciales en gestor, SMTP y DNS asociados, retención y prueba de restauración. Revocar accesos salientes después de validar.
