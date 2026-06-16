-- =============================================================================
-- Banco Pichincha – Integración rúbrica (Criterios 1, 4 y 5)
-- Ejecutar DESPUÉS de schema_and_seed.sql en Supabase SQL Editor
-- =============================================================================

create index if not exists idx_usuarios_documento on public.usuarios(documento);

-- ─── PROFILES / RBAC ─────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  rol             text not null default 'cliente'
                  check (rol in ('cliente', 'asesor', 'supervisor', 'admin')),
  documento       text unique,
  login_attempts  integer not null default 0,
  locked_until    timestamptz,
  created_at      timestamptz not null default now()
);

create index if not exists idx_profiles_documento on public.profiles(documento);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select to authenticated
  using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert to authenticated
  with check (id = auth.uid() and rol = 'cliente');

-- ─── PAGOS DE SERVICIOS ────────────────────────────────────────────────────
create table if not exists public.pagos_servicios (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  text not null references public.usuarios(id) on delete cascade,
  cuenta_id   text not null references public.cuentas_ahorro(id),
  servicio    text not null,
  referencia  text not null,
  monto       numeric(14,2) not null,
  fecha       timestamptz not null default now()
);

create index if not exists idx_pagos_usuario on public.pagos_servicios(usuario_id);

alter table public.pagos_servicios enable row level security;

drop policy if exists "pagos_select_own" on public.pagos_servicios;
create policy "pagos_select_own"
  on public.pagos_servicios for select to authenticated
  using (usuario_id = auth.uid()::text);

drop policy if exists "pagos_insert_own" on public.pagos_servicios;
create policy "pagos_insert_own"
  on public.pagos_servicios for insert to authenticated
  with check (usuario_id = auth.uid()::text);

-- ─── PUENTE SINCRONIZACIÓN (FVentas → Core espejo → Cliente) ───────────────
create table if not exists public.sync_outbox (
  id                 uuid primary key default gen_random_uuid(),
  tipo_evento        text not null check (tipo_evento in ('solicitud_aprobada', 'desembolso')),
  payload            jsonb not null,
  documento_cliente  text not null,
  estado             text not null default 'pendiente'
                     check (estado in ('pendiente', 'procesado', 'error')),
  error_mensaje      text,
  created_at         timestamptz not null default now(),
  processed_at       timestamptz
);

create table if not exists public.sync_log (
  id          uuid primary key default gen_random_uuid(),
  outbox_id   uuid references public.sync_outbox(id) on delete set null,
  evento      text not null,
  detalle     text,
  created_at  timestamptz not null default now()
);

create index if not exists idx_sync_outbox_estado on public.sync_outbox(estado);
create index if not exists idx_sync_outbox_dni on public.sync_outbox(documento_cliente);

alter table public.sync_outbox enable row level security;
alter table public.sync_log enable row level security;

drop policy if exists "sync_outbox_select_auth" on public.sync_outbox;
create policy "sync_outbox_select_auth"
  on public.sync_outbox for select to authenticated using (true);

drop policy if exists "sync_log_select_auth" on public.sync_log;
create policy "sync_log_select_auth"
  on public.sync_log for select to authenticated using (true);

-- ─── TABLAS ESPEJO cr_* (rúbrica) ───────────────────────────────────────────
alter table public.creditos
  add column if not exists origen_solicitud_id text,
  add column if not exists espejo_core boolean not null default false;

create table if not exists public.cr_creditos (
  id                  text primary key,
  credito_id          text not null references public.creditos(id) on delete cascade,
  usuario_id          text not null references public.usuarios(id) on delete cascade,
  solicitud_id        text,
  monto_desembolsado  numeric(14,2) not null,
  sincronizado_at     timestamptz not null default now()
);

create table if not exists public.cr_cuotas (
  id          uuid primary key default gen_random_uuid(),
  cr_credito_id text not null references public.cr_creditos(id) on delete cascade,
  cuota_id    uuid not null references public.cuotas(id) on delete cascade,
  unique (cr_credito_id, cuota_id)
);

alter table public.cr_creditos enable row level security;
alter table public.cr_cuotas enable row level security;

