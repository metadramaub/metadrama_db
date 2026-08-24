-- El eslabón separa la canción de la alirada
--
-- Decisión del IP el 24 de agosto de 2026, y **la prosa del catálogo no la decía bien**. Tres
-- definiciones —la canción petrarquista, el cuarteto-lira y la octava-lira— sostenían que lo que
-- separa una estrofa alirada de una estancia es que la alirada «prescinde de la ordenación en
-- fronte y sirima». Eso es cierto de lejos y **no distingue nada de cerca**.
--
-- El caso que lo prueba es el patrón `aBaBcDcDeE`, que la edición crítica de *Elisa Dido* llama
-- «décima-estancia». Si la prueba es la ordenación en fronte y sirima, ese esquema la pasa:
--
-- | | |
-- |---|---|
-- | `aB` + `aB` | dos piedi idénticos → hay fronte |
-- | `cDcDeE` | rimas nuevas → hay sirima |
--
-- Y sin embargo el IP lo considera forzado. Lo único que le falta frente al modelo petrarquista es
-- **la chiave**, el verso que abre la sirima repitiendo la rima con que se cerró la fronte —lo que
-- el catálogo llama eslabón—. De modo que es el eslabón lo que estaba decidiendo, y así queda:
--
-- > Es **canción** si la fronte se parte en dos piedi idénticos **y** la sirima empieza con
-- > eslabón. Es **estrofa alirada** en cualquier otro caso.
--
-- **El eslabón sigue siendo estructuralmente opcional**, porque en la tradición italiana la chiave
-- lo es: una canción sin ella no deja de ser una canción. Lo que la decisión fija es **cómo se
-- nombra** lo que no la tiene, que preferentemente será alirado. Los dos planos no se confunden: la
-- estructura admite el caso raro, la nomenclatura elige por defecto.
--
-- Y por eso el criterio es reversible: cuando la anotación registre por separado el esquema
-- observado, si la cabeza se repite y si hay eslabón —que llega con B1—, una estancia larga sin
-- chiave se encontrará con una consulta y se reclasificará sin rehacer nada.
--
-- Esta migración solo cambia prosa. No toca ninguna estructura.

begin;

do $$
declare
	v_n integer;
	v_actual text;

	c_cancion constant text :=
		'Composición en estancias: una estrofa larga de heptasílabos y endecasílabos que el poeta '
		|| 'inventa para cada canción y que, fijada por la primera, vuelve idéntica hasta el final. '
		|| 'La estancia se ordena en dos partes: la fronte, partida a su vez en dos piedi de igual '
		|| 'medida y disposición, y la sirima, de rimas nuevas, que suele abrirse con un verso '
		|| '—el eslabón o chiave— que repite la rima con que se cerró la fronte. Cierra un fragmento '
		|| 'de estancia más breve —el remate, envío o commiato— en el que el poeta suele dirigirse a '
		|| 'la propia canción. Esa ordenación es lo que la separa de las estrofas aliradas, que '
		|| 'tienen su misma materia: cuando una estrofa de siete y once repite la cabeza pero no '
		|| 'trae eslabón, la tradición y este catálogo la llaman alirada y no canción. «Canción» a '
		|| 'secas designa esta forma italiana, no la medieval del siglo XV.';

	c_cuarteto constant text :=
		'Estrofa de cuatro versos que mezcla endecasílabos y heptasílabos en proporción variable y '
		|| 'rima en consonante, cruzada —el primero con el tercero y el segundo con el cuarto— o '
		|| 'abrazada —el primero con el cuarto y el segundo con el tercero—. Es la menor de las '
		|| 'estrofas aliradas: tiene la materia de la canción italiana, siete y once consonantes '
		|| 'repetidos sin cambio de una estrofa a otra, y le falta su ordenación. En una estrofa tan '
		|| 'breve la diferencia no llega a plantearse, porque no hay sitio para una fronte partida '
		|| 'en dos piedi y una sirima con eslabón. La tradición registra también realizaciones con '
		|| 'rima asonante o con algún verso suelto.';

	c_octava constant text :=
		'Estrofa de ocho versos que mezcla endecasílabos y heptasílabos y reparte cuatro rimas '
		|| 'consonantes en disposiciones variables, con una condición que no falla: los dos últimos '
		|| 'versos forman pareado. Es la mayor de las estrofas aliradas y la que más fácilmente se '
		|| 'confunde con una estancia de canción, porque tiene su misma materia y porque algunas de '
		|| 'sus disposiciones repiten la cabeza como lo haría una fronte. Lo que decide es el '
		|| 'eslabón: si el verso que abre la segunda mitad retoma la rima con que se cerró la '
		|| 'primera, el pasaje se ordena como una estancia y es canción; si no lo retoma, el pasaje '
		|| 'repite ocho versos iguales y es octava-lira.';
begin
	-- Las tres definiciones son las que había, no otras: si alguien las ha reescrito, esto para.
	select definicion into v_actual from public.formas_metricas where slug = 'cancion_petrarquista';
	if v_actual is null or v_actual not like '%no la medieval del siglo XV.' then
		raise exception 'La definición de la canción no es la esperada. Acaba: %', right(v_actual, 40);
	end if;

	select count(*) into v_n from public.formas_metricas
	where slug in ('cuarteto_lira', 'octava_lira') and definicion like '%ordenación%';
	if v_n <> 2 then
		raise exception 'Solo % de las dos aliradas dice lo de la ordenación.', v_n;
	end if;

	update public.formas_metricas set definicion = c_cancion where slug = 'cancion_petrarquista';
	update public.formas_metricas set definicion = c_cuarteto where slug = 'cuarteto_lira';
	update public.formas_metricas set definicion = c_octava where slug = 'octava_lira';

	-- ------------------------------------------------------------------ Comprobaciones
	-- Las tres nombran ya el eslabón, que es lo que decide.
	select count(*) into v_n from public.formas_metricas
	where slug in ('cancion_petrarquista', 'cuarteto_lira', 'octava_lira')
		and definicion ilike '%eslabón%';
	if v_n <> 3 then
		raise exception 'Solo % de las tres definiciones nombra el eslabón.', v_n;
	end if;

	-- Y ninguna se ha quedado corta al reescribirla: la prosa del catálogo mejora alargando.
	select count(*) into v_n from public.formas_metricas
	where slug in ('cancion_petrarquista', 'cuarteto_lira', 'octava_lira')
		and length(definicion) < 400;
	if v_n <> 0 then
		raise exception '% definiciones han quedado más cortas de lo que pedía el cambio.', v_n;
	end if;

	-- El eslabón de la canción regular sigue donde estaba: esto era prosa, no estructura.
	if not exists (
		select 1 from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'cancion_petrarquista' and a.slug = 'regular_13_versos'
			and s.slug = 'eslabon'
	) then
		raise exception 'La canción regular ha perdido su eslabón.';
	end if;

	if public.get_forma_metrica_publica('cancion_petrarquista') -> 'formas' = '[]'::jsonb
		or public.get_forma_metrica_publica('octava_lira') -> 'formas' = '[]'::jsonb
		or public.get_forma_metrica_publica('cuarteto_lira') -> 'formas' = '[]'::jsonb then
		raise exception 'Alguna de las tres fichas ha dejado de responder.';
	end if;
end $$;

commit;
