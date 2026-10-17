# Revisión del kit

Completado: YAML/Python/shell, TLS verify-full y CA, puertos no públicos, instalación idempotente, env de administrador fuera del servicio app, generación de configuración 0600 sin sobrescritura, inclusión de dump y uploads en backup. Plantilla revisada por estructura y placeholders. Integridad ZIP verificada sin secretos reales.

Revisado contra código upstream: parámetros PostgreSQL/TLS, esquema pgcrypto, estado de campañas, SMTP habilitado/deshabilitado, healthcheck y ruta de medios.

Pendiente: ejecutar Docker, SQL real, permisos de pgcrypto, instalación/upgrade, UI/MFA, SMTP, render en clientes de correo, formularios, bajas, rebotes, respaldo/restauración reales y prueba de capacidad. Compatibilidad con Supabase preparada documentalmente, no demostrada contra una cuenta real.
