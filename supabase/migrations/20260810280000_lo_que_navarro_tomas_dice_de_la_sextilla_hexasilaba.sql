-- Lo que Navarro Tomás dice de la sextilla hexasílaba, y que el catálogo no registraba.
--
-- Al revisar los esquemas abiertos que no declaran nada aparecieron cinco, y se fue a la
-- bibliografía a comprobar si estaban mudos porque no hay norma o porque no se buscó. Tres lo
-- están con razón: el sexteto dodecasílabo, del que ninguna fuente dice nada de su rima; el
-- endecasílabo, que ya tiene su esquema concreto y cuyo abierto significa «se admiten otras»; y
-- la sextilla heptasílaba, a la que Jauralde dedica epígrafe pero solo con ejemplos escandidos.
--
-- La **hexasílaba no**. Navarro Tomás le documenta tres disposiciones que aquí no constaban, y
-- eso es lo que se registra: **como afirmación de fuente, no como esquemas del catálogo**. La
-- decisión de admitirlas o no es del IP, y queda planteada en las cuestiones.
--
-- El criterio para no registrarlas es el mismo que se aplicó al romance heroico: lo documentado
-- cae fuera del teatro áureo —Juan Ruiz es del XIV, Álvaro de Luna del XV y Lobo del XVIII— y
-- declarar una disposición porque exista en la tradición, sin que el corpus la pida, sería
-- inventar norma. Lo que sí corresponde es dejar dicho lo que la fuente dice.

begin;

insert into public.afirmaciones_fuentes_metricas
	(fuente_id, arquitectura_id, localizador, resumen, confianza, estado_revision)
select fu.fuente_id, a.arquitectura_id,
	'§ 30, § 245 y glosario, s. v. «Lay»',
	'Documenta para la sextilla hexasílaba tres disposiciones concretas: de rimas alternas, en las cantigas de ciegos y de loores de Juan Ruiz; aguda «aaé:bbé», en el Diálogo de París y Elena de Eugenio Gerardo Lobo; y el lay, que define como breve canción amorosa de origen francoprovenzal en sextillas hexasílabas con insistentes rimas agudas, con el ejemplo «ááá:ááé» de don Álvaro de Luna.',
	'alta', 'revisada'
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.fuentes_metricas fu
	on fu.autoria = 'Tomás Navarro Tomás' and fu.anio = 1972
where f.slug = 'sextilla' and a.slug = 'hexasilabica'
	and not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		where af.arquitectura_id = a.arquitectura_id and af.fuente_id = fu.fuente_id
	);

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas af
	join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sextilla' and a.slug = 'hexasilabica';
	if v_n <> 1 then
		raise exception 'La sextilla hexasílaba tiene % afirmaciones en vez de 1', v_n;
	end if;

	-- Y no se ha registrado ninguna disposición nueva: la decisión es del IP.
	select count(*) into v_n
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sextilla' and a.slug = 'hexasilabica';
	if v_n <> 1 then
		raise exception 'La sextilla hexasílaba tiene ya % esquemas: solo debía tener el abierto', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;
