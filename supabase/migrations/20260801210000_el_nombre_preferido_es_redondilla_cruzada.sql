begin;

-- El nombre preferido para abab es «redondilla cruzada»; «cuarteta» es alias histórico.
--
-- La redondilla es una sola forma con dos disposiciones, abrazada y cruzada, y así está
-- definida. Pero las respuestas no lo decían igual en todas partes: el villancico ofrecía
-- «abba — redondilla» y «abab — cuarteta», que afirma que la cuarteta es otra forma y que una
-- mudanza abba «es» una redondilla en vez de tener una disposición; la novena decía «Cruzada ·
-- abab» sin más; y la propia redondilla, «Cruzada · abab (cuarteta)». Tres maneras de nombrar
-- lo mismo en el mismo catálogo.
--
-- Se unifican en «Redondilla abrazada · abba» y «Redondilla cruzada · abab (cuarteta)». El
-- alias va entre paréntesis porque el renombramiento es posterior y hay bibliografía que lo
-- usa: quien lo conozca lo reconoce, y quien no, no tiene que aprendérselo para anotar.
--
-- El arte mayor no entra: el cuarteto tiene su propia pareja abrazada/cruzada —esta última es
-- lo que la tradición llama serventesio— y sus respuestas escriben el esquema en mayúsculas.
-- Esa diferencia de caja es justamente el criterio que separa unas de otras aquí.

update public.opciones_eleccion_metrica opcion
set
	nombre = 'Redondilla cruzada · abab (cuarteta)',
	descripcion = coalesce(
		opcion.descripcion,
		'Dos rimas consonantes dispuestas de forma cruzada. Esta realización recibe también la denominación «Cuarteta».'
	)
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.dimension = 'rima'
	and opcion.nombre like '%abab%';

update public.opciones_eleccion_metrica opcion
set
	nombre = 'Redondilla abrazada · abba',
	descripcion = coalesce(opcion.descripcion, 'Dos rimas consonantes dispuestas de forma abrazada.')
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.dimension = 'rima'
	and opcion.nombre like '%abba%';

-- El esquema normalizado que sostiene esas respuestas se nombraba por el alias.
update public.esquemas_rima
set nombre = 'Mudanza en redondilla cruzada'
where nombre = 'Mudanza en cuarteta';

-- La estrofa que cierra el terceto encadenado octosílabo reutiliza la redondilla octosilábica,
-- así que se nombra como ella. El tipo de sección no se toca: es identidad analítica.
update public.estructuras_secciones
set nombre = 'Redondilla cruzada final'
where nombre = 'Cuarteta final';

-- La rima de la primera mudanza suele repetirse en las siguientes, así que su respuesta debe
-- poder valer para todas. Sin esta marca, el editor la responde aparte aunque no cambie.
update public.grupos_eleccion_metrica
set permite_aplicar_global = true
where slug = 'rima_primera_mudanza';

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_cruzada integer;
	v_abrazada integer;
	v_restos integer;
	v_arte_mayor integer;
	v_primera_mudanza integer;
begin
	select count(*) into v_cruzada
	from public.opciones_eleccion_metrica
	where nombre = 'Redondilla cruzada · abab (cuarteta)';
	select count(*) into v_abrazada
	from public.opciones_eleccion_metrica
	where nombre = 'Redondilla abrazada · abba';
	if v_cruzada <> v_abrazada or v_cruzada = 0 then
		raise exception 'Las disposiciones no quedaron emparejadas: % cruzadas y % abrazadas',
			v_cruzada, v_abrazada;
	end if;

	-- Ninguna respuesta de rima sigue diciendo «cuarteta» como si fuera la forma.
	select count(*) into v_restos
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	where grupo.dimension = 'rima'
		and opcion.nombre ilike '%cuarteta%'
		and opcion.nombre <> 'Redondilla cruzada · abab (cuarteta)';
	if v_restos <> 0 then
		raise exception 'Quedan % respuestas de rima con el alias como nombre principal', v_restos;
	end if;

	-- El arte mayor conserva las suyas.
	select count(*) into v_arte_mayor
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'cuarteto' and opcion.nombre like '%ABBA%';
	if v_arte_mayor = 0 then
		raise exception 'Se han tocado las respuestas del cuarteto de arte mayor';
	end if;

	select count(*) into v_primera_mudanza
	from public.grupos_eleccion_metrica
	where slug = 'rima_primera_mudanza' and permite_aplicar_global;
	if v_primera_mudanza = 0 then
		raise exception 'La rima de la primera mudanza sigue sin poder aplicarse a todas';
	end if;
end;
$$;

commit;
