-- Las dos arquitecturas del terceto encadenado dicen que su rima es consonante.
--
-- `endecasilabico_consonante` ya lo decía; `octosilabico` callaba lo mismo que la otra
-- declara, y en una lista de arquitecturas eso se lee como si fueran cosas distintas.
--
-- El slug cambia aquí y no desde el panel: es la clave que usan el código y las
-- migraciones, así que su renombrado es un acto deliberado y no un efecto de editar el
-- nombre. Ninguna línea de código se ramifica sobre slugs de arquitectura, y ninguna
-- migración anterior apunta a `octosilabico` dentro del terceto encadenado salvo
-- `20260731320000_terceto_encadenado_octosilabico.sql`, que ya está aplicada y no se toca.

update public.arquitecturas_forma a
set slug = 'octosilabico_consonante',
	nombre = 'Terceto encadenado octosilábico consonante',
	updated_at = now()
from public.formas_metricas f
where f.forma_id = a.forma_id
	and f.slug = 'terceto_encadenado'
	and a.slug = 'octosilabico';

-- Una migración que apunta a una fila del catálogo por su slug tiene que comprobar que la
-- encontró. Si no, un renombrado anterior la deja sin efecto y se aplica en silencio.
do $$
declare
	v_total integer;
begin
	select count(*) into v_total
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'terceto_encadenado'
		and a.slug in ('octosilabico_consonante', 'endecasilabico_consonante');

	if v_total <> 2 then
		raise exception
			'El terceto encadenado debería tener sus dos arquitecturas consonantes y tiene %', v_total;
	end if;
end;
$$;
