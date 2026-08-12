-- El editor deriva todas sus etiquetas y solo guarda la ayuda que aporta criterio.
--
-- Habían quedado tres clases de prosa editorial:
--
--   · `formas_metricas.pregunta_arquitectura`, con dos excepciones al rótulo «Arquitectura»;
--   · `rasgos_metricos.pregunta`, que convertía en interrogación el nombre del rasgo;
--   · `grupos_eleccion_metrica.ayuda_editor`, con 51 usos y solo 31 textos distintos.
--
-- Las dos primeras no añaden datos. «Estribillo inicial» y «Estribillo tras la primera copla»
-- ya responden dónde aparece el estribillo; «Densidad de rima», «Dístico final» o «Vocales de
-- la asonancia» son mejores etiquetas breves que otra frase escrita a mano. La vista resuelta
-- toma desde ahora el nombre del rasgo y el editor usa siempre «Arquitectura».
--
-- `ayuda_editor` sí conserva una función propia, pero solo en el grupo, que es la decisión
-- efectiva que toma el editor. Se vacían las instrucciones que repetían el control, el rango,
-- las opciones o `permite_aplicar_global`; quedan únicamente formatos de entrada, criterios de
-- clasificación y precisiones necesarias para saber qué observar.
--
-- La misma lectura cierra el estribillo implícito del villancico. Una edición crítica resuelve
-- las acotaciones o abreviaciones y ofrece versos materiales: la repetición es total o parcial.
-- En la arquitectura con estribillo posterior, la primera aparición es obligatoria y no es una
-- repetición; el editor la reconoce porque la repetición total toma su extensión de esa misma
-- sección y empieza a preguntar en la aparición siguiente.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Los nombres del catálogo son las etiquetas del editor
-- ---------------------------------------------------------------------------

create or replace view public.grupos_eleccion_metrica_resueltos
with (security_invoker = on) as
select g.*,
	case
		when g.dimension = 'rasgo' then rm.nombre
		when g.dimension = 'repeticion' then rep.nombre
		else concat_ws(' · ', coalesce(s.nombre, st.nombre),
			case g.dimension
				when 'rima' then case
					when g.tipo_control = 'esquema_rima' then 'Esquema de rima observado'
					else 'Esquema de rima' end
				when 'metro' then case
					when m.quebrados then 'Medida de los quebrados'
					when m.posicional then 'Medida de cada verso'
					else 'Medida de los versos' end
				when 'combinacion' then 'Variedad'
			end)
	end as nombre
from public.grupos_eleccion_metrica g
left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
left join public.estructuras_secciones st on st.seccion_id = g.seccion_tratada_id
left join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
left join lateral (
	select coalesce(bool_and(o.posicion_unidad is not null), false) as posicional,
		coalesce(bool_and(eo.rol = 'quebrado'), false) as quebrados
	from public.opciones_eleccion_metrica o
	left join public.esquemas_metricos em on em.arquitectura_id = g.arquitectura_id
	left join public.esquema_metrico_opciones eo
		on eo.esquema_metrico_id = em.esquema_metrico_id and eo.metro_id = o.metro_id
	where o.grupo_eleccion_id = g.grupo_eleccion_id
) m on g.dimension = 'metro'
left join lateral (
	select ms.nombre
	from public.repeticiones_metricas rp
	join public.estructuras_secciones ms on ms.seccion_id = rp.materializa_seccion_id
	where rp.arquitectura_id = g.arquitectura_id
	limit 1
) rep on g.dimension = 'repeticion';

comment on view public.grupos_eleccion_metrica_resueltos is
	'Las elecciones registrables con su etiqueta calculada al leer. La etiqueta sale del nombre del rasgo o de la dimensión y la sección; `ayuda_editor` es la única prosa suplementaria y solo aparece cuando aporta un criterio que esos datos no expresan.';

grant select on public.grupos_eleccion_metrica_resueltos to authenticated;

alter table public.rasgos_metricos drop column pregunta;
alter table public.formas_metricas drop column pregunta_arquitectura;

comment on column public.grupos_eleccion_metrica.ayuda_editor is
	'Criterio breve imprescindible para responder esta elección. No repite la etiqueta, las opciones, el rango, la aplicación global ni la teoría de la forma.';

-- ---------------------------------------------------------------------------
-- 2 · Se retira toda ayuda y se reponen solo las que añaden criterio
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica
set ayuda_editor = null,
	updated_at = now()
where ayuda_editor is not null;

-- Formato de una respuesta abierta.
update public.grupos_eleccion_metrica g
set ayuda_editor = 'Escribe seis posiciones con letras y guiones, por ejemplo AABCCB.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'sexteto'
	and g.slug = 'esquema_rima_observado';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'Escribe una letra por verso. La misma disposición debe mantenerse en todas las estancias.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'cancion_petrarquista'
	and g.slug = 'esquema_rima_estancia';

-- Límites que cambian la clasificación de la secuencia.
update public.grupos_eleccion_metrica g
set ayuda_editor = case g.slug
		when 'densidad_de_rima' then 'Si rima más de la mitad de los versos, el pasaje deja de ser endecasílabo suelto y se registra como silva.'
		when 'organizacion_en_pareados' then 'Los pareados pueden aparecer de forma ocasional, pero no organizar sistemáticamente la serie.'
	end,
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'endecasilabo_suelto'
	and g.slug in ('densidad_de_rima', 'organizacion_en_pareados');

update public.grupos_eleccion_metrica g
set ayuda_editor = 'Si los pareados organizan sistemáticamente toda la secuencia, se registra como tirada de pareados y no como silva.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'silva'
	and g.slug = 'organizacion_en_pareados';

