begin;

-- Catálogo métrico independiente. Esta migración es deliberadamente aditiva:
-- no modifica las declaraciones métricas de las secuencias ni sustituye el
-- vocabulario actual.

alter table public.demarcador_versiones
	add column if not exists fuente_tipo text not null default 'vocabulario_legacy'
		check (fuente_tipo in ('vocabulario_legacy', 'catalogo_metrico')),
	add column if not exists catalogo_revision bigint null;

comment on column public.demarcador_versiones.fuente_tipo is
	'Distingue las versiones del demarcador legado de las pruebas compiladas desde el nuevo catálogo.';

create table public.formas_metricas (
	forma_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	definicion text null,
	nivel_estructural text not null default 'estrofa'
		check (nivel_estructural in ('verso', 'estrofa', 'serie', 'composicion', 'compuesta')),
	seleccionable boolean not null default true,
	residual boolean not null default false,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_by uuid null references public.editores (user_id) on update cascade on delete set null,
	updated_by uuid null references public.editores (user_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (not residual or seleccionable)
);

comment on table public.formas_metricas is
	'Identidades métricas canónicas y salidas residuales asignables. No sustituye todavía estrofa_tipo en las secuencias.';

create table public.familias_metricas (
	familia_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	familia_padre_id uuid null references public.familias_metricas (familia_id)
		on update cascade on delete restrict,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_by uuid null references public.editores (user_id) on update cascade on delete set null,
	updated_by uuid null references public.editores (user_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (familia_padre_id is null or familia_padre_id <> familia_id)
);

create table public.familias_formas (
	familia_id uuid not null references public.familias_metricas (familia_id)
		on update cascade on delete cascade,
	forma_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	es_principal boolean not null default false,
	orden integer null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (familia_id, forma_id)
);

create unique index familias_formas_principal_idx
	on public.familias_formas (forma_id)
	where es_principal;

create table public.tradiciones_metricas (
	tradicion_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	ambito_geografico text null,
	periodo_desde smallint null,
	periodo_hasta smallint null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	created_by uuid null references public.editores (user_id) on update cascade on delete set null,
	updated_by uuid null references public.editores (user_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (periodo_desde is null or periodo_hasta is null or periodo_desde <= periodo_hasta)
);

create table public.formas_tradiciones (
	forma_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	tradicion_id uuid not null references public.tradiciones_metricas (tradicion_id)
		on update cascade on delete cascade,
	tipo_relacion text not null
		check (tipo_relacion in ('origen', 'adaptacion', 'difusion', 'uso')),
	es_principal boolean not null default false,
	cronologia text null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (forma_id, tradicion_id, tipo_relacion)
);

create table public.forma_aliases (
	alias_id uuid primary key default gen_random_uuid(),
	forma_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	nombre text not null check (btrim(nombre) <> ''),
	slug_normalizado text not null check (btrim(slug_normalizado) <> ''),
	tipo_alias text not null default 'equivalente'
		check (tipo_alias in ('equivalente', 'variante_grafica', 'historico', 'abreviatura')),
	idioma text null,
	preferente boolean not null default false,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (forma_id, slug_normalizado)
);

create table public.forma_relaciones (
	relacion_id uuid primary key default gen_random_uuid(),
	forma_origen_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	forma_destino_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	tipo_relacion text not null
		check (tipo_relacion in (
			'subtipo_de',
			'variante_historica_de',
			'derivada_de',
			'relacionada_con',
			'contrasta_con',
			'equivalente_de'
		)),
	nota text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (forma_origen_id <> forma_destino_id),
	unique (forma_origen_id, forma_destino_id, tipo_relacion)
);

create table public.configuraciones_forma (
	configuracion_id uuid primary key default gen_random_uuid(),
	forma_id uuid not null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	slug text not null check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	principal boolean not null default false,
	demarcable boolean not null default true,
	grado text not null default 'admitida'
		check (grado in ('fija', 'canonica', 'admitida', 'rara', 'irregular_documentada')),
	naturaleza_estrofica_id uuid null
		references public.vocabularios (termino_id) on update cascade on delete set null,
	tipo_rima_id uuid null
		references public.vocabularios (termino_id) on update cascade on delete set null,
	versos_min integer null check (versos_min is null or versos_min > 0),
	versos_max integer null check (versos_max is null or versos_max > 0),
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_by uuid null references public.editores (user_id) on update cascade on delete set null,
	updated_by uuid null references public.editores (user_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (versos_min is null or versos_max is null or versos_min <= versos_max),
	unique (forma_id, slug)
);

create unique index configuraciones_forma_principal_idx
	on public.configuraciones_forma (forma_id)
	where principal and activo;

create table public.modelos_verso (
	modelo_verso_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	metro_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete set null,
	tipo text not null check (tipo in ('simple', 'compuesto')),
	silabas_totales integer null check (silabas_totales is null or silabas_totales > 0),
	tipo_cesura text null,
	patron_acentual text null,
	descripcion text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.modelo_verso_segmentos (
	segmento_id uuid primary key default gen_random_uuid(),
	modelo_verso_id uuid not null references public.modelos_verso (modelo_verso_id)
		on update cascade on delete cascade,
	posicion integer not null check (posicion > 0),
	silabas integer not null check (silabas > 0),
	funcion text null,
	pausa_posterior text null,
	alternativa integer not null default 1 check (alternativa > 0),
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (modelo_verso_id, alternativa, posicion)
);

create table public.patrones_metricos (
	patron_metrico_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	ambito text not null default 'unidad'
		check (ambito in ('unidad', 'estrofa', 'serie', 'seccion', 'composicion')),
	tipo text not null
		check (tipo in ('secuencia_fija', 'conjunto_permitido', 'secuencia_repetible', 'abierta')),
	longitud_minima integer null check (longitud_minima is null or longitud_minima > 0),
	longitud_maxima integer null check (longitud_maxima is null or longitud_maxima > 0),
	descripcion text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (
		longitud_minima is null
		or longitud_maxima is null
		or longitud_minima <= longitud_maxima
	)
);

create table public.patron_metrico_posiciones (
	posicion_id uuid primary key default gen_random_uuid(),
	patron_metrico_id uuid not null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete cascade,
	posicion integer not null check (posicion > 0),
	metro_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete restrict,
	modelo_verso_id uuid null references public.modelos_verso (modelo_verso_id)
		on update cascade on delete restrict,
	opcional boolean not null default false,
	grupo_repeticion text null,
	alternativa integer not null default 1 check (alternativa > 0),
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (num_nonnulls(metro_id, modelo_verso_id) = 1),
	unique (patron_metrico_id, alternativa, posicion)
);

create table public.patron_metrico_opciones (
	patron_metrico_id uuid not null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete cascade,
	metro_id uuid not null references public.vocabularios (termino_id)
		on update cascade on delete restrict,
	orden integer null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (patron_metrico_id, metro_id)
);

create table public.patrones_rima (
	patron_rima_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	nombre text null,
	esquema text null,
	tipo_rima_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete set null,
	ambito text not null default 'unidad'
		check (ambito in ('unidad', 'estrofa', 'serie', 'seccion', 'composicion')),
	fijeza text not null default 'admitido'
		check (fijeza in ('fijo', 'admitido', 'preferente', 'libre', 'no_aplica')),
	descripcion text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.patron_rima_posiciones (
	posicion_id uuid primary key default gen_random_uuid(),
	patron_rima_id uuid not null references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	bloque integer not null default 1 check (bloque > 0),
	seccion text null,
	posicion integer not null check (posicion > 0),
	ubicacion text not null default 'final' check (ubicacion in ('final', 'interior')),
	clase_rima text null,
	suelto boolean not null default false,
	opcional boolean not null default false,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (patron_rima_id, bloque, posicion, ubicacion)
);

create table public.patron_rima_enlaces (
	enlace_id uuid primary key default gen_random_uuid(),
	patron_rima_id uuid not null references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	bloque_origen integer not null default 1 check (bloque_origen > 0),
	posicion_origen integer not null check (posicion_origen > 0),
	ubicacion_origen text not null default 'final' check (ubicacion_origen in ('final', 'interior')),
	desplazamiento_bloque integer not null default 0,
	bloque_destino integer null check (bloque_destino is null or bloque_destino > 0),
	posicion_destino integer not null check (posicion_destino > 0),
	ubicacion_destino text not null default 'final' check (ubicacion_destino in ('final', 'interior')),
	tipo_enlace text not null default 'misma_rima',
	obligatorio boolean not null default true,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.patron_rima_restricciones (
	restriccion_id uuid primary key default gen_random_uuid(),
	patron_rima_id uuid not null references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	tipo text not null
		check (tipo in (
			'numero_clases',
			'max_consecutivos',
			'prohibe_pareado_final',
			'versos_sueltos',
			'otra'
		)),
	valor_numero numeric null,
	valor_texto text null,
	descripcion text null,
	obligatoria boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (num_nonnulls(valor_numero, valor_texto) <= 1)
);

create table public.estructuras_secciones (
	seccion_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	seccion_padre_id uuid null references public.estructuras_secciones (seccion_id)
		on update cascade on delete cascade,
	tipo_seccion text not null check (btrim(tipo_seccion) <> ''),
	nombre text null,
	orden integer not null check (orden > 0),
	repeticiones_min integer null check (repeticiones_min is null or repeticiones_min >= 0),
	repeticiones_max integer null check (repeticiones_max is null or repeticiones_max >= 0),
	versos_min integer null check (versos_min is null or versos_min >= 0),
	versos_max integer null check (versos_max is null or versos_max >= 0),
	patron_metrico_id uuid null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete set null,
	patron_rima_id uuid null references public.patrones_rima (patron_rima_id)
		on update cascade on delete set null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (seccion_padre_id is null or seccion_padre_id <> seccion_id),
	check (
		repeticiones_min is null
		or repeticiones_max is null
		or repeticiones_min <= repeticiones_max
	),
	check (versos_min is null or versos_max is null or versos_min <= versos_max),
	unique (configuracion_id, seccion_padre_id, orden)
);

create table public.patrones_repeticion (
	patron_repeticion_id uuid primary key default gen_random_uuid(),
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	tipo text not null
		check (tipo in ('palabra_final', 'verso', 'estribillo', 'seccion', 'otro')),
	ambito text not null default 'unidad'
		check (ambito in ('unidad', 'estrofa', 'serie', 'seccion', 'composicion')),
	regla text not null check (btrim(regla) <> ''),
	fijeza text not null default 'fija'
		check (fijeza in ('fija', 'canonica', 'habitual', 'admitida')),
	descripcion text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.patron_repeticion_posiciones (
	posicion_id uuid primary key default gen_random_uuid(),
	patron_repeticion_id uuid not null references public.patrones_repeticion (patron_repeticion_id)
		on update cascade on delete cascade,
	bloque integer not null default 1 check (bloque > 0),
	posicion integer not null check (posicion > 0),
	bloque_origen integer null check (bloque_origen is null or bloque_origen > 0),
	posicion_origen integer null check (posicion_origen is null or posicion_origen > 0),
	etiqueta_funcional text null,
	condicion text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (
		(bloque_origen is null and posicion_origen is null)
		or (bloque_origen is not null and posicion_origen is not null)
	),
	unique (patron_repeticion_id, bloque, posicion)
);

create table public.rasgos_metricos (
	rasgo_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	tipo_valor text not null default 'booleano'
		check (tipo_valor in ('booleano', 'catalogo', 'texto_controlado', 'numero')),
	observabilidad text not null default 'directa'
		check (observabilidad in ('directa', 'especializada', 'derivada')),
	demarcable boolean not null default false,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.rasgo_valores (
	valor_id uuid primary key default gen_random_uuid(),
	rasgo_id uuid not null references public.rasgos_metricos (rasgo_id)
		on update cascade on delete cascade,
	slug text not null check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	descripcion text null,
	orden integer null,
	activo boolean not null default true,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (rasgo_id, slug)
);

create table public.configuracion_rasgos (
	configuracion_id uuid not null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	rasgo_id uuid not null references public.rasgos_metricos (rasgo_id)
		on update cascade on delete cascade,
	valor_id uuid null references public.rasgo_valores (valor_id)
		on update cascade on delete restrict,
	modalidad text not null default 'definitoria'
		check (modalidad in ('definitoria', 'habitual', 'admitida', 'destacable')),
	valor_numero numeric null,
	valor_texto text null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (configuracion_id, rasgo_id, modalidad),
	check (num_nonnulls(valor_id, valor_numero, valor_texto) <= 1)
);

create table public.fuentes_metricas (
	fuente_id uuid primary key default gen_random_uuid(),
	tipo text null,
	autoria text null,
	titulo text not null check (btrim(titulo) <> ''),
	anio integer null,
	publicacion text null,
	doi text null,
	url text null,
	cita text null,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

create table public.afirmaciones_fuentes_metricas (
	afirmacion_id uuid primary key default gen_random_uuid(),
	fuente_id uuid not null references public.fuentes_metricas (fuente_id)
		on update cascade on delete cascade,
	forma_id uuid null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	familia_id uuid null references public.familias_metricas (familia_id)
		on update cascade on delete cascade,
	tradicion_id uuid null references public.tradiciones_metricas (tradicion_id)
		on update cascade on delete cascade,
	configuracion_id uuid null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	patron_metrico_id uuid null references public.patrones_metricos (patron_metrico_id)
		on update cascade on delete cascade,
	patron_rima_id uuid null references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	rasgo_id uuid null references public.rasgos_metricos (rasgo_id)
		on update cascade on delete cascade,
	localizador text null,
	resumen text null,
	confianza text null check (confianza is null or confianza in ('alta', 'media', 'baja')),
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	created_by uuid null references public.editores (user_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (
		num_nonnulls(
			forma_id,
			familia_id,
			tradicion_id,
			configuracion_id,
			patron_metrico_id,
			patron_rima_id,
			rasgo_id
		) = 1
	)
);

create table public.migracion_terminos_metricos (
	termino_id uuid primary key references public.vocabularios (termino_id)
		on update cascade on delete restrict,
	clasificacion_propuesta text not null
		check (clasificacion_propuesta in ('F', 'G', 'C', 'P', 'R', 'A', 'E', 'D', '?')),
	clasificacion_decidida text null
		check (clasificacion_decidida is null or clasificacion_decidida in ('F', 'G', 'C', 'P', 'R', 'A', 'E', 'D', '?')),
	propuesta text not null,
	certeza text not null check (certeza in ('alta', 'media', 'baja')),
	requiere_revision boolean not null default true,
	estado_revision text not null default 'pendiente'
		check (estado_revision in ('pendiente', 'revisada')),
	notas_ip text null,
	revisado_por uuid null references public.editores (user_id) on update cascade on delete set null,
	revisado_en timestamptz null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

comment on table public.migracion_terminos_metricos is
	'Trazabilidad y revisión inicial de las entradas de estrofa_tipo. No forma parte del modelo editorial de las secuencias.';

create table public.migracion_termino_destinos (
	destino_id uuid primary key default gen_random_uuid(),
	termino_id uuid not null references public.migracion_terminos_metricos (termino_id)
		on update cascade on delete cascade,
	tipo_operacion text not null
		check (tipo_operacion in ('conservar', 'fusionar', 'transformar', 'retirar', 'revisar')),
	forma_id uuid null references public.formas_metricas (forma_id)
		on update cascade on delete cascade,
	familia_id uuid null references public.familias_metricas (familia_id)
		on update cascade on delete cascade,
	configuracion_id uuid null references public.configuraciones_forma (configuracion_id)
		on update cascade on delete cascade,
	patron_rima_id uuid null references public.patrones_rima (patron_rima_id)
		on update cascade on delete cascade,
	rasgo_id uuid null references public.rasgos_metricos (rasgo_id)
		on update cascade on delete cascade,
	valor_rasgo_id uuid null references public.rasgo_valores (valor_id)
		on update cascade on delete cascade,
	alias_id uuid null references public.forma_aliases (alias_id)
		on update cascade on delete cascade,
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	check (
		tipo_operacion = 'retirar'
		or num_nonnulls(
			forma_id,
			familia_id,
			configuracion_id,
			patron_rima_id,
			rasgo_id,
			valor_rasgo_id,
			alias_id
		) = 1
	)
);

create table public.catalogo_metrico_estado (
	id boolean primary key default true check (id),
	revision bigint not null default 1 check (revision > 0),
	actualizado_en timestamptz not null default now(),
	actualizado_por uuid null references public.editores (user_id)
		on update cascade on delete set null
);

insert into public.catalogo_metrico_estado (id)
values (true);

create or replace function public.marcar_configuracion_metrica_principal(
	p_configuracion_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_forma_id uuid;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden modificar el catálogo métrico'
			using errcode = '42501';
	end if;

	select forma_id
	into v_forma_id
	from public.configuraciones_forma
	where configuracion_id = p_configuracion_id
	for update;

	if v_forma_id is null then
		raise exception 'Configuración métrica no encontrada'
			using errcode = 'P0002';
	end if;

	update public.configuraciones_forma
	set principal = configuracion_id = p_configuracion_id
	where forma_id = v_forma_id
		and activo;
end;
$$;

revoke all on function public.marcar_configuracion_metrica_principal(uuid) from public;
grant execute on function public.marcar_configuracion_metrica_principal(uuid) to authenticated;

create or replace function public.guardar_revision_migracion_metrica(
	p_cambios jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
	v_cambio record;
	v_total integer := 0;
	v_afectadas integer;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden revisar el catálogo métrico'
			using errcode = '42501';
	end if;

	if jsonb_typeof(p_cambios) <> 'array' then
		raise exception 'p_cambios debe ser un array JSON';
	end if;

	for v_cambio in
		select *
		from jsonb_to_recordset(p_cambios) as x(
			termino_id uuid,
			clasificacion_decidida text,
			estado_revision text,
			notas_ip text
		)
	loop
		if v_cambio.clasificacion_decidida is null
			or v_cambio.clasificacion_decidida not in ('F', 'G', 'C', 'P', 'R', 'A', 'E', 'D', '?')
		then
			raise exception 'Clasificación métrica no válida';
		end if;
		if v_cambio.estado_revision is null
			or v_cambio.estado_revision not in ('pendiente', 'revisada')
		then
			raise exception 'Estado de revisión métrica no válido';
		end if;

		update public.migracion_terminos_metricos
		set
			clasificacion_decidida = v_cambio.clasificacion_decidida,
			estado_revision = v_cambio.estado_revision,
			notas_ip = nullif(btrim(v_cambio.notas_ip), ''),
			revisado_por = case
				when v_cambio.estado_revision = 'revisada' then auth.uid()
				else null
			end,
			revisado_en = case
				when v_cambio.estado_revision = 'revisada' then now()
				else null
			end
		where termino_id = v_cambio.termino_id;

		get diagnostics v_afectadas = row_count;
		if v_afectadas <> 1 then
			raise exception 'Término métrico de origen no encontrado: %', v_cambio.termino_id;
		end if;
		v_total := v_total + 1;
	end loop;

	return v_total;
end;
$$;

revoke all on function public.guardar_revision_migracion_metrica(jsonb) from public;
grant execute on function public.guardar_revision_migracion_metrica(jsonb) to authenticated;

create or replace function public.marcar_catalogo_metrico_actualizado()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
	update public.catalogo_metrico_estado
	set
		revision = revision + 1,
		actualizado_en = now(),
		actualizado_por = auth.uid()
	where id;
	return null;
end;
$$;

create index configuraciones_forma_forma_idx on public.configuraciones_forma (forma_id);
create index patrones_metricos_configuracion_idx on public.patrones_metricos (configuracion_id);
create index patrones_rima_configuracion_idx on public.patrones_rima (configuracion_id);
create index migracion_terminos_metricos_estado_idx
	on public.migracion_terminos_metricos (estado_revision, requiere_revision);

do $$
declare
	v_table text;
begin
	foreach v_table in array array[
		'formas_metricas',
		'familias_metricas',
		'familias_formas',
		'tradiciones_metricas',
		'formas_tradiciones',
		'forma_aliases',
		'forma_relaciones',
		'configuraciones_forma',
		'modelos_verso',
		'modelo_verso_segmentos',
		'patrones_metricos',
		'patron_metrico_posiciones',
		'patron_metrico_opciones',
		'patrones_rima',
		'patron_rima_posiciones',
		'patron_rima_enlaces',
		'patron_rima_restricciones',
		'estructuras_secciones',
		'patrones_repeticion',
		'patron_repeticion_posiciones',
		'rasgos_metricos',
		'rasgo_valores',
		'configuracion_rasgos',
		'fuentes_metricas',
		'afirmaciones_fuentes_metricas',
		'migracion_terminos_metricos',
		'migracion_termino_destinos',
		'catalogo_metrico_estado'
	]
	loop
		execute format('alter table public.%I enable row level security', v_table);
		execute format(
			'create policy %I on public.%I for all to authenticated using (public.auth_is_admin_or_ip()) with check (public.auth_is_admin_or_ip())',
			v_table || '_admin_ip',
			v_table
		);
		execute format(
			'grant select, insert, update, delete on table public.%I to authenticated',
			v_table
		);
	end loop;
end;
$$;

do $$
declare
	v_table text;
begin
	foreach v_table in array array[
		'formas_metricas',
		'familias_metricas',
		'familias_formas',
		'tradiciones_metricas',
		'formas_tradiciones',
		'forma_aliases',
		'forma_relaciones',
		'configuraciones_forma',
		'modelos_verso',
		'modelo_verso_segmentos',
		'patrones_metricos',
		'patron_metrico_posiciones',
		'patron_metrico_opciones',
		'patrones_rima',
		'patron_rima_posiciones',
		'patron_rima_enlaces',
		'patron_rima_restricciones',
		'estructuras_secciones',
		'patrones_repeticion',
		'patron_repeticion_posiciones',
		'rasgos_metricos',
		'rasgo_valores',
		'configuracion_rasgos',
		'fuentes_metricas',
		'afirmaciones_fuentes_metricas',
		'migracion_terminos_metricos',
		'migracion_termino_destinos'
	]
	loop
		execute format(
			'create trigger %I before update on public.%I for each row execute function public.actualizar_updated_at()',
			'trigger_' || v_table || '_updated_at',
			v_table
		);
	end loop;
end;
$$;

do $$
declare
	v_table text;
begin
	foreach v_table in array array[
		'formas_metricas',
		'familias_metricas',
		'familias_formas',
		'tradiciones_metricas',
		'formas_tradiciones',
		'forma_aliases',
		'forma_relaciones',
		'configuraciones_forma',
		'modelos_verso',
		'modelo_verso_segmentos',
		'patrones_metricos',
		'patron_metrico_posiciones',
		'patron_metrico_opciones',
		'patrones_rima',
		'patron_rima_posiciones',
		'patron_rima_enlaces',
		'patron_rima_restricciones',
		'estructuras_secciones',
		'patrones_repeticion',
		'patron_repeticion_posiciones',
		'rasgos_metricos',
		'rasgo_valores',
		'configuracion_rasgos'
	]
	loop
		execute format(
			'create trigger %I after insert or update or delete on public.%I for each statement execute function public.marcar_catalogo_metrico_actualizado()',
			'trigger_' || v_table || '_catalogo_revision',
			v_table
		);
	end loop;
end;
$$;

commit;
