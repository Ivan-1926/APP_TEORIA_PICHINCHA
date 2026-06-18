# Banco Pichincha — App Clientes

App móvil de homebanking para el proyecto final (rúbrica Banco Andino).

## Identidad

- **Nombre al instalar:** Banco Pichincha
- **Colores:** azul `#002B5C`, amarillo `#FFD200`

## Funcionalidades

- Login con **DNI** + contraseña (Supabase Auth)
- Inicio, enviar dinero, contratar, cuentas, bandeja
- Cuentas, créditos + cronograma, tarjetas, pagos, transferencias
- Integración E2E con Fuerza de Ventas vía `sync_outbox`

## Supabase

1. `supabase/schema_and_seed.sql`
2. `supabase/02_rubrica_integracion.sql`
3. `supabase/03_fix_registro.sql`
4. `supabase/04_cliente_solicitud_credito.sql` (solicitudes desde app cliente → FV)
5. Desactivar confirmación de email en Auth (desarrollo)

Proyecto: `https://uomaqpphyouzbnestbba.supabase.co`

## Credenciales demo (Caso 1)

| App | Login | Contraseña |
|-----|-------|------------|
| **Cliente** (esta app) | DNI `40118120` | La que elijas al **registrarte** (sugerido: `Docente2025!`) |
| **Asesor móvil** | `demo@pichincha.com` | `pichincha123` |
| **Supervisor web** | Sin login (sesión fija supervisor) | — |

Registro Caso 1: nombre **Anaximandro Quispe**, DNI **40118120**, correo válido.

Más detalle: `fuerza-ventas-web/CREDENCIALES_DEMO.md` en el monorepo local o repo web en GitHub.

## Ejecutar

```bash
cd banco_pichincha
flutter pub get
flutter run
```

## Documentación rúbrica

- `docs/RUBRICA_AUTOEVALUACION.md` — evidencias 4/4 por criterio
- `docs/ARQUITECTURA.md` — capas, tablas, diagrama E2E

## Registro

1. **Regístrate** con DNI, correo, celular y clave
2. **Inicia sesión** solo con DNI + clave
