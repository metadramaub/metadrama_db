begin;

alter table public.secuencias_metricas
	add column final_acentual character varying(32) not null default 'normal';

alter table public.secuencias_metricas
	add constraint secuencias_metricas_final_acentual_chk
	check (final_acentual in ('normal', 'mayoria_agudas', 'mayoria_esdrujulas'));

comment on column public.secuencias_metricas.final_acentual is
	'Caracterizacion global de los finales de verso de la secuencia (normal, mayoria_agudas, mayoria_esdrujulas).';

commit;
