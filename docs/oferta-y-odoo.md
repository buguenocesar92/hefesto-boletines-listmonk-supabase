# Oferta y traspaso
Servicio: instalación por empresa, diseño de boletín, organización de listas, capacitación, soporte, respaldo y reportes. Enfocado en pymes, academias y comunidades con suscriptores autorizados. Cotizar infraestructura/Supabase y SMTP aparte o con límites explícitos; no garantizar entregabilidad ni ventas.

Piloto: lista interna autorizada, plantilla, borrador, revisión y envío de prueba posterior a configuración. No existe campaña enviada/programada por este kit. listmonk es un gestor de listas; procesos comerciales complejos pueden mantenerse en Odoo/Mautic.

## Datos para Odoo
Exportar desde interfaz/API autorizada conservando email normalizado, nombre, atributos, listas y estado por suscripción. Mantener evidencia de origen/confirmación, bajas y blocklist. No convertir automáticamente todos los contactos comerciales de Odoo en suscriptores confirmados.

| listmonk | Destino propuesto | Condición |
|---|---|---|
| Suscriptor | Contacto de mailing | Duplicados y propósito compatibles |
| Lista | Lista/segmento | Mapeo por identificador |
| Unsubscribed/blocklisted | Baja/supresión | Preservar siempre |
| Atributos | Campos personalizados | Tipos y minimización |
| Campaña/reporte | Archivo histórico | No recrear un envío automáticamente |

No se incluye conector bidireccional. Validar versión/edición de Odoo y plantilla de importación; probar un conjunto pequeño y conciliar conteos/estados. Si se migra a otra instancia listmonk, usar restauración completa con campañas desactivadas. La exportación CSV no sustituye backup de configuración, plantillas y medios.
