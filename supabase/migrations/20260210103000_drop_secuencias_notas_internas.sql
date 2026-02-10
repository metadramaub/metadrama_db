-- Iteracion dashboard: eliminar campo legacy de notas internas por secuencia.
-- El contenido se centralizara en comentarios internos tipados.
alter table public.secuencias_metricas
drop column if exists notas_internas;
