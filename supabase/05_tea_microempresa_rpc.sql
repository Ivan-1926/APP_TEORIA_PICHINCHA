-- =============================================================================
-- RPC solicitud cliente — TEA tarifario microempresa (40.92 / 43.92)
-- Ejecutar en Supabase SQL Editor tras 04_cliente_solicitud_credito.sql
-- =============================================================================

create or replace function public.rpc_registrar_solicitud_cliente(
  p_documento   text,
  p_nombre      text,
  p_producto    text,
  p_monto       numeric,
  p_plazo_meses integer,
  p_destino     text,
  p_garantia    text default null,
  p_tea         numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id         uuid;
  v_tea        numeric;
  v_tem        numeric;
  v_cuota      numeric;
  v_expediente text;
  v_purpose    text;
begin
  v_tea := coalesce(
    p_tea,
    case
      when lower(coalesce(p_producto, '')) like '%empresarial%'
        or lower(coalesce(p_producto, '')) like '%microempresa%'
      then 43.92
      else 18.0
    end
  );

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
    'status', 'enviado',
    'tea', v_tea,
    'monthly_payment', round(v_cuota, 2)
  );
end;
$$;

grant execute on function public.rpc_registrar_solicitud_cliente(
  text, text, text, numeric, integer, text, text, numeric
) to anon, authenticated;
