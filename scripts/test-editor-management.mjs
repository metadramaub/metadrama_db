/** Ejecuta el reparto real en Supabase y revierte todos los fixtures y cambios. */
import { readFileSync } from 'node:fs';
import { query } from './lib/consulta.mjs';

const migration = process.argv.includes('--with-migration')
	? [
			'20261019120000_gestion_de_asignaciones_en_lote.sql',
			'20261019123000_los_gestores_ven_editores_deshabilitados.sql',
			'20261019130000_los_conflictos_de_reparto_no_se_reintentan.sql'
		]
			.map((file) =>
				readFileSync(new URL(`../supabase/migrations/${file}`, import.meta.url), 'utf8')
			)
			.join('\n')
	: '';

const assertions = `
do $$
declare
  actor uuid := gen_random_uuid();
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  disabled uuid := gen_random_uuid();
  w1 uuid := gen_random_uuid();
  w2 uuid := gen_random_uuid();
  role_editor uuid;
  role_admin uuid;
  draft uuid;
  snapshot jsonb;
  result integer;
begin
  select termino_id into strict role_editor from public.vocabularios where categoria = 'role_editor' and lower(termino) = 'editor';
  select termino_id into strict role_admin from public.vocabularios where categoria = 'role_editor' and lower(termino) = 'admin';
  select termino_id into strict draft from public.vocabularios where categoria = 'estado' and lower(termino) = 'borrador';
  insert into auth.users(id, email) values
    (actor, actor::text || '@editor-test.invalid'), (a, a::text || '@editor-test.invalid'),
    (b, b::text || '@editor-test.invalid'), (disabled, disabled::text || '@editor-test.invalid');
  insert into public.editores(user_id,nombre_completo,email,role,activo) values
    (actor, 'Prueba gestor', actor::text || '@editor-test.invalid', role_admin, true),
    (a, 'Prueba A', a::text || '@editor-test.invalid', role_editor, true),
    (b, 'Prueba B', b::text || '@editor-test.invalid', role_editor, true),
    (disabled, 'Prueba deshabilitado', disabled::text || '@editor-test.invalid', role_editor, false);
  insert into public.obras(obra_id,titulo,titulo_normalizado,estado,editor_asignado) values
    (w1, 'Prueba reparto uno', 'prueba reparto uno', draft, a),
    (w2, 'Prueba reparto dos', 'prueba reparto dos', draft, a);
  perform set_config('request.jwt.claim.sub', actor::text, true);
  select jsonb_agg(jsonb_build_object('obra_id', obra_id, 'editor_asignado', editor_asignado, 'reviewer_ids', '[]'::jsonb) order by obra_id)
    into snapshot from public.obras where obra_id in (w1,w2);

  -- La comprobación se ejecuta dentro de la función, aunque se llame sin el endpoint.
  perform set_config('request.jwt.claim.sub', a::text, true);
  begin
    perform public.gestionar_asignaciones_lote('editor', b, snapshot);
    raise exception 'La función ha permitido repartir a un editor ordinario';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claim.sub', disabled::text, true);
  begin
    perform public.gestionar_asignaciones_lote('editor', b, snapshot);
    raise exception 'La función ha permitido repartir a un usuario deshabilitado';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claim.sub', actor::text, true);
  begin
    perform public.gestionar_asignaciones_lote('editor', disabled, snapshot);
    raise exception 'La función ha permitido asignar a un destino deshabilitado';
  exception when invalid_parameter_value then null; end;

  result := public.gestionar_asignaciones_lote('add_reviewer', b, snapshot);
  if result <> 2 then raise exception 'No se añadieron ambas revisiones'; end if;
  select jsonb_agg(jsonb_build_object('obra_id', obra_id, 'editor_asignado', a, 'reviewer_ids', jsonb_build_array(b)) order by obra_id)
    into snapshot from public.obras where obra_id in (w1,w2);
  if public.gestionar_asignaciones_lote('add_reviewer', b, snapshot) <> 0 then raise exception 'Añadir otra vez ha duplicado revisiones'; end if;
  begin
    perform public.gestionar_asignaciones_lote('add_reviewer', a, snapshot);
    raise exception 'Se ha permitido revisar una obra propia';
  exception when invalid_parameter_value then null; end;
  result := public.gestionar_asignaciones_lote('editor', b, snapshot);
  if result <> 2 or exists(select 1 from public.obras_revisores where obra_id in(w1,w2) and revisor_id=b) then
    raise exception 'El cambio de editor no retiró la autorrevisión';
  end if;
  if (select count(*) from public.asignaciones_historial where obra_id in(w1,w2)) <> 4 then raise exception 'Falta el historial del lote'; end if;

  -- El segundo elemento está obsoleto. El primero también debe quedar sin cambios.
  select jsonb_agg(jsonb_build_object('obra_id', obra_id, 'editor_asignado', case when obra_id = greatest(w1,w2) then a else b end, 'reviewer_ids', '[]'::jsonb) order by obra_id)
    into snapshot from public.obras where obra_id in (w1,w2);
  begin
    perform public.gestionar_asignaciones_lote('editor', a, snapshot);
    raise exception 'Se ha permitido aplicar una selección obsoleta';
  exception when sqlstate 'PT409' then null; end;
  if exists(select 1 from public.obras where obra_id in(w1,w2) and editor_asignado <> b) then raise exception 'Se ha aplicado una parte del lote fallido'; end if;
  if (select count(*) from public.asignaciones_historial where obra_id in(w1,w2)) <> 4 then raise exception 'El lote fallido dejó historial parcial'; end if;

  -- La retirada de un revisor permite limpiar destinos deshabilitados y conserva los demás.
  insert into public.obras_revisores(obra_id,revisor_id,asignado_por) values(w1,a,actor),(w1,disabled,actor);
  snapshot := jsonb_build_array(jsonb_build_object('obra_id',w1,'editor_asignado',b,'reviewer_ids',
    (select jsonb_agg(revisor_id order by revisor_id) from public.obras_revisores where obra_id=w1)));
  if public.gestionar_asignaciones_lote('remove_reviewer', disabled, snapshot) <> 1 then raise exception 'No se retiró el revisor deshabilitado'; end if;
  if not exists(select 1 from public.obras_revisores where obra_id=w1 and revisor_id=a) then raise exception 'Se han borrado otros revisores'; end if;
  if has_function_privilege('anon', 'public.gestionar_asignaciones_lote(text,uuid,jsonb)', 'execute') then raise exception 'El anónimo puede ejecutar la función'; end if;
  perform set_config('editor_test.actor', actor::text, true);
  perform set_config('editor_test.regular', a::text, true);
  perform set_config('editor_test.work', w1::text, true);
end;
$$;
set local role authenticated;
do $$ begin
  perform set_config('request.jwt.claim.sub', current_setting('editor_test.regular'), true);
  if exists(select 1 from public.asignaciones_historial where obra_id=current_setting('editor_test.work')::uuid) then
    raise exception 'Un editor ordinario puede leer el historial de gestión';
  end if;
  perform set_config('request.jwt.claim.sub', current_setting('editor_test.actor'), true);
  if (select count(*) from public.asignaciones_historial where obra_id=current_setting('editor_test.work')::uuid) < 2 then
    raise exception 'El gestor no puede leer el historial';
  end if;
end $$;
reset role;
`;
const result = query(
	`begin; ${migration} ${assertions} rollback; select 'Permisos, altas de revisión, reasignación, retirada, historial y atomicidad verificados; fixtures revertidos.' as resultado;`
);
console.log(result[0]?.resultado ?? result);
