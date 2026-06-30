-- =============================================================================
-- Banco Pichincha – FIX REGISTRO
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query → Run
-- Proyecto: https://uomaqpphyouzbnestbba.supabase.co
-- -----------------------------------------------------------------------------
-- PROBLEMA QUE RESUELVE:
--   Al registrarse, Supabase Auth crea el usuario pero (si la confirmación de
--   email está activada) NO devuelve sesión. Sin sesión, auth.uid() es NULL y
--   los INSERT del cliente en usuarios/profiles/cuentas_ahorro/tarjetas fallan
--   con: "new row violates row-level security policy" (código 42501).
--
-- SOLUCIÓN:
--   Un trigger SECURITY DEFINER sobre auth.users que crea TODAS las filas del
--   lado servidor (se ejecuta como dueño de la tabla, ignora RLS). Así el
--   registro funciona aunque no haya sesión todavía.
-- =============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       text := new.id::text;
  v_staff_rol text := lower(coalesce(nullif(trim(new.raw_user_meta_data->>'rol'), ''), ''));
  v_nombre    text := coalesce(nullif(trim(new.raw_user_meta_data->>'nombre'), ''), 'Usuario Nuevo');
  v_documento text := coalesce(
    nullif(trim(new.raw_user_meta_data->>'documento'), ''),
    '9' || substr(replace(v_uid, '-', ''), 1, 7)
  );
  v_celular   text := coalesce(new.raw_user_meta_data->>'celular', '');
  v_seed      bigint := abs(hashtext(v_uid));
  v_num_ah    text := '2100' || lpad((v_seed % 1000000)::text, 6, '0');
  v_num_cte   text := '2101' || lpad(((v_seed / 7) % 1000000)::text, 6, '0');
  v_cci_ah    text := '002A' || replace(v_uid, '-', '');
  v_cci_cte   text := '002B' || replace(v_uid, '-', '');
begin
  if v_staff_rol in ('asesor', 'supervisor', 'admin') then
    return new;
  end if;
  -- 1. Usuario
  insert into public.usuarios (id, nombre, documento, email, celular)
  values (v_uid, v_nombre, v_documento, new.email, v_celular)
  on conflict (id) do update
    set nombre = excluded.nombre,
        documento = excluded.documento,
        celular = excluded.celular;

  -- 2. Perfil (RBAC / control de intentos)
  insert into public.profiles (id, rol, documento, login_attempts)
  values (new.id, 'cliente', v_documento, 0)
  on conflict (id) do update set documento = excluded.documento;

  -- 3. Cuentas (ahorros + corriente)
  insert into public.cuentas_ahorro (id, usuario_id, numero, cci, tipo, saldo)
  values
    ('ca_' || v_uid || '_ahorros',   v_uid, v_num_ah,  v_cci_ah,  'Cuenta de Ahorros', 5000.00),
    ('ca_' || v_uid || '_corriente', v_uid, v_num_cte, v_cci_cte, 'Cuenta Corriente',  1000.00)
  on conflict (id) do nothing;

  -- 4. Tarjeta de débito asociada a la cuenta de ahorros
  insert into public.tarjetas (id, usuario_id, cuenta_id, numero_enmascarado, tipo, bloqueada)
  values ('td_' || v_uid || '_1', v_uid, 'ca_' || v_uid || '_ahorros',
          '*' || right(v_num_ah, 4), 'Tarjeta De Débito', false)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =============================================================================
-- IMPORTANTE – CONFIRMACIÓN DE EMAIL
-- -----------------------------------------------------------------------------
-- Para que el usuario pueda INICIAR SESIÓN inmediatamente después de
-- registrarse (sin tener que abrir un correo), desactiva la confirmación:
--
--   Supabase Dashboard → Authentication → Sign In / Providers → Email
--   → desactiva "Confirm email" → Save
--
-- Con eso el signUp devuelve sesión al instante y el login funciona.
-- =============================================================================
