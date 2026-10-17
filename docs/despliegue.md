# Coolify, administración y envío
1. Desplegar primero por túnel privado, con DELIVERY_ENABLED=false. configure deshabilita proveedores SMTP/messengers existentes preservando su configuración, pausa campañas running y devuelve scheduled a borrador. Esto ocurre antes de iniciar app; no es un bloqueo permanente frente a cambios posteriores hechos por un administrador en la UI.
2. Cambiar clave admin, corregir correo del administrador (el instalador usa un correo de ejemplo), habilitar TOTP y crear usuarios nominales. Separar permisos de edición y campaigns:send. No conceder permisos de consultas SQL/plantillas avanzadas a usuarios no confiables. Revisar listas/campañas de ejemplo y eliminarlas si no se usan.
3. Definir remitente, nombre público, idioma, políticas de seguimiento y preferencias. configure administra app.root_url con https://NEWS_HOST y ruta de medios /listmonk/uploads en cada despliegue. El volumen debe mantenerse. No guardar adjuntos sensibles como imágenes públicas de campaña.
4. Para producción usar `docker compose -f compose.yaml up -d --force-recreate app` y comprobar retirada del puerto localhost:8094. Cargar este directorio como recurso Compose de Coolify, variables y montaje de certs/ops; asociar HTTPS al servicio app:9000. Preservar prefijo de volumen al mover el recurso dentro del mismo VPS; detener antes la instancia anterior.
5. El proxy puede restringir panel/API administrativa, pero las rutas públicas de confirmación/baja y medios deben seguir accesibles a destinatarios. No poner toda la instancia detrás de un login externo que impida desuscribirse. Configurar protección administrativa conforme a las rutas de la versión desplegada y probar los enlaces públicos.

## Activar SMTP deliberadamente
Una vez terminado el piloto sin envíos: configurar DELIVERY_ENABLED=true en el despliegue, recrear configure y app, e ingresar proveedor SMTP verificado desde ajustes nativos. Esa variable no añade ni habilita por sí sola credenciales; evita que el paso de configuración las vuelva a desactivar al iniciar. Los proveedores anteriormente deshabilitados deben habilitarse en la UI.

Configurar host/puerto/TLS y remitente autorizado por el proveedor. Preparar SPF/DKIM/DMARC conforme a sus instrucciones y comprobar DNS. No desactivar validación TLS. Ajustar velocidad/concurrencia a la cuota contratada. Probar envío SOLO a destinatarios autorizados cuando se solicite; este paquete no realiza esa acción.

Configurar rebotes/quejas con el proveedor y endpoints autenticados adecuados. Probar baja, doble confirmación, blocklist y rebote antes de una campaña. No añadir direcciones extraídas de Internet ni marcar como confirmados contactos sin base válida para recibir esos mensajes.

## Contenido
Cargar templates/boletin-base.html como plantilla de campaña y templates/contenido-ejemplo.html como cuerpo borrador. Reemplazar texto/enlace de ejemplo antes de usar. La plantilla tiene enlace de baja y no incorpora pixel de aperturas ni enlaces de tracking. Verificar render y versión texto desde listmonk; no está probado en Outlook/Gmail aquí.
