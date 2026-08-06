-- Un nombre es un nombre: se retira la clasificación de las denominaciones.
--
-- `tipo_alias` admitía cinco valores y **solo se usaban dos**: 30 `equivalente` y 5
-- `historico`. `variante_grafica`, `abreviatura` y `posterior` llevaban desde el principio a
-- cero, y el último se vació ayer al reasignar «Cuarteta». El vocabulario legado, por su
-- parte, guarda sus equivalencias como una simple lista de nombres, sin tipo: la migración
-- tampoco los necesita.
--
-- Cinco categorías para dos usos reales no clasifican, obligan a decidir. Y la decisión no
-- era fácil ni estable: «Quintilla de Fray Luis de León» estuvo marcada como histórica hasta
-- que se vio que Morley y Bruerton son de 1968.
--
-- **Lo que se pierde no se pierde.** Los cinco `historico` decían «este nombre es de otra
-- época», que es justo lo que una afirmación de fuente cuenta entero y con su referencia:
--
--   · «Redondilla de diez versos» → ya lo dice Navarro Tomás, § 185: es el nombre que Espinel
--     dio a la estrofa.
--   · «Estrofa de fray Luis de León» → ya lo dice Domínguez Caparrós 2014, p. 196.
--   · «Octava real regular», «Irregular» y «Verso suelto» vienen del vocabulario retirado y no
--     tienen matiz que contar: son sencillamente otros nombres.
--
-- Una etiqueta de una palabra no puede decir *por qué* un nombre es de otra época; una
-- afirmación sí, y además dice quién lo documenta. La ficha deja de imprimir «· equivalente»
-- junto a treinta nombres, que era ruido sin información.

begin;

do $$
declare
	v_sin_respaldo integer;
begin
	-- Antes de retirar el matiz, comprobar que los dos que lo merecían están contados.
	select count(*) into v_sin_respaldo
	from (values
		('%redondilla de diez versos%'),
		('%estrofa de fray Luis de León%')
	) as necesarias(patron)
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas af
		where af.resumen ilike necesarias.patron
	);

	if v_sin_respaldo > 0 then
		raise exception 'Faltan % denominaciones históricas por contar en una afirmación', v_sin_respaldo;
	end if;
end $$;

alter table public.denominaciones_metricas
	drop constraint if exists denominaciones_metricas_tipo_alias_check;

alter table public.denominaciones_metricas
	drop column if exists tipo_alias;

comment on table public.denominaciones_metricas is
	'Los otros nombres de una forma, una arquitectura, un esquema o una variedad. Todos valen igual: un nombre es un nombre. Si alguno tiene historia —quién lo acuñó, en qué época, por qué se dejó de usar—, eso se cuenta en una afirmación de fuente, que puede decirlo entero y con su referencia, y no en una etiqueta de una palabra.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
