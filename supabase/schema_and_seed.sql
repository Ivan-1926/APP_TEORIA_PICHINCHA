-- =============================================================================
-- Banco Pichincha – App Demo
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query → Run
-- Proyecto: https://uomaqpphyouzbnestbba.supabase.co
-- =============================================================================

-- ─── 1. LIMPIEZA (opcional, solo si re-ejecutas) ───────────────────────────
drop table if exists public.transferencias cascade;
drop table if exists public.cuotas cascade;
drop table if exists public.movimientos cascade;
drop table if exists public.notificaciones cascade;
drop table if exists public.tarjetas cascade;
drop table if exists public.creditos cascade;
drop table if exists public.cuentas_ahorro cascade;
drop table if exists public.usuarios cascade;

-- ─── 2. TABLAS ─────────────────────────────────────────────────────────────

create table public.usuarios (
  id          text primary key,
  nombre      text not null,
  documento   text not null default '00000000',
  email       text not null,
  celular     text not null default '',
  created_at  timestamptz not null default now()
);

create table public.cuentas_ahorro (
  id          text primary key,
  usuario_id  text not null references public.usuarios(id) on delete cascade,
  numero      text not null,
  cci         text not null unique,
  tipo        text not null default 'Cuenta de Ahorros',
  saldo       numeric(14,2) not null default 0,
  created_at  timestamptz not null default now()
);

create table public.movimientos (
  id          uuid primary key default gen_random_uuid(),
  cuenta_id   text not null references public.cuentas_ahorro(id) on delete cascade,
  usuario_id  text not null references public.usuarios(id) on delete cascade,
  fecha       timestamptz not null default now(),
  descripcion text not null,
  monto       numeric(14,2) not null,
  tipo        text not null check (tipo in ('deposito','retiro','transferencia'))
);

create table public.creditos (
  id               text primary key,
  usuario_id       text not null references public.usuarios(id) on delete cascade,
  descripcion      text not null,
  monto_original   numeric(14,2) not null,
  saldo_pendiente  numeric(14,2) not null,
  cuota_mensual    numeric(14,2) not null,
  fecha_inicio     timestamptz not null,
  plazo_meses      integer not null,
  tasa_interes     numeric(6,2) not null,
  created_at       timestamptz not null default now()
);

create table public.cuotas (
  id                uuid primary key default gen_random_uuid(),
  credito_id        text not null references public.creditos(id) on delete cascade,
  numero_cuota      integer not null,
  fecha_vencimiento timestamptz not null,
  monto_cuota       numeric(14,2) not null,
  capital           numeric(14,2) not null,
  interes           numeric(14,2) not null,
  saldo_restante    numeric(14,2) not null,
  pagada            boolean not null default false,
  unique (credito_id, numero_cuota)
);

create table public.transferencias (
  id                 uuid primary key default gen_random_uuid(),
  usuario_origen_id  text not null references public.usuarios(id) on delete cascade,
  cuenta_origen_id   text not null references public.cuentas_ahorro(id),
  cuenta_destino_id  text not null references public.cuentas_ahorro(id),
  cci_destino        text not null,
  monto              numeric(14,2) not null,
  concepto           text not null default '',
  fecha              timestamptz not null default now()
);

create table public.tarjetas (
  id                  text primary key,
  usuario_id          text not null references public.usuarios(id) on delete cascade,
  cuenta_id           text not null references public.cuentas_ahorro(id),
  numero_enmascarado  text not null,
  tipo                text not null default 'Tarjeta De Débito',
  bloqueada           boolean not null default false,
  created_at          timestamptz not null default now()
);

create table public.notificaciones (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  text not null references public.usuarios(id) on delete cascade,
  titulo      text not null,
  mensaje     text not null,
  fecha       timestamptz not null default now(),
  tipo        text not null default 'general',
  leida       boolean not null default false
);

-- ─── 3. ÍNDICES ────────────────────────────────────────────────────────────

