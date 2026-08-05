-- El catálogo de formas como sección pública, apagable desde /dashboard/publicacion.
--
-- Nace en `admin_ip` como el demarcador: es un recurso en construcción y conviene mirarlo
-- antes de enseñarlo. Abrirlo es cambiar `scope_minimo` desde el panel, sin tocar código.

begin;

insert into public.secciones_publicas (seccion_id, label, descripcion, activa, scope_minimo, orden)
values (
	'formas',
	'Catálogo de formas',
	'Ficha de cada forma métrica generada desde el catálogo: arquitecturas, esquemas, secciones, rasgos, denominaciones y lo que dicen las fuentes. Se actualiza sola con el dato.',
	true,
	'admin_ip',
	50
)
on conflict (seccion_id) do nothing;

commit;
