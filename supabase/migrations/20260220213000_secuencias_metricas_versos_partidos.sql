alter table public.secuencias_metricas
	add column if not exists versos_partidos boolean not null default false;
