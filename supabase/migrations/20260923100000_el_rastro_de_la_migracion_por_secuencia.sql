-- El rastro de la migración, secuencia a secuencia
--
-- **Una asignación legada tiene que poder seguirse hasta su anotación nueva.** Es el criterio de
-- aceptación 3 del plan, y hoy no se cumple: `origen_termino_id` dice de qué término del
-- vocabulario viejo nace cada entidad del catálogo, pero nada dice qué le pasó a *esta* secuencia
-- de *esta* obra el día que se migró. Las tablas que iban a decirlo, `migracion_terminos_metricos`
-- y `migracion_termino_destinos`, se retiraron en julio de 2026 porque describían el mapa, no el
-- trabajo.
--
-- Esta tabla la escribe `npm run migracion:aplicar`, una fila por secuencia migrada, y guarda lo
-- que no se puede reconstruir después:
--
--   · el término legado que tenía, que sigue en `secuencias_metricas.estrofa_tipo_id` pero puede
--     dejar de estar el día que esa columna se retire (plan, §7);
--   · la anotación nueva que se escribió, y de qué obra es;
--   · lo que respondió el editor, tal cual se leyó del Excel, porque **el Excel devuelto es el
--     documento y esto es su lectura**: si una migración sale mal, lo que hay que poder comparar es
--     lo que se entendió con lo que se contestó;
--   · las correcciones que se aplicaron de camino —una renumeración por laguna, un rango corregido,
--     una fusión de tramos—, que modifican las tablas legadas y no dejan otra huella.
--
-- Una secuencia se migra una vez: si se repite —porque el editor corrige su Excel— la fila se
-- reescribe, y por eso la clave es la secuencia y no una fila suelta más.
--
-- Es un registro interno del trabajo, no un dato del corpus: lo leen admin y el IP, y nada de la
-- zona pública lo consulta.

begin;

create table if not exists public.migracion_secuencias (
	secuencia_id uuid primary key references public.secuencias_metricas (secuencia_id)
		on update cascade on delete cascade,
	obra_id uuid not null references public.obras (obra_id)
		on update cascade on delete cascade,
	anotacion_id uuid null references public.anotaciones_metricas (anotacion_id)
		on update cascade on delete set null,
	termino_legado text null,
	origen_termino_id uuid null references public.vocabularios (termino_id)
		on update cascade on delete set null,
	-- Lo que se hizo con la secuencia: se anotó tal cual, absorbió a sus contiguas al fundirse, o
	-- se dejó para más tarde porque su respuesta no se podía aplicar. **La absorbida no tiene fila
	-- propia**: su secuencia deja de existir y se llevaría la fila por delante, así que lo que era
	-- —su rango y su término— queda escrito en las correcciones de la que la absorbió.
	resultado text not null
		check (resultado in ('anotada', 'fundida', 'pendiente')),
	-- Las respuestas del Excel que tocaban a esta secuencia, por su clave, y las correcciones
	-- aplicadas. Es el rastro de la lectura, no un dato consultable: se guarda como llegó.
	respuestas jsonb not null default '{}'::jsonb,
	correcciones jsonb not null default '[]'::jsonb,
	notas text null,
	migrada_en timestamptz not null default now(),
	migrada_por uuid null references public.editores (user_id)
		on update cascade on delete set null
);

comment on table public.migracion_secuencias is
	'Rastro de la migración de las secuencias anotadas con el vocabulario legado al catálogo nuevo: qué término tenía cada una, qué anotación se le escribió, qué respondió su editor y qué se corrigió de camino. Lo escribe npm run migracion:aplicar.';

create index if not exists migracion_secuencias_obra_idx
	on public.migracion_secuencias (obra_id);

alter table public.migracion_secuencias enable row level security;

drop policy if exists migracion_secuencias_lectura on public.migracion_secuencias;
create policy migracion_secuencias_lectura
	on public.migracion_secuencias
	for select
	to authenticated
	using (public.auth_is_admin_or_ip());

drop policy if exists migracion_secuencias_escritura on public.migracion_secuencias;
create policy migracion_secuencias_escritura
	on public.migracion_secuencias
	for all
	to authenticated
	using (public.auth_is_admin_or_ip())
	with check (public.auth_is_admin_or_ip());

commit;