create index idx_cuentas_usuario on public.cuentas_ahorro(usuario_id);
create index idx_cuentas_cci on public.cuentas_ahorro(cci);
create index idx_movimientos_usuario on public.movimientos(usuario_id);
create index idx_movimientos_cuenta on public.movimientos(cuenta_id);
create index idx_movimientos_fecha on public.movimientos(fecha desc);
create index idx_creditos_usuario on public.creditos(usuario_id);
create index idx_cuotas_credito on public.cuotas(credito_id);
create index idx_transferencias_origen on public.transferencias(usuario_origen_id);
create index idx_notificaciones_usuario on public.notificaciones(usuario_id);

-- ─── 4. ROW LEVEL SECURITY ─────────────────────────────────────────────────
-- Políticas pensadas para app demo con Supabase Auth.
-- Usuarios autenticados pueden operar datos bancarios (incluye transferencias).

alter table public.usuarios enable row level security;
alter table public.cuentas_ahorro enable row level security;
alter table public.movimientos enable row level security;
alter table public.creditos enable row level security;
alter table public.cuotas enable row level security;
alter table public.transferencias enable row level security;
alter table public.tarjetas enable row level security;
alter table public.notificaciones enable row level security;

-- Perfil propio
create policy "usuarios_select_own"
  on public.usuarios for select to authenticated
  using (id = auth.uid()::text);

create policy "usuarios_insert_own"
  on public.usuarios for insert to authenticated
  with check (id = auth.uid()::text);

create policy "usuarios_update_own"
  on public.usuarios for update to authenticated
  using (id = auth.uid()::text);

-- Cuentas: leer propias + buscar CCI destino + actualizar saldos (transferencias)
create policy "cuentas_select_auth"
  on public.cuentas_ahorro for select to authenticated
  using (true);

create policy "cuentas_insert_own"
  on public.cuentas_ahorro for insert to authenticated
  with check (usuario_id = auth.uid()::text);

create policy "cuentas_update_auth"
  on public.cuentas_ahorro for update to authenticated
  using (true);

-- Movimientos
create policy "movimientos_all_auth"
  on public.movimientos for all to authenticated
  using (true) with check (true);

-- Créditos y cuotas
create policy "creditos_select_own"
  on public.creditos for select to authenticated
  using (usuario_id = auth.uid()::text);

create policy "cuotas_select_via_credito"
  on public.cuotas for select to authenticated
  using (
    exists (
      select 1 from public.creditos c
      where c.id = cuotas.credito_id
        and c.usuario_id = auth.uid()::text
    )
  );

-- Transferencias
create policy "transferencias_all_auth"
  on public.transferencias for all to authenticated
  using (usuario_origen_id = auth.uid()::text)
  with check (usuario_origen_id = auth.uid()::text);

-- Tarjetas y notificaciones
create policy "tarjetas_select_own"
  on public.tarjetas for select to authenticated
  using (usuario_id = auth.uid()::text);

create policy "notificaciones_all_own"
  on public.notificaciones for all to authenticated
  using (usuario_id = auth.uid()::text)
  with check (usuario_id = auth.uid()::text);

-- ─── 5. DATOS DEMO (referencia para transferencias CCI) ────────────────────
-- Nota: estos IDs no son usuarios Auth reales. Sirven como contraparte CCI.
-- Al registrarte en la app, se crean tus propias filas con tu auth.uid().

insert into public.usuarios (id, nombre, documento, email, celular) values
  ('cliente_demo',    'Juan Pérez Rodríguez', '72345678', 'juan.perez@demo.com',  '987654321'),
  ('cliente_destino', 'María López García',   '87654321', 'maria.lopez@demo.com', '912345678');

insert into public.cuentas_ahorro (id, usuario_id, numero, cci, tipo, saldo) values
  ('ca001', 'cliente_demo',    '2100234567', '00221002345670000', 'Cuenta de Ahorros', 15420.50),
  ('ca002', 'cliente_demo',    '2100987654', '00221009876540000', 'Cuenta Corriente',    5280.75),
  ('ca003', 'cliente_destino', '2100111222', '00221001112220000', 'Cuenta de Ahorros',   8500.00);