drop policy if exists "cr_creditos_select_own" on public.cr_creditos;
create policy "cr_creditos_select_own"
  on public.cr_creditos for select to authenticated
  using (usuario_id = auth.uid()::text);

drop policy if exists "cr_cuotas_select_via_cr" on public.cr_cuotas;
create policy "cr_cuotas_select_via_cr"
  on public.cr_cuotas for select to authenticated
  using (
    exists (
      select 1 from public.cr_creditos c
      where c.id = cr_cuotas.cr_credito_id
        and c.usuario_id = auth.uid()::text
    )
  );

-- ─── RPC: resolver email por DNI (login) ───────────────────────────────────
create or replace function public.rpc_resolver_login_dni(p_documento text)
returns table(email text, bloqueado boolean, intentos integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_locked timestamptz;
  v_attempts int;
begin
  select u.email into email
  from public.usuarios u
  where u.documento = trim(p_documento)
  limit 1;

  if email is null then
    return;
  end if;

  select p.id, p.locked_until, p.login_attempts
  into v_uid, v_locked, v_attempts
  from public.profiles p
  join public.usuarios u on u.id = p.id::text
  where u.documento = trim(p_documento)
  limit 1;

  bloqueado := v_locked is not null and v_locked > now();
  intentos := coalesce(v_attempts, 0);
  return next;
end;
$$;

grant execute on function public.rpc_resolver_login_dni(text) to anon, authenticated;

-- ─── RPC: registrar intento login ──────────────────────────────────────────
create or replace function public.rpc_registrar_intento_login(
  p_documento text,
  p_exitoso boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  select p.id into v_profile_id
  from public.profiles p
  join public.usuarios u on u.id = p.id::text
  where u.documento = trim(p_documento)
  limit 1;

  if v_profile_id is null then
    return;
  end if;

  if p_exitoso then
    update public.profiles
    set login_attempts = 0, locked_until = null
    where id = v_profile_id;
  else
    update public.profiles
    set login_attempts = login_attempts + 1,
        locked_until = case
          when login_attempts + 1 >= 5 then now() + interval '15 minutes'
          else locked_until
        end
    where id = v_profile_id;
  end if;
end;
$$;

grant execute on function public.rpc_registrar_intento_login(text, boolean) to anon, authenticated;

-- ─── RPC: procesar sync_outbox pendiente ───────────────────────────────────
create or replace function public.rpc_procesar_sync_outbox(p_documento text default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_usuario_id text;
  v_credito_id text;
  v_cr_id text;
  v_monto numeric;
  v_plazo int;
  v_tasa numeric;
  v_cuota numeric;
  v_saldo numeric;
  v_i int;
  v_capital numeric;
  v_interes numeric;
  v_fecha date;
  v_procesados int := 0;
begin
  for r in
    select * from public.sync_outbox
    where estado = 'pendiente'
      and (p_documento is null or documento_cliente = trim(p_documento))
    order by created_at
    for update skip locked
  loop
    begin
      select id into v_usuario_id
      from public.usuarios
      where documento = r.documento_cliente
      limit 1;

      if v_usuario_id is null then
        update public.sync_outbox
        set estado = 'error', error_mensaje = 'Cliente no registrado en app', processed_at = now()
        where id = r.id;
        continue;
      end if;

      v_monto := (r.payload->>'monto')::numeric;
      v_plazo := coalesce((r.payload->>'plazo_meses')::int, 12);
      v_tasa := coalesce((r.payload->>'tasa_interes')::numeric, 18.5);
      v_cuota := coalesce((r.payload->>'cuota_mensual')::numeric, round(v_monto / v_plazo, 2));
      v_credito_id := coalesce(r.payload->>'credito_id', 'cr_sync_' || substr(r.id::text, 1, 8));
      v_cr_id := 'crc_' || substr(r.id::text, 1, 8);

      insert into public.creditos (
        id, usuario_id, descripcion, monto_original, saldo_pendiente,
        cuota_mensual, fecha_inicio, plazo_meses, tasa_interes,
        origen_solicitud_id, espejo_core
      ) values (
        v_credito_id,
        v_usuario_id,
        coalesce(r.payload->>'descripcion', 'Préstamo originado en campo'),
        v_monto,
        v_monto,
        v_cuota,
        now(),
        v_plazo,
        v_tasa,
        r.payload->>'solicitud_id',
        true
      )
      on conflict (id) do nothing;

      v_saldo := v_monto;
      v_fecha := (now() + interval '1 month')::date;
      for v_i in 1..least(v_plazo, 6) loop
        v_interes := round(v_saldo * (v_tasa / 100 / 12), 2);
        v_capital := round(v_cuota - v_interes, 2);
        v_saldo := greatest(v_saldo - v_capital, 0);

        insert into public.cuotas (
          credito_id, numero_cuota, fecha_vencimiento,
          monto_cuota, capital, interes, saldo_restante, pagada
        ) values (
          v_credito_id, v_i, v_fecha + ((v_i - 1) * interval '1 month'),
          v_cuota, v_capital, v_interes, v_saldo, false
        )
        on conflict do nothing;
      end loop;

      insert into public.cr_creditos (id, credito_id, usuario_id, solicitud_id, monto_desembolsado)
      values (v_cr_id, v_credito_id, v_usuario_id, r.payload->>'solicitud_id', v_monto)
      on conflict (id) do nothing;

      insert into public.notificaciones (usuario_id, titulo, mensaje, tipo, leida)
      values (
        v_usuario_id,
        'Crédito aprobado',
        'Tu ' || coalesce(r.payload->>'descripcion', 'préstamo') ||
        ' por S/ ' || v_monto::text || ' fue desembolsado. Revisa tu cronograma.',
        'credito',
        false
      );

      insert into public.movimientos (cuenta_id, usuario_id, descripcion, monto, tipo)
      select ca.id, v_usuario_id,
        'Desembolso crédito ' || v_credito_id,
        v_monto, 'deposito'
      from public.cuentas_ahorro ca
      where ca.usuario_id = v_usuario_id
      order by ca.created_at
      limit 1;

      update public.cuentas_ahorro ca
      set saldo = saldo + v_monto
      where ca.id = (
        select id from public.cuentas_ahorro
        where usuario_id = v_usuario_id
        order by created_at limit 1
      );

      update public.sync_outbox
      set estado = 'procesado', processed_at = now()
      where id = r.id;

      insert into public.sync_log (outbox_id, evento, detalle)
      values (r.id, 'credito_espejado', 'Crédito ' || v_credito_id || ' reflejado en app cliente');

      v_procesados := v_procesados + 1;
    exception when others then
      update public.sync_outbox
      set estado = 'error', error_mensaje = SQLERRM, processed_at = now()
      where id = r.id;
    end;
  end loop;

  return v_procesados;
end;
$$;

grant execute on function public.rpc_procesar_sync_outbox(text) to authenticated;

-- ─── SEED: solicitud demo en outbox (procesar tras login del cliente) ───────
-- Descomenta si quieres probar integración E2E con DNI 72345678:
/*
insert into public.sync_outbox (tipo_evento, documento_cliente, payload) values
  ('solicitud_aprobada', '72345678', '{
    "solicitud_id": "sol_demo_001",
    "descripcion": "Préstamo Personal Campo",
    "monto": 15000,
    "plazo_meses": 24,
    "tasa_interes": 18.5,
    "cuota_mensual": 750
  }'::jsonb);
*/

-- =============================================================================
-- FIN – Ejecutar rpc_procesar_sync_outbox('TU_DNI') tras registrar cliente
-- =============================================================================

-- Políticas adicionales tarjetas (registro crea tarjeta débito)
drop policy if exists "tarjetas_insert_own" on public.tarjetas;
create policy "tarjetas_insert_own"
  on public.tarjetas for insert to authenticated
  with check (usuario_id = auth.uid()::text);

drop policy if exists "tarjetas_update_own" on public.tarjetas;
create policy "tarjetas_update_own"
  on public.tarjetas for update to authenticated
  using (usuario_id = auth.uid()::text);
