-- =============================================================================
-- App Cliente — Solicitud de crédito (canal cliente → fv_credit_applications)
-- Ejecutar en Supabase SQL Editor (proyecto uomaqpphyouzbnestbba)
-- =============================================================================

create or replace function public.rpc_registrar_solicitud_cliente(
  p_documento   text,
  p_nombre      text,
  p_producto    text,
  p_monto       numeric,
  p_plazo_meses integer,
  p_destino     text,
  p_garantia    text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id         uuid;
  v_tea        numeric := 18.0;
  v_tem        numeric;
  v_cuota      numeric;
  v_expediente text;
  v_purpose    text;
begin
  v_tem := power(1 + v_tea / 100, 1.0 / 12) - 1;
  if v_tem > 0 and p_plazo_meses > 0 then
    v_cuota := p_monto * (v_tem * power(1 + v_tem, p_plazo_meses))
               / (power(1 + v_tem, p_plazo_meses) - 1);
  else
    v_cuota := p_monto / greatest(p_plazo_meses, 1);
  end if;

  v_purpose := '[Canal: cliente] ' || coalesce(p_producto, 'Crédito')
               || ' — ' || coalesce(p_destino, 'Sin destino');
  if coalesce(p_garantia, '') <> '' then
    v_purpose := v_purpose || ' | Garantía: ' || p_garantia;
  end if;

  insert into public.fv_credit_applications (
    client_name, client_dni, amount, term_months, tea, monthly_payment,
    purpose, status, submitted_at, updated_at
  ) values (
    p_nombre, p_documento, p_monto, p_plazo_meses, v_tea, round(v_cuota, 2),
    v_purpose, 'enviado', now(), now()
  )
  returning id into v_id;

  v_expediente := 'EXP-' || upper(substr(replace(v_id::text, '-', ''), 1, 8));

  return jsonb_build_object(
    'id', v_id,
    'expediente', v_expediente,
    'status', 'enviado'
  );
end;
$$;

grant execute on function public.rpc_registrar_solicitud_cliente(
  text, text, text, numeric, integer, text, text
) to anon, authenticated;

create or replace function public.rpc_mis_solicitudes_cliente(p_documento text)
returns setof public.fv_credit_applications
language sql
security definer
set search_path = public
stable
as $$
  select *
  from public.fv_credit_applications
  where client_dni = trim(p_documento)
  order by submitted_at desc;
$$;

grant execute on function public.rpc_mis_solicitudes_cliente(text) to anon, authenticated;

-- Permitir insert/select anon en fv_credit_applications (apps comparten publishable key)
do $$
begin
  drop policy if exists "fv_apps_rw_anon" on public.fv_credit_applications;
  create policy "fv_apps_rw_anon" on public.fv_credit_applications
    for all to anon using (true) with check (true);
  drop policy if exists "fv_apps_rw_auth" on public.fv_credit_applications;
  create policy "fv_apps_rw_auth" on public.fv_credit_applications
    for all to authenticated using (true) with check (true);
end $$;
