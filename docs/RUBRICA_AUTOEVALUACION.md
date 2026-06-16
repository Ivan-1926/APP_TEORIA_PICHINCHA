# Autoevaluación rúbrica — App Clientes (Banco Pichincha)

Proyecto: `banco_pichincha` | Supabase: `uomaqpphyouzbnestbba.supabase.co`

| # | Criterio | Nivel | Pts | Evidencia |
|---|----------|-------|-----|-----------|
| 1 | Integración E2E (FV ↔ Core espejo ↔ Clientes) | Excelente | **4/4** | Tablas `sync_outbox`, `sync_log`, `cr_creditos`, `cr_cuotas`. RPC `rpc_procesar_sync_outbox` refleja créditos aprobados en `creditos`, `cuotas`, `movimientos`, `notificaciones`. Dashboard ejecuta sync al refrescar. Badge "Originado Fuerza de Ventas" en Mis créditos. |
| 2 | App Fuerza de Ventas — originación | Excelente* | **4/4*** | *Evaluado en proyecto `APP_Fuerza _De_Venta`. La app cliente consume el resultado vía `sync_outbox` (Criterio 1). |
| 3 | App Clientes — autoservicio | Excelente | **4/4** | Login con **DNI** + clave. Perfil, cuentas, créditos + cronograma, movimientos, tarjetas, bandeja. Transferencias y pagos de servicios persisten en Supabase (`transferencias`, `pagos_servicios`, `movimientos`). |
| 4 | Seguridad RBAC (JWT + roles) | Excelente | **4/4** | Supabase Auth (JWT). `flutter_secure_storage` guarda tokens. Tabla `profiles` con rol `cliente`. RPC bloqueo tras **5 intentos** (`rpc_registrar_intento_login`). RLS por `auth.uid()` en todas las tablas. |
| 5 | Calidad datos, arquitectura, documentación | Excelente | **4/4** | SQL versionado (`schema_and_seed.sql`, `02_rubrica_integracion.sql`). Capas: `models` → `services` → `screens` → `widgets`. Integridad referencial FK. Seed coherente. Ver `docs/ARQUITECTURA.md`. |
| | **TOTAL** | | **20/20** | |

## Cómo demostrar integración E2E (Criterio 1)

1. Ejecutar en Supabase SQL Editor: `schema_and_seed.sql` y `02_rubrica_integracion.sql`.
2. Registrar cliente en la app (DNI + correo + clave).
3. Insertar en `sync_outbox` una solicitud aprobada con el DNI del cliente:

```sql
insert into public.sync_outbox (tipo_evento, documento_cliente, payload) values
  ('solicitud_aprobada', 'TU_DNI', '{
    "solicitud_id": "sol_demo_001",
    "descripcion": "Préstamo Personal Campo",
    "monto": 15000,
    "plazo_meses": 24,
    "tasa_interes": 18.5,
    "cuota_mensual": 750
  }'::jsonb);
```

4. Abrir la app → pull-to-refresh en Inicio → el crédito aparece en **Mis créditos** con etiqueta Fuerza de Ventas, notificación en bandeja y movimiento de desembolso.

## Scripts SQL (orden)

1. `supabase/schema_and_seed.sql`
2. `supabase/02_rubrica_integracion.sql`
