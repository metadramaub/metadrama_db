-- La caja de la rima cuando la arquitectura no fija la medida verso a verso.
--
-- La comprobación anterior solo alcanzaba a las arquitecturas que declaran una medida por
-- posición. Las que declaran un **conjunto** de medidas admisibles quedaban fuera, y ahí
-- había dos notaciones que afirmaban un arte que la medida no sostiene.
--
-- La regla que faltaba escribir: **la caja dice el arte**. Si todas las medidas admisibles
-- comparten arte, se usa el suyo. Si lo cruzan, el arte no está determinado y se escribe en
-- minúscula, que es la forma no marcada. No es una invención: el pareado ya lo hace así, con
-- medidas de cuatro a catorce sílabas y notación `aa`.
--
-- 1 · **Zéjel**, hexasílabo u octosílabo: **arte menor**, y escribía `A(A) | [BBBA]…`.
--     Las clases de rima siguen siendo dos y distintas; solo baja la caja.
--
-- 2 · **Canción petrarquista**, pareado final de la modalidad sin rima. Escribía `AA` sobre
--     una arquitectura de siete y once sílabas, así que afirmaba dos endecasílabos sin que
--     nada lo sostuviera. La definición del proyecto dice «un pareado final de rima
--     consonante que sirve para cerrar cada unidad», sin fijar medida, y Morley y Bruerton
--     tampoco la fijan: «versos de siete y once sílabas, agrupados en estrofas sin rima,
--     excepto un pareado final». Y el pareado final de la canción regular es `fF`, siete más
--     once, así que el `AA` venía de llamarlos «pareados consonantes» y no de la medida.
--     Queda `aa`: riman, y la medida se declara aparte.

begin;

do $$
declare
	v_mal integer;
begin
	update public.esquemas_rima set notacion = 'a(a) | [bbba]…'
	where notacion = 'A(A) | [BBBA]…';

	update public.esquemas_rima er
	set notacion = 'aa'
	where er.notacion = 'AA'
		and er.arquitectura_id in (
			select a.arquitectura_id from public.arquitecturas_forma a
			join public.formas_metricas f on f.forma_id = a.forma_id
			where f.slug = 'cancion_petrarquista'
		);

	-- Comprobación: en una arquitectura cuya medida es un conjunto, la caja de la notación
	-- no puede afirmar un arte que las medidas admisibles no sostengan.
	with artes as (
		select
			em.arquitectura_id,
			min(m.silabas) as minima,
			max(m.silabas) as maxima
		from public.esquemas_metricos em
		join public.esquema_metrico_opciones o on o.esquema_metrico_id = em.esquema_metrico_id
		join public.metros m on m.metro_id = o.metro_id
		where em.tipo_secuencia = 'conjunto'
		group by em.arquitectura_id
	),
	simbolos as (
		select er.arquitectura_id, s.simbolo
		from public.esquemas_rima er
		cross join lateral (
			select m[1] as simbolo
			from regexp_matches(er.notacion, '([A-Za-z])', 'g') as t(m)
		) s
		where er.notacion is not null
	)
	select count(*) into v_mal
	from simbolos s
	join artes a on a.arquitectura_id = s.arquitectura_id
	where
		-- Arte menor en todas sus medidas: la mayúscula miente.
		(a.maxima <= 8 and s.simbolo = upper(s.simbolo))
		-- Arte mayor en todas: la minúscula miente.
		or (a.minima >= 9 and s.simbolo = lower(s.simbolo))
		-- Cruzan el límite: el arte no está determinado y la mayúscula afirma de más.
		or (a.minima <= 8 and a.maxima >= 9 and s.simbolo = upper(s.simbolo));

	if v_mal > 0 then
		raise exception 'Quedan % símbolos con una caja que la medida admisible no sostiene', v_mal;
	end if;
end $$;

comment on column public.esquemas_rima.notacion is
	'Notación normalizada: minúscula arte menor, mayúscula arte mayor, «-» verso suelto, «( )» opcional, «:» pausa dentro de un bloque, «|» frontera de bloque, «[ ]…» bloque que se repite. Cada posición aparece una sola vez: la repetición se marca, no se escribe. Dentro de un bloque repetido, cada clase de rima **avanza** en cada repetición salvo que un enlace de `esquema_rima_enlaces` declare lo contrario: por eso `[aA]…` es aA bB cC y `[-a]…` mantiene una sola asonancia. Cuando la arquitectura no fija la medida verso a verso, la caja sigue el arte de las medidas admisibles; si estas cruzan el límite del arte mayor, el arte no está determinado y se escribe en minúscula, que es la forma no marcada.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
