# Banco Pichincha

App demo de banca móvil para el proyecto de teoría.

## Identidad

- **Nombre al instalar:** Banco Pichincha
- **Carpeta del proyecto:** `banco_pichincha`
- **Colores:** azul marino `#002B5C`, amarillo `#FFD200`, fondo blanco

## Funcionalidades del usuario

- **Inicio:** saldo total, acciones rápidas, Yape/Plin/interbancarias, movimientos
- **Enviar dinero:** Yape, Plin y transferencias interbancarias (CCI)
- **Contratar:** catálogo de productos (cuentas, préstamos, hipotecas) y servicios (seguros, pagos)
- **Cuentas:** ahorros, créditos, tarjetas de débito y pagos de servicios
- **Bandeja:** notificaciones y mensajes del banco
- **Perfil y Ayuda:** accesibles desde el inicio

## Backend

- **Supabase** (Auth + PostgreSQL)
- **Modo demo offline** sin conexión (datos en memoria)

## Ejecutar

```bash
cd banco_pichincha
flutter pub get
dart run flutter_launcher_icons
flutter run
```