insert into public.movimientos (cuenta_id, usuario_id, fecha, descripcion, monto, tipo) values
  ('ca001', 'cliente_demo', now() - interval '2 days',  'Depósito en efectivo',       500.00,   'deposito'),
  ('ca001', 'cliente_demo', now() - interval '5 days',  'Pago servicios de agua',     -45.00,   'retiro'),
  ('ca001', 'cliente_demo', now() - interval '7 days',  'Transferencia recibida',     1200.00,  'transferencia'),
  ('ca001', 'cliente_demo', now() - interval '12 days', 'Pago servicio eléctrico',    -120.00,  'retiro'),
  ('ca001', 'cliente_demo', now() - interval '18 days', 'Depósito nómina',            2500.00,  'deposito'),
  ('ca002', 'cliente_demo', now() - interval '3 days',  'Depósito en efectivo',       300.00,   'deposito'),
  ('ca002', 'cliente_demo', now() - interval '9 days',  'Retiro cajero automático',   -200.00,  'retiro');

insert into public.creditos (id, usuario_id, descripcion, monto_original, saldo_pendiente, cuota_mensual, fecha_inicio, plazo_meses, tasa_interes) values
  ('cr001', 'cliente_demo', 'Préstamo Personal',  25000.00, 18750.00, 555.56, '2024-01-15', 36, 18.5),
  ('cr002', 'cliente_demo', 'Préstamo Vehicular', 35000.00, 28400.00, 778.89, '2024-06-01', 48, 14.0);

-- Primeras 6 cuotas del cr001 (15 marcadas pagadas en demo offline)
insert into public.cuotas (credito_id, numero_cuota, fecha_vencimiento, monto_cuota, capital, interes, saldo_restante, pagada) values
  ('cr001', 1,  '2024-02-15', 555.56, 170.56, 385.00, 24829.44, true),
  ('cr001', 2,  '2024-03-15', 555.56, 173.19, 382.37, 24656.25, true),
  ('cr001', 3,  '2024-04-15', 555.56, 175.86, 379.70, 24480.39, true),
  ('cr001', 4,  '2024-05-15', 555.56, 178.57, 376.99, 24301.82, true),
  ('cr001', 5,  '2024-06-15', 555.56, 181.32, 374.24, 24120.50, true),
  ('cr001', 6,  '2024-07-15', 555.56, 184.11, 371.45, 23936.39, true);

insert into public.tarjetas (id, usuario_id, cuenta_id, numero_enmascarado, tipo, bloqueada) values
  ('td001', 'cliente_demo', 'ca002', '*6327', 'Tarjeta De Débito', false);

insert into public.notificaciones (usuario_id, titulo, mensaje, fecha, tipo, leida) values
  ('cliente_demo', 'Préstamo aprobado', 'Tu Préstamo Personal por S/ 50,000.00 ha sido aprobado.', now() - interval '5 hours', 'credito', false),
  ('cliente_demo', 'Transferencia recibida', 'Recibiste S/ 1,200.00 en tu Cuenta de Ahorros.', now() - interval '2 days', 'transferencia', true),
  ('cliente_demo', 'Promoción Yape', 'Envía y recibe dinero de Yape directamente desde la app.', now() - interval '6 days', 'promo', false);

-- ─── 6. TRIGGER OPCIONAL: perfil al registrarse ───────────────────────────
-- Descomenta si quieres crear fila en usuarios automáticamente al signup Auth.

/*
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.usuarios (id, nombre, email, documento, celular)
  values (
    new.id::text,
    coalesce(new.raw_user_meta_data->>'nombre', 'Usuario Nuevo'),
    new.email,
    coalesce(new.raw_user_meta_data->>'documento', '00000000'),
    coalesce(new.raw_user_meta_data->>'celular', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
*/

-- =============================================================================
-- FIN – Verifica en Table Editor que existan las 8 tablas.
-- Luego inicia sesión en la app (registro/login) para usar Supabase en línea.
-- CCI de prueba para transferir: 00221001112220000 (María López)
-- =============================================================================
