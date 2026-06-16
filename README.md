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

1. Ejecutar `supabase/schema_and_seed.sql`
2. Ejecutar `supabase/02_rubrica_integracion.sql`
3. Desactivar confirmación de email en Auth (desarrollo)

Proyecto: `https://uomaqpphyouzbnestbba.supabase.co`

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
