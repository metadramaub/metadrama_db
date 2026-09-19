-- El dístico final no cuenta para la densidad de rima
--
-- Al revisar *Adonis y Venus* apareció un endecasílabo suelto anotado con «densidad de rima:
-- ninguna» y «dístico final: presente», y la nota del rasgo decía «cuando la rima desaparece del
-- todo, la serie se llama verso blanco»: leída al pie de la letra, un pasaje con dístico no podía
-- ser «ninguna». David aclara el criterio el 18 de septiembre de 2026: el dístico final no cuenta
-- para la densidad —es el cierre, no la serie—, de modo que «ninguna» con dístico es exactamente el
-- suelto puro con dístico del vocabulario legado. Lo que no puede ser es «ninguna» con pareados
-- intercalados: eso ya es rima en la serie, y el editor lo impide.

begin;

do $$
declare
	v_rasgo uuid;
	v_n integer;
begin
	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'densidad_de_rima';
	if v_rasgo is null then raise exception 'No está el rasgo de densidad de rima.'; end if;

	update public.rasgo_valores
	set descripcion = 'Ningún verso de la serie rima con otro; el dístico final, si lo hay, no cuenta. Es el verso blanco de Jauralde, la desaparición sistemática de la rima.'
	where rasgo_id = v_rasgo and slug = 'ninguna';
	get diagnostics v_n = row_count;
	if v_n <> 1 then raise exception 'No se encontró el valor «ninguna».'; end if;

	update public.rasgo_valores
	set descripcion = 'Rima menos de la mitad de los versos de la serie, sin contar el dístico final. Morley y Bruerton cuentan un pasaje como suelto por debajo de ese umbral.'
	where rasgo_id = v_rasgo and slug = 'esporadica';

	update public.arquitectura_rasgos ar
	set nota = 'Cuando la rima desaparece del todo, la serie se llama verso blanco. El dístico final no cuenta: un pasaje sin más rima que su cierre en dístico es de densidad ninguna.'
	from public.rasgo_valores v
	where ar.rasgo_id = v_rasgo and ar.valor_id = v.valor_id and v.slug = 'ninguna'
		and ar.nota like 'Cuando la rima desaparece del todo%';
	get diagnostics v_n = row_count;
	if v_n < 1 then raise exception 'No se encontró la nota del suelto para «ninguna».'; end if;

	update public.grupos_eleccion_metrica
	set ayuda_editor = 'Cuenta los versos que riman en la serie, sin el dístico final. Si rima más de la mitad, el pasaje deja de ser endecasílabo suelto y se registra como silva.'
	where rasgo_id = v_rasgo and ayuda_editor like 'Si rima más de la mitad de los versos%';
	get diagnostics v_n = row_count;
	if v_n < 1 then raise exception 'No se encontró la ayuda de la pregunta de densidad.'; end if;

	perform public.get_forma_metrica_publica_jerarquica('endecasilabo_suelto');
end $$;

commit;
