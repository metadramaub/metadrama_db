begin;

-- Las estrofas básicas existen una vez y las formas complejas las reutilizan.
--
-- La tradición nombra con cuatro palabras la misma rejilla de cuatro versos:
--
--                  abba          abab
--   arte menor     redondilla    cuarteta
--   arte mayor     cuarteto      serventesio
--
-- El catálogo tenía la fila de arriba —la redondilla, con «Cuarteta» como denominación de su
-- disposición cruzada— y no la de abajo. Por eso los cuartetos del soneto no tenían a qué
-- apuntar y declaraban su propio esquema, mientras sus tercetos sí reutilizaban el terceto:
-- dos tratamientos del mismo hecho dentro de la misma arquitectura.
--
-- Lo que trae la reutilización: el metro y el repertorio de esquemas de esa sección. Lo que
-- no trae: los enlaces entre secciones, que solo la forma contenedora puede declarar. Por eso
-- la espinela reutiliza la redondilla y conserva su esquema de diez posiciones, donde vive el
-- trabado —la `a` de la primera redondilla vuelve en el verso quinto y el puente enlaza con la
-- `c` de la segunda—: la décima no es dos redondillas seguidas, es dos redondillas trabadas.
--
-- Y reutilizar no afirma parentesco. Para eso está `compuesta_por`, que se declara aparte y
-- solo cuando es cierto: la copla real sí se formó de dos quintillas, el soneto no se formó
-- de cuartetos y tercetos.
--
-- La mudanza del villancico queda fuera a propósito. Estructuralmente es una redondilla, pero
-- la redondilla se reparte por medidas y el villancico elige la suya al registrar: apuntar a
-- `redondilla · octosilabica` contradiría un villancico hexasílabo. Reutilizar exige que la
-- medida esté fijada en las dos puntas.

-- ---------------------------------------------------------------------------
-- 1 · El cuarteto
-- ---------------------------------------------------------------------------

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_abba uuid;
	v_abab uuid;
	v_grupo uuid;
	v_consonante uuid;
	v_endecasilabo uuid;
begin
	select esquema.tipo_rima_id into v_consonante
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and esquema.slug = 'abab'
	limit 1;

	select metro_id into v_endecasilabo from public.metros where slug = 'endecasilabo';

	insert into public.formas_metricas (
		slug, nombre, definicion, nivel_estructural, tipo_registro, grado_especificacion,
		seleccionable, estado_revision, activo
	)
	values (
		'cuarteto', 'Cuarteto',
		'Estrofa de cuatro versos de arte mayor con rima consonante. Abrazada es el cuarteto propiamente dicho; cruzada es lo que la tradición llama serventesio.',
		'estrofa', 'forma', 'especifica', true, 'revisada', true
	)
	returning forma_id into v_forma;

	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'endecasilabica', 'Endecasilábica',
		'Cuatro endecasílabos consonantes.',
		true, true, 'preferente', v_consonante, 4, 4, 'revisada', true, 1
	)
	returning arquitectura_id into v_arq;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, estado_revision
	)
	values (v_arq, '11-repetido', 'Endecasílabo repetido', 'unidad', 'ciclo', 'revisada')
	returning esquema_metrico_id into v_metrico;

	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_metrico, 1, v_endecasilabo, 1);

	-- El disparador deriva las posiciones de la notación.
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, modalidad,
		tipo_secuencia, estado_revision
	)
	values (v_arq, 'abba', 'Abrazada', 'ABBA', v_consonante, 'unidad', 'preferente', 'secuencia', 'revisada')
	returning esquema_rima_id into v_abba;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, modalidad,
		tipo_secuencia, estado_revision
	)
	values (v_arq, 'abab', 'Cruzada', 'ABAB', v_consonante, 'unidad', 'admitida', 'secuencia', 'revisada')
	returning esquema_rima_id into v_abab;

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_arq, 'disposicion_rima', '¿Cómo se distribuyen las dos rimas?',
		'Abrazada es el cuarteto; cruzada es el serventesio.',
		'rima', 'unidad', 'opciones', 1, 1, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, esquema_rima_id, orden)
	values (v_grupo, 'abba', 'Abrazada · ABBA', v_abba, 1),
		(v_grupo, 'abab', 'Cruzada · ABAB', v_abab, 2);

	insert into public.denominaciones_metricas (esquema_rima_id, nombre, slug_normalizado, tipo_alias, idioma)
	values (v_abab, 'Serventesio', 'serventesio', 'equivalente', 'es');
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · El soneto reutiliza el cuarteto, y admite las dos disposiciones
-- ---------------------------------------------------------------------------
--
-- `ABBA ABBA` sigue siendo lo esperable y por eso su esquema es preferente, pero `ABAB` es
-- una realización real del soneto y el catálogo no debe negarla: lo que hace la escala de
-- modalidad es decir cuál es la típica, no cuál está permitida.

do $$
declare
	v_soneto uuid;
	v_seccion uuid;
	v_cuarteto uuid;
	v_grupo uuid;
	v_abba_propio uuid;