-- Precisiones sobre la parte que debe observarse.
update public.grupos_eleccion_metrica g
set ayuda_editor = 'Registra las vocales compartidas por los versos pares.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'romance'
	and g.slug = 'vocales_asonancia';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'Registra las vocales compartidas por los endecasílabos.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'endecha_real'
	and g.slug = 'vocales_asonancia';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'La asonancia sostenida mantiene una sola rima durante todo el pasaje; las demás disposiciones la cierran por ciclo o prescinden de ella.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'endecha_real'
	and g.slug = 'disposicion_rima';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'El tercer verso suele ser endecasílabo; registra diez o doce sílabas solo cuando esa sea la medida observada.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'seguidilla'
	and a.slug = 'gitana'
	and g.slug = 'medida_tercer_verso';

-- Controles opcionales cuyo vacío necesita una interpretación concreta.
update public.grupos_eleccion_metrica g
set ayuda_editor = 'Marca la disposición manriqueña; déjala sin marcar para cualquier otra disposición regular.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'sextilla'
	and a.slug = 'doble_pie_quebrado'
	and g.slug = 'esquema_rima';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'Selecciona únicamente las posiciones quebradas; el resto de los versos son octosílabos.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'copla_real'
	and g.slug = 'posiciones_pie_quebrado';

update public.grupos_eleccion_metrica g
set ayuda_editor = 'Selecciona las posiciones quebradas y si tienen cuatro o cinco sílabas; el resto de los versos son octosílabos.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'copla_de_pie_quebrado'
	and g.slug = 'medidas_pies_quebrados';

-- ---------------------------------------------------------------------------
-- 3 · El villancico solo registra repeticiones materiales
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from public.repeticiones_metricas r
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and r.slug = 'represa_implicita';
	if v_n <> 2 then
		raise exception 'Se esperaban 2 repeticiones implícitas del villancico y hay %', v_n;
	end if;

	select count(*) into v_n
	from public.elecciones_editor_metrico e
	join public.repeticiones_metricas r on r.repeticion_id = e.repeticion_id
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and r.slug = 'represa_implicita';
	if v_n <> 0 then
		raise exception 'Hay % elecciones que todavía usan la repetición implícita del villancico', v_n;
	end if;

	select count(*) into v_n
	from public.desviaciones_editor_metrico d
	join public.repeticiones_metricas r on r.repeticion_id = d.repeticion_observada_id
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and r.slug = 'represa_implicita';
	if v_n <> 0 then
		raise exception 'Hay % desviaciones que todavía usan la repetición implícita del villancico', v_n;
	end if;
end;
$$;

delete from public.repeticiones_metricas r
using public.arquitecturas_forma a, public.formas_metricas f
where r.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id
	and f.slug = 'villancico'
	and r.slug = 'represa_implicita';

update public.repeticiones_metricas r
set descripcion = case r.slug
		when 'represa_total' then 'El estribillo vuelve entero, con todos sus versos.'
		when 'represa_parcial' then 'Solo vuelve una parte del estribillo; se registran únicamente los versos presentes.'
	end,
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where r.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and r.slug in ('represa_total', 'represa_parcial');

update public.grupos_eleccion_metrica g
set ayuda_editor = 'La edición crítica debe ofrecer los versos repetidos. Indica si vuelve el estribillo entero o solo una parte.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where g.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and g.slug = 'represa_estribillo';

update public.estructuras_secciones s
set repeticiones_min = 1,
	nota = 'El estribillo que sigue a cada copla. En el primer ciclo es su primera aparición; en los siguientes, una repetición total o parcial.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'villancico'
	and a.slug = 'estribillo_tras_primera_copla'
	and s.slug = 'estribillo';

-- ---------------------------------------------------------------------------
-- 4 · Guardas: una sola capa de ayuda y ninguna pregunta manual
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	select count(*) into v_n
	from information_schema.columns
	where table_schema = 'public'
		and ((table_name = 'formas_metricas' and column_name = 'pregunta_arquitectura')
			or (table_name = 'rasgos_metricos' and column_name = 'pregunta'));
	if v_n <> 0 then
		raise exception 'Quedan % columnas de pregunta manual', v_n;
	end if;

	select count(*), string_agg(f.slug || '·' || a.slug || '·' || g.slug, ', ' order by f.slug, a.slug, g.slug)
	into v_n, v_mal
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.activo and a.activo and g.activo
		and nullif(btrim(g.ayuda_editor), '') is not null;
	if v_n <> 21 then
		raise exception 'Quedaron % ayudas activas en vez de 21: %', v_n, v_mal;
	end if;

	select count(*) into v_n
	from public.repeticiones_metricas r
	join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and r.slug = 'represa_implicita';
	if v_n <> 0 then
		raise exception 'Quedan % repeticiones implícitas en el villancico', v_n;
	end if;

	select count(*) into v_n
	from public.grupos_eleccion_metrica_resueltos g
	where g.activo and nullif(btrim(g.nombre), '') is null;
	if v_n <> 0 then
		raise exception '% elecciones activas se quedaron sin etiqueta derivada', v_n;
	end if;

	-- Las tres proyecciones que consumen el catálogo deben seguir siendo ejecutables después
	-- de retirar las columnas. No se valida aquí su contenido completo: cada función ya lo deriva.
	select public.get_catalogo_formas_publicas() into v_json;
	if v_json is null then
		raise exception 'La proyección del catálogo público devolvió null';
	end if;
	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if v_json is null then
		raise exception 'La ficha pública del villancico devolvió null';
	end if;
	select public.obtener_catalogo_demarcador() into v_json;
	if v_json is null then
		raise exception 'La proyección del demarcador devolvió null';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
