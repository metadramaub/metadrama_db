/** Matriz de SELECT de la expansión con las cuentas restauradas, sin extraer sus identidades. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const carpeta =
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim();
const contenedor = 'versologia-control-obras-preparacion';
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
	if (r.status !== 0) throw Error((r.stderr || 'Docker').slice(-2000));
	return r.stdout;
}
const c = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	c.HostConfig.NetworkMode !== 'none' ||
	Object.keys(c.HostConfig.PortBindings ?? {}).length ||
	c.Config.Labels['versologia.tarea'] !== 'control-obras'
)
	throw Error('Contenedor no aislado');
const sql = (s) =>
	docker(
		[
			'exec',
			'-i',
			contenedor,
			'psql',
			'-X',
			'-q',
			'-At',
			'-U',
			'supabase_admin',
			'-d',
			'control_obras_preparacion',
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
const resultados = JSON.parse(
	sql(`begin;
create function pg_temp.comprobar_accesos() returns jsonb language plpgsql as $$
declare e record; n integer; esperado integer; total integer; fichas integer; salida jsonb:='[]';
begin
 select count(*) into total from public.obras;
 for e in select ed.user_id,coalesce(ed.activo,true) as activo,lower(v.termino) as rol
          from public.editores ed join public.vocabularios v on v.termino_id=ed.role loop
  perform set_config('request.jwt.claim.sub',e.user_id::text,true);
  execute 'set local role authenticated';
  select count(*) into n from public.control_obras_preparacion;
  select count(*) into fichas from public.fichas_completas;
  execute 'reset role';
  esperado:=case when e.activo and e.rol in ('admin','ip') then total else 0 end;
  if n<>esperado then raise exception 'Control global accesible para rol % o incompleto',e.rol; end if;
  if e.activo and e.rol in ('admin','ip') and fichas<>(select count(*) from public.fichas_completas) then
   raise exception 'Gestor no puede consultar todas las completas';
  end if;
  if e.activo and e.rol='editor' and fichas<>(
   select count(*) from public.fichas_completas f where f.editor_asignado=e.user_id or exists(
    select 1 from public.obras_revisores r where r.obra_id=f.obra_id and r.revisor_id=e.user_id)) then
   raise exception 'El editor ve completas distintas de sus encargos/revisiones';
  end if;
  if not e.activo and fichas<>0 then raise exception 'Cuenta deshabilitada conserva acceso'; end if;
  salida:=salida||jsonb_build_array(jsonb_build_object('rol',e.rol,'activo',e.activo,
    'control_global_correcto',true,'completas_correctas',true));
 end loop;
 return salida;
end $$;
select pg_temp.comprobar_accesos();
rollback;`).trim()
);
writeFileSync(
	join(carpeta, 'validacion-acceso.json'),
	JSON.stringify(
		{ ejecutado_en: new Date().toISOString(), cuentas: resultados.length, resultados },
		null,
		2
	) + '\n',
	'utf8'
);
console.log(
	`Acceso comprobado mediante SET ROLE y JWT para ${resultados.length} perfiles restaurados; sin cambios persistidos.`
);