begin
	select arquitectura.arquitectura_id into v_soneto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'soneto';

	select arquitectura.arquitectura_id into v_cuarteto
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'cuarteto' and arquitectura.slug = 'endecasilabica';

	select seccion_id into v_seccion
	from public.estructuras_secciones
	where arquitectura_id = v_soneto and slug = 'cuarteto';

	select esquema_rima_id into v_abba_propio
	from public.esquemas_rima where arquitectura_id = v_soneto and slug = 'abba';

	update public.estructuras_secciones
	set arquitectura_referenciada_id = v_cuarteto,
		esquema_rima_id = null,
		nota = 'Los dos cuartetos comparten sus dos clases de rima. Reutilizan el repertorio del cuarteto: el soneto no se formó sumando cuartetos.'
	where seccion_id = v_seccion;

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id,
		tipo_control, selecciones_min, selecciones_max, permite_aplicar_global,
		estado_revision, activo, orden
	)
	values (
		v_soneto, 'esquema_cuartetos', '¿Qué esquema presentan los cuartetos?',
		'Lo esperable es ABBA en ambos. ABAB existe y se registra igual.',
		'rima', 'unidad', v_seccion, 'opciones', 1, 1, true, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, descripcion, esquema_rima_id, orden)
	select v_grupo, esquema.slug,
		case esquema.slug when 'abba' then 'ABBA ABBA' else 'ABAB ABAB' end,
		case esquema.slug
			when 'abba' then 'La disposición esperable del soneto castellano.'
			else 'Disposición documentada, menos frecuente.'
		end,
		esquema.esquema_rima_id,
		case esquema.slug when 'abba' then 1 else 2 end
	from public.esquemas_rima esquema
	where esquema.arquitectura_id = v_cuarteto and esquema.slug in ('abba', 'abab');

	delete from public.esquemas_rima where esquema_rima_id = v_abba_propio;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Las décimas reutilizan la redondilla
-- ---------------------------------------------------------------------------

update public.estructuras_secciones seccion
set arquitectura_referenciada_id = (
	select arquitectura.arquitectura_id
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and arquitectura.slug = 'octosilabica'
)
from public.arquitecturas_forma arquitectura, public.formas_metricas forma
where arquitectura.arquitectura_id = seccion.arquitectura_id
	and forma.forma_id = arquitectura.forma_id
	and (
		(forma.slug = 'decima_espinela' and seccion.slug in ('primera_redondilla', 'segunda_redondilla'))
		or (forma.slug = 'decima_aumentada' and seccion.slug = 'primer_bloque')
	);

-- ---------------------------------------------------------------------------
-- 4 · La forma que reutiliza no vuelve a declarar el metro de lo reutilizado
-- ---------------------------------------------------------------------------
--
-- La copla real es octosilábica precisamente por ser dos quintillas, y sus dos secciones
-- cubren sus diez versos: su esquema propio no añadía nada que la reutilización no traiga.

delete from public.esquemas_metricos esquema
using public.arquitecturas_forma arquitectura, public.formas_metricas forma
where arquitectura.arquitectura_id = esquema.arquitectura_id
	and forma.forma_id = arquitectura.forma_id
	and forma.slug = 'copla_real';

-- La seguidilla compuesta declaraba sus siete posiciones mientras su cuerpo reutilizaba la
-- simple, que ya declara las cuatro primeras. Su esquema pasa a describir solo el estribillo.
do $$
declare
	v_arq uuid;
	v_esquema uuid;
	v_seccion uuid;
	v_pentasilabo uuid;
	v_heptasilabo uuid;
begin
	select arquitectura.arquitectura_id into v_arq
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'seguidilla' and arquitectura.slug = 'compuesta';

	select esquema_metrico_id into v_esquema
	from public.esquemas_metricos where arquitectura_id = v_arq;

	select seccion_id into v_seccion
	from public.estructuras_secciones where arquitectura_id = v_arq and slug = 'estribillo';

	select metro_id into v_pentasilabo from public.metros where slug = 'pentasilabo';
	select metro_id into v_heptasilabo from public.metros where slug = 'heptasilabo';

	delete from public.esquema_metrico_posiciones where esquema_metrico_id = v_esquema;

	update public.esquemas_metricos
	set slug = '5-7-5', nombre = '5-7-5', ambito = 'seccion', tipo_secuencia = 'secuencia'
	where esquema_metrico_id = v_esquema;

	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_esquema, 1, v_pentasilabo, 1),
		(v_esquema, 2, v_heptasilabo, 1),
		(v_esquema, 3, v_pentasilabo, 1);

	update public.estructuras_secciones
	set esquema_metrico_id = v_esquema
	where seccion_id = v_seccion;
end;
$$;

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_formas integer;
	v_reutilizan integer;
	v_opciones integer;
begin
	select count(*) into v_formas from public.formas_metricas where tipo_registro = 'forma';
	if v_formas <> 26 then
		raise exception 'Se esperaban 26 formas y hay %', v_formas;
	end if;

	select count(*) into v_reutilizan
	from public.estructuras_secciones where arquitectura_referenciada_id is not null;
	if v_reutilizan <> 12 then
		raise exception 'Se esperaban 12 secciones que reutilizan y hay %', v_reutilizan;
	end if;

	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	where grupo.slug = 'esquema_cuartetos';
	if v_opciones <> 2 then
		raise exception 'El soneto debe ofrecer dos disposiciones de cuartetos y ofrece %', v_opciones;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 54,
	revision = revision + 1,
	actualizado_en = now();

commit;
