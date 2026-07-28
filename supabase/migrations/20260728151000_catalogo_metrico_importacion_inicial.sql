begin;

-- Clasificación inicial procedente de la matriz de reclasificación. Todas las
-- decisiones quedan pendientes de revisión humana aunque algunas no requieran
-- atención prioritaria.
with propuestas(slug, clasificacion, propuesta, certeza, requiere_revision) as (
	values
		('cancion_petrarquista', 'F', 'Conservar como forma compuesta; formalizar estancias y alternativas.', 'alta', true),
		('cancion_de_15_versos', 'C', 'Configuración de estancia de 15 versos.', 'alta', false),
		('cancion_de_8_versos', 'C', 'Configuración de estancia de 8 versos.', 'alta', false),
		('cancion_de_9_versos', 'C', 'Configuración de estancia de 9 versos.', 'alta', false),
		('cancion_endecasilaba', 'C', 'Configuración isométrica endecasílaba; revisar si está lexicalizada como subtipo.', 'media', true),
		('cancion_regular_abCabCcdeeDfF', 'P', 'Patrón de rima y metro admitido por una configuración regular.', 'alta', false),
		('cancion_sin_rima', '?', 'Decidir entre forma `cancion_libre` documentada o configuración sin rima.', 'baja', true),
		('cancion_sin_rima_de_esdrujulos', 'R', 'Forma de destino de `cancion_sin_rima` más rasgo esdrújulo.', 'alta', true),
		('copla_de_arte_mayor', 'F', 'Conservar como forma canónica. Corregir y formalizar el metro dodecasílabo.', 'alta', true),
		('copla_de_arte_mayor_tipo_1_ABBAACCA', 'P', 'Patrón de rima admitido `ABBAACCA`.', 'alta', false),
		('copla_de_arte_mayor_tipo_2_ABBACDCD', 'P', 'Patrón de rima admitido `ABBACDCD`.', 'alta', false),
		('copla_de_arte_mayor_tipo_3_ABABCDCD', 'P', 'Patrón de rima admitido `ABABCDCD`.', 'alta', false),
		('copla_de_pie_quebrado', 'G', 'Familia de formas con pie quebrado; no usar como residual ni como equivalente de sextilla.', 'media', true),
		('copla_real', 'F', 'Conservar como forma canónica de diez versos y pausa 5 + 5.', 'alta', true),
		('copla_real_de_pie_quebrado', 'C', 'Configuración con patrón métrico ordenado que incluya quebrados.', 'alta', true),
		('copla_real_sin_quebrado', 'C', 'Configuración isométrica octosílaba; puede ser la configuración principal sin nombre público.', 'alta', false),
		('decima', '?', 'Decidir si será familia `decimas` o alias contextual de `decima_espinela`; el registro actual ya describe una espinela.', 'baja', true),
		('decima_aumentada', 'F', 'Candidata a forma canónica de doce versos, condicionada a fuente y uso en corpus.', 'media', true),
		('decima_espinela', 'F', 'Conservar como forma canónica con patrón `abbaaccddc`.', 'alta', false),
		('doble_sextilla', 'F', 'Conservar como forma de doce versos; tipar su relación con la familia de pie quebrado.', 'media', true),
		('copla_manriqueña', 'F', 'Conservar como forma lexicalizada y relacionarla como subtipo de doble sextilla.', 'alta', false),
		('doble_sextilla_alternativa', 'C', 'Configuración no manriqueña de doble sextilla; sustituir “alternativa” por descripción positiva.', 'alta', true),
		('endecasilabo_suelto', 'F', 'Conservar como serie métrica abierta.', 'alta', true),
		('endecasilabo_suelto_con_pareados', 'C', 'Configuración con pareados intercalados y dístico final.', 'alta', true),
		('endecasilabo_suelto_con_pareados_y_sin_distico_final', 'C', 'Configuración con pareados y sin dístico final.', 'alta', true),
		('endecasilabo_suelto_de_esdrujulos', 'R', 'Endecasílabo suelto más rasgo esdrújulo.', 'alta', false),
		('endecasilabo_suelto_encadenado', 'C', 'Configuración con rima interna encadenada; registrar además el rasgo correspondiente.', 'media', true),
		('endecasilabo_suelto_puro', 'C', 'Configuración sin pareados intercalados, con la política de cierre que se apruebe.', 'alta', true),
		('endecasilabo_suelto_puro_sin_distico_final', 'C', 'Configuración pura sin dístico final.', 'alta', true),
		('irregular', 'E', 'Mantener como salida “forma regular no identificada”.', 'alta', true),
		('irregular_arte_mayor', 'D', 'Retirar como forma; derivar arte mayor de los metros observados.', 'alta', false),
		('irregular_arte_menor', 'D', 'Retirar como forma; derivar arte menor de los metros observados.', 'alta', false),
		('irregular_mixto', 'D', 'Retirar como forma; derivar mezcla de los metros observados.', 'alta', false),
		('lira', 'F', 'Conservar como forma canónica con patrón métrico y de rima ordenado.', 'alta', false),
		('novena', 'F', 'Conservar como forma de nueve versos.', 'alta', true),
		('novena_canonica', 'C', 'Configuración redondilla + quintilla.', 'alta', false),
		('novena_invertida', 'C', 'Configuración quintilla + redondilla.', 'alta', false),
		('octava_real', 'F', 'Conservar como forma canónica.', 'alta', false),
		('octava_real_de_esdrujulos', 'R', 'Octava real más rasgo esdrújulo.', 'alta', false),
		('octava_real_regular', 'A', 'Fusionar con `octava_real`; el patrón `ABABABCC` será su configuración principal.', 'alta', false),
		('pareado_de_arte_menor', 'C', 'Configuración de la nueva forma `pareado` con metro de arte menor.', 'media', true),
		('pareado_hexasilabo', 'C', 'Configuración hexasílaba de `pareado`.', 'alta', false),
		('pareado_octosilabo', 'C', 'Configuración octosílaba de `pareado`.', 'alta', false),
		('pareado_endecasilabo', 'C', 'Configuración endecasílaba de `pareado`; completar definición.', 'alta', true),
		('quintilla', 'F', 'Conservar como forma canónica.', 'alta', false),
		('quintilla_1_ababa', 'P', 'Patrón admitido `ababa`.', 'alta', false),
		('quintilla_2_abbab', 'P', 'Patrón admitido `abbab`.', 'alta', false),
		('quintilla_3_abaab', 'P', 'Patrón admitido `abaab`.', 'alta', false),
		('quintilla_4_aabab', 'P', 'Patrón admitido `aabab`.', 'alta', false),
		('quintilla_5_aabba', 'P', 'Patrón admitido `aabba`; corregir tamaño 6 → 5 en origen.', 'alta', false),
		('quintilla_6_abbaa', 'P', 'Patrón admitido `abbaa`.', 'alta', false),
		('quintilla_7_ababb', 'P', 'Patrón admitido `ababb`; corregir tamaño 6 → 5 en origen.', 'alta', false),
		('quintilla_8_abbba', 'P', 'Patrón irregular documentado, no configuración canónica.', 'alta', true),
		('redondilla', 'F', 'Conservar como forma; definir de manera expresa su sentido moderno o histórico.', 'media', true),
		('redondilla_cruzada', '?', 'Crear `cuarteta` como forma canónica o conservarla como configuración histórica documentada de redondilla.', 'baja', true),
		('redondilla_doble_abbaacca', 'F', 'Candidata a forma canónica `redondilla_doble`, con relación a redondilla.', 'media', true),
		('redondilla_heptasilaba', 'C', 'Configuración heptasílaba de redondilla.', 'alta', false),
		('redondilla_hexasilaba', 'C', 'Configuración hexasílaba; corregir la relación métrica de origen a 6.', 'alta', false),
		('redondilla_regular', 'A', 'Fusionar con `redondilla` si se adopta `abba` octosílabo como definición canónica.', 'media', true),
		('romance', 'F', 'Conservar como forma canónica.', 'alta', false),
		('romance_a', 'R', 'Valor normalizado de `vocales_asonancia`: vocal tónica final `á`.', 'alta', true),
		('romance_a-a', 'R', 'Valor `a-a` de `vocales_asonancia`.', 'alta', false),
		('romance_a-e', 'R', 'Valor `a-e` de `vocales_asonancia`.', 'alta', false),
		('romance_a-o', 'R', 'Valor `a-o` de `vocales_asonancia`.', 'alta', false),
		('romance_e', 'R', 'Valor normalizado de `vocales_asonancia`: vocal final `e`.', 'alta', true),
		('romance_e-a', 'R', 'Valor `e-a` de `vocales_asonancia`.', 'alta', false),
		('romance_e-e', 'R', 'Valor `e-e` de `vocales_asonancia`.', 'alta', false),
		('romance_e-o', 'R', 'Valor `e-o` de `vocales_asonancia`.', 'alta', false),
		('romance_i', 'R', 'Valor normalizado de `vocales_asonancia`: vocal tónica final `í`.', 'alta', true),
		('romance_i-a', 'R', 'Valor `i-a` de `vocales_asonancia`.', 'alta', false),
		('romance_i-e', 'R', 'Valor `i-e` de `vocales_asonancia`.', 'alta', false),
		('romance_i-o', 'R', 'Valor `i-o` de `vocales_asonancia`.', 'alta', false),
		('romance_o', 'R', 'Valor normalizado de `vocales_asonancia`: vocal tónica final `ó`.', 'alta', true),
		('romance_o-a', 'R', 'Valor `o-a` de `vocales_asonancia`.', 'alta', false),
		('romance_o-e', 'R', 'Valor `o-e` de `vocales_asonancia`.', 'alta', false),
		('romance_o-o', 'R', 'Valor `o-o` de `vocales_asonancia`.', 'alta', false),
		('romance_u-a', 'R', 'Valor `u-a` de `vocales_asonancia`.', 'alta', false),
		('romance_u-e', 'R', 'Valor `u-e` de `vocales_asonancia`.', 'alta', false),
		('romance_u-o', 'R', 'Valor `u-o` de `vocales_asonancia`.', 'alta', false),
		('romance_heroico', 'F', 'Conservar como forma lexicalizada y relacionarla con romance.', 'alta', false),
		('romancillo', 'F', 'Conservar como forma canónica de serie asonantada de arte menor.', 'alta', true),
		('romancillo_heptasilabo', 'C', 'Configuración heptasílaba.', 'alta', true),
		('romancillo_hexasilabo', 'C', 'Configuración hexasílaba.', 'alta', true),
		('seguidilla', 'F', 'Conservar y crear configuraciones simple y compuesta; el tamaño no puede quedar fijado solo en 4.', 'alta', true),
		('sexta_rima', 'F', 'Conservar como forma canónica; sustituir la bibliografía `****`.', 'alta', false),
		('sexteto', 'F', 'Conservar como forma abierta de seis versos de arte mayor.', 'alta', true),
		('sexteto_lira', 'F', 'Conservar como forma canónica.', 'alta', false),
		('sexteto_lira_a1_aBaBcC', 'P', 'Patrón admitido `aBaBcC`.', 'alta', false),
		('sexteto_lira_a2_AbaBcC', 'P', 'Patrón admitido `AbaBcC`.', 'alta', false),
		('sexteto_lira_a3_abaBcC', 'P', 'Patrón admitido `abaBcC`; completar definición.', 'alta', false),
		('sexteto_lira_b1_abbacC', 'P', 'Patrón admitido `abbacC`.', 'alta', false),
		('sexteto_lira_b2_AbbACC', 'P', 'Patrón admitido `AbbACC`.', 'alta', false),
		('sexteto_lira_c1_AabBcC', 'P', 'Patrón admitido `AabBcC`; corregir tamaño 4 → 6.', 'alta', false),
		('sexteto_lira_c2_AabBCC', 'P', 'Patrón admitido `AabBCC`.', 'alta', false),
		('sexteto_lira_de_esdrujulos', 'R', 'Sexteto-lira más rasgo esdrújulo; corregir tamaño 5 → 6 mientras exista la entrada.', 'alta', false),
		('sextilla', 'F', 'Conservar como forma canónica de seis versos de arte menor.', 'alta', true),
		('sextilla_de_pie_quebrado', 'C', 'Configuración con patrón métrico ordenado; relacionar con familia de pie quebrado.', 'alta', true),
		('sextilla_sin_quebrado', 'C', 'Configuración isométrica; declarar sus medidas admitidas.', 'alta', true),
		('sextina', 'F', 'Conservar como forma compuesta; formalizar 6 × 6 + 3 y la permutación de palabras finales.', 'alta', true),
		('silva', 'F', 'Conservar como serie métrica abierta.', 'alta', true),
		('silva_de_consonantes_irregular', 'C', 'Configuración con pareados de disposición irregular.', 'media', true),
		('silva_de_consonantes_regular', 'C', 'Configuración con pareados de disposición regular.', 'media', true),
		('silva_de_endecasilabos', 'C', 'Configuración endecasílaba; decidir si el uso del corpus justifica una forma lexicalizada.', 'media', true),
		('silva_libre', '?', 'Revisar definición y denominación; candidata a forma propia solo tras resolver su contradicción bibliográfica.', 'baja', true),
		('soneto', 'F', 'Conservar como forma canónica de composición.', 'alta', false),
		('soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE', 'P', 'Patrón de rima admitido.', 'alta', false),
		('soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE', 'P', 'Patrón de rima admitido.', 'alta', false),
		('soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE', 'P', 'Patrón de rima admitido.', 'alta', false),
		('soneto_de_esdrújulos', 'R', 'Soneto más rasgo esdrújulo.', 'alta', false),
		('soneto_regular_ABBAABBACDCDCD', 'P', 'Configuración o patrón principal; no forma independiente.', 'alta', false),
		('terceto', 'F', 'Conservar como unidad de tres versos; retirar de su definición la mezcla con series completas.', 'media', true),
		('terceto_de_esdrujulos', 'R', 'Terceto más rasgo esdrújulo; corregir tamaño 1 → 3 mientras exista la entrada.', 'alta', false),
		('terceto_encadenado', 'F', 'Conservar como forma de serie abierta, diferenciada de la unidad terceto.', 'alta', true),
		('terceto_sin_encadenar_1_AXABYB', 'P', 'Patrón de una serie no encadenada; no forma independiente.', 'media', true),
		('terceto_sin_encadenar_2_XAAYBB', 'P', 'Patrón de una serie no encadenada; no forma independiente.', 'media', true),
		('terceto_octosilabo', 'C', 'Configuración octosílaba de terceto encadenado, salvo que se documente como forma lexicalizada.', 'media', true),
		('verso suelto', 'E', 'Mantener como categoría editorial residual para un verso aislado, fuera del catálogo de formas demarcables.', 'alta', true),
		('villancico', 'F', 'Conservar como forma compuesta; formalizar cabeza, mudanza, enlace, vuelta y estribillo.', 'alta', true),
		('zejel', 'F', 'Conservar como forma compuesta; formalizar estribillo, mudanza y vuelta.', 'alta', true)
)
insert into public.migracion_terminos_metricos (
	termino_id,
	clasificacion_propuesta,
	propuesta,
	certeza,
	requiere_revision
)
select
	v.termino_id,
	p.clasificacion,
	p.propuesta,
	p.certeza,
	p.requiere_revision
from propuestas p
join public.vocabularios v
	on v.categoria = 'estrofa_tipo'
	and v.termino = p.slug;

do $$
declare
	v_total integer;
begin
	select count(*) into v_total from public.migracion_terminos_metricos;
	if v_total <> 119 then
		raise exception
			'La matriz métrica esperaba 119 términos y solo pudo enlazar % con vocabularios',
			v_total;
	end if;
end;
$$;

-- Formas canónicas y salidas residuales. Se reutiliza el UUID legado para
-- facilitar la futura migración de las secuencias.
insert into public.formas_metricas (
	forma_id,
	slug,
	nombre,
	definicion,
	nivel_estructural,
	seleccionable,
	residual,
	orden,
	origen_termino_id
)
select
	v.termino_id,
	replace(v.termino, ' ', '_'),
	coalesce(nullif(btrim(v.etiqueta), ''), v.termino),
	v.definicion,
	case
		when v.termino in ('soneto') then 'composicion'
		when v.termino in ('cancion_petrarquista', 'sextina', 'villancico', 'zejel') then 'compuesta'
		when v.termino in ('endecasilabo_suelto', 'romance', 'romance_heroico', 'romancillo', 'silva', 'terceto_encadenado') then 'serie'
		when v.termino = 'verso suelto' then 'verso'
		else 'estrofa'
	end,
	true,
	m.clasificacion_propuesta = 'E',
	v.orden,
	v.termino_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
where m.clasificacion_propuesta in ('F', 'E');

-- Pareado no dispone de raíz propia en el vocabulario legado, pero cuatro
-- entradas de la matriz necesitan esta forma de destino.
insert into public.formas_metricas (
	slug,
	nombre,
	definicion,
	nivel_estructural,
	seleccionable,
	residual
)
values (
	'pareado',
	'Pareado',
	'Forma de dos versos relacionados por la rima. Registro inicial creado para reunir las configuraciones heredadas.',
	'estrofa',
	true,
	false
);

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, forma_id)
select m.termino_id, 'conservar', f.forma_id
from public.migracion_terminos_metricos m
join public.formas_metricas f on f.origen_termino_id = m.termino_id
where m.clasificacion_propuesta in ('F', 'E');

insert into public.familias_metricas (
	familia_id,
	slug,
	nombre,
	descripcion,
	orden,
	origen_termino_id
)
select
	v.termino_id,
	replace(v.termino, ' ', '_'),
	coalesce(nullif(btrim(v.etiqueta), ''), v.termino),
	coalesce(v.definicion, m.propuesta),
	v.orden,
	v.termino_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
where m.clasificacion_propuesta = 'G';

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, familia_id)
select m.termino_id, 'transformar', f.familia_id
from public.migracion_terminos_metricos m
join public.familias_metricas f on f.origen_termino_id = m.termino_id
where m.clasificacion_propuesta = 'G';

-- Configuración principal provisional de cada forma no residual.
insert into public.configuraciones_forma (
	forma_id,
	slug,
	nombre,
	descripcion,
	principal,
	demarcable,
	grado,
	naturaleza_estrofica_id,
	tipo_rima_id,
	versos_min,
	versos_max
)
select
	f.forma_id,
	'principal',
	'Configuración principal',
	'Configuración inicial derivada de los datos del término de origen. Debe revisarse antes de aprobarse.',
	true,
	true,
	'canonica',
	v.naturaleza_estrofica_id,
	v.tipo_rima_id,
	v.tamanio_unidad_estrofica,
	v.tamanio_unidad_estrofica
from public.formas_metricas f
left join public.vocabularios v on v.termino_id = f.origen_termino_id
where not f.residual;

-- Configuraciones procedentes de antiguas subformas. Se usa primero el padre
-- legado si se convirtió en forma y, para los pareados, la nueva forma común.
with destinos as (
	select
		m.termino_id,
		coalesce(fp.forma_id, pareado.forma_id) as forma_id
	from public.migracion_terminos_metricos m
	join public.vocabularios v on v.termino_id = m.termino_id
	left join public.formas_metricas fp on fp.forma_id = v.termino_padre_id
	left join public.formas_metricas pareado
		on pareado.slug = 'pareado'
		and v.termino like 'pareado_%'
	where m.clasificacion_propuesta = 'C'
)
insert into public.configuraciones_forma (
	forma_id,
	slug,
	nombre,
	descripcion,
	principal,
	demarcable,
	grado,
	naturaleza_estrofica_id,
	tipo_rima_id,
	versos_min,
	versos_max,
	orden,
	origen_termino_id
)
select
	d.forma_id,
	replace(v.termino, ' ', '_'),
	coalesce(nullif(btrim(v.etiqueta), ''), v.termino),
	concat_ws(E'\n\n', m.propuesta, nullif(btrim(v.definicion), '')),
	false,
	true,
	'admitida',
	v.naturaleza_estrofica_id,
	v.tipo_rima_id,
	v.tamanio_unidad_estrofica,
	v.tamanio_unidad_estrofica,
	v.orden,
	v.termino_id
from destinos d
join public.migracion_terminos_metricos m on m.termino_id = d.termino_id
join public.vocabularios v on v.termino_id = d.termino_id
where d.forma_id is not null;

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, configuracion_id)
select m.termino_id, 'transformar', c.configuracion_id
from public.migracion_terminos_metricos m
join public.configuraciones_forma c on c.origen_termino_id = m.termino_id
where m.clasificacion_propuesta = 'C';

-- Patrones métricos obtenidos de los conjuntos de metros actuales. Un conjunto
-- no se interpreta como secuencia ordenada: esa información deberá completarse
-- en el constructor especializado del catálogo.
insert into public.patrones_metricos (
	configuracion_id,
	ambito,
	tipo,
	longitud_minima,
	longitud_maxima,
	descripcion
)
select
	c.configuracion_id,
	'unidad',
	case when count(etm.metro_id) = 1 then 'secuencia_repetible' else 'conjunto_permitido' end,
	c.versos_min,
	c.versos_max,
	'Importado como conjunto de medidas; el orden no se infiere del vocabulario legado.'
from public.configuraciones_forma c
join public.formas_metricas f on f.forma_id = c.forma_id
left join public.estrofa_tipo_metros etm
	on etm.estrofa_tipo_id = coalesce(c.origen_termino_id, f.origen_termino_id)
group by c.configuracion_id, c.versos_min, c.versos_max
having count(etm.metro_id) > 0;

insert into public.patron_metrico_opciones (patron_metrico_id, metro_id, orden)
select
	pm.patron_metrico_id,
	etm.metro_id,
	row_number() over (
		partition by pm.patron_metrico_id
		order by coalesce(v.numero_silabas, 999), v.termino
	)
from public.patrones_metricos pm
join public.configuraciones_forma c on c.configuracion_id = pm.configuracion_id
join public.formas_metricas f on f.forma_id = c.forma_id
join public.estrofa_tipo_metros etm
	on etm.estrofa_tipo_id = coalesce(c.origen_termino_id, f.origen_termino_id)
join public.vocabularios v on v.termino_id = etm.metro_id;

-- Patrón de rima básico de cada configuración cuando hay información propia.
insert into public.patrones_rima (
	configuracion_id,
	nombre,
	esquema,
	tipo_rima_id,
	ambito,
	fijeza,
	descripcion
)
select
	c.configuracion_id,
	'Patrón principal',
	v.patron_especifico,
	coalesce(c.tipo_rima_id, v.tipo_rima_id),
	'unidad',
	case when nullif(btrim(v.patron_especifico), '') is null then 'admitido' else 'fijo' end,
	'Importado desde los datos estructurados del vocabulario anterior.'
from public.configuraciones_forma c
join public.formas_metricas f on f.forma_id = c.forma_id
join public.vocabularios v
	on v.termino_id = coalesce(c.origen_termino_id, f.origen_termino_id)
where c.tipo_rima_id is not null
	or v.tipo_rima_id is not null
	or nullif(btrim(v.patron_especifico), '') is not null;

-- Entradas que eran únicamente patrones: se enlazan a la configuración
-- principal de la forma padre sin convertirlas en formas seleccionables.
insert into public.patrones_rima (
	configuracion_id,
	nombre,
	esquema,
	tipo_rima_id,
	ambito,
	fijeza,
	descripcion,
	origen_termino_id
)
select
	c.configuracion_id,
	coalesce(nullif(btrim(v.etiqueta), ''), v.termino),
	coalesce(
		nullif(btrim(v.patron_especifico), ''),
		(substring(v.termino from '([A-Za-z-]+)$'))
	),
	coalesce(v.tipo_rima_id, c.tipo_rima_id),
	'unidad',
	'admitido',
	concat_ws(E'\n\n', m.propuesta, nullif(btrim(v.definicion), '')),
	v.termino_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
join public.formas_metricas f on f.forma_id = v.termino_padre_id
join public.configuraciones_forma c on c.forma_id = f.forma_id and c.principal
where m.clasificacion_propuesta = 'P';

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, patron_rima_id)
select m.termino_id, 'transformar', p.patron_rima_id
from public.migracion_terminos_metricos m
join public.patrones_rima p on p.origen_termino_id = m.termino_id
where m.clasificacion_propuesta = 'P';

-- Rasgos transversales detectables en la matriz inicial.
insert into public.rasgos_metricos (
	slug,
	nombre,
	descripcion,
	tipo_valor,
	observabilidad,
	demarcable
)
values
	(
		'final_acentual',
		'Final acentual',
		'Comportamiento acentual destacado de los finales de verso.',
		'catalogo',
		'directa',
		false
	),
	(
		'vocales_asonancia',
		'Vocales de la asonancia',
		'Vocales que caracterizan la rima asonante de una secuencia.',
		'catalogo',
		'especializada',
		false
	);

insert into public.rasgo_valores (rasgo_id, slug, nombre)
select rasgo_id, 'esdrujulo', 'Esdrújulo'
from public.rasgos_metricos
where slug = 'final_acentual';

insert into public.rasgo_valores (
	rasgo_id,
	slug,
	nombre,
	origen_termino_id
)
select
	r.rasgo_id,
	regexp_replace(v.termino, '^romance_', ''),
	regexp_replace(v.termino, '^romance_', ''),
	v.termino_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
cross join public.rasgos_metricos r
where m.clasificacion_propuesta = 'R'
	and v.termino like 'romance_%'
	and r.slug = 'vocales_asonancia';

insert into public.migracion_termino_destinos (
	termino_id,
	tipo_operacion,
	valor_rasgo_id
)
select m.termino_id, 'transformar', rv.valor_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
join public.rasgo_valores rv on rv.origen_termino_id = v.termino_id
where m.clasificacion_propuesta = 'R'
	and v.termino like 'romance_%';

insert into public.migracion_termino_destinos (
	termino_id,
	tipo_operacion,
	valor_rasgo_id
)
select m.termino_id, 'transformar', rv.valor_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
join public.rasgo_valores rv on rv.slug = 'esdrujulo'
join public.rasgos_metricos r
	on r.rasgo_id = rv.rasgo_id
	and r.slug = 'final_acentual'
where m.clasificacion_propuesta = 'R'
	and (
		v.termino like '%esdrujulos'
		or v.termino like '%esdrújulos'
	);

-- Alias fusionados con la forma padre.
insert into public.forma_aliases (
	forma_id,
	nombre,
	slug_normalizado,
	tipo_alias,
	origen_termino_id
)
select
	f.forma_id,
	coalesce(nullif(btrim(v.etiqueta), ''), v.termino),
	replace(v.termino, ' ', '_'),
	'historico',
	v.termino_id
from public.migracion_terminos_metricos m
join public.vocabularios v on v.termino_id = m.termino_id
join public.formas_metricas f on f.forma_id = v.termino_padre_id
where m.clasificacion_propuesta = 'A';

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, alias_id)
select m.termino_id, 'fusionar', a.alias_id
from public.migracion_terminos_metricos m
join public.forma_aliases a on a.origen_termino_id = m.termino_id
where m.clasificacion_propuesta = 'A';

insert into public.migracion_termino_destinos (termino_id, tipo_operacion, nota)
select termino_id, 'retirar', propuesta
from public.migracion_terminos_metricos
where clasificacion_propuesta = 'D';

-- Las tradiciones se ofrecen desde el primer día como dimensión separada; no
-- se infiere todavía ninguna pertenencia forma-tradición.
insert into public.tradiciones_metricas (slug, nombre, estado_revision)
values
	('espanola', 'Española', 'borrador'),
	('italiana', 'Italiana', 'borrador'),
	('provenzal', 'Provenzal', 'borrador');

-- Relaciones seguras y explícitas que ayudan a orientar la primera revisión.
insert into public.forma_relaciones (
	forma_origen_id,
	forma_destino_id,
	tipo_relacion,
	nota
)
select hija.forma_id, padre.forma_id, 'subtipo_de', 'Relación inicial propuesta por la matriz de reclasificación.'
from public.formas_metricas hija
join public.formas_metricas padre on (
	(hija.slug = 'copla_manriqueña' and padre.slug = 'doble_sextilla')
	or (hija.slug = 'romance_heroico' and padre.slug = 'romance')
	or (hija.slug = 'redondilla_doble_abbaacca' and padre.slug = 'redondilla')
);

-- La familia de pie quebrado recibe únicamente formas canónicas; las
-- configuraciones se revisarán desde sus propias formas.
insert into public.familias_formas (familia_id, forma_id, es_principal, nota)
select
	fam.familia_id,
	forma.forma_id,
	forma.slug = 'doble_sextilla',
	'Pertenencia inicial propuesta para revisión.'
from public.familias_metricas fam
join public.formas_metricas forma
	on forma.slug in ('doble_sextilla', 'copla_manriqueña')
where fam.slug = 'copla_de_pie_quebrado';

-- Comprobaciones de cobertura de la carga. Los cuatro términos con decisión
-- abierta no tienen destino todavía; otros términos pueden quedar sin destino
-- si su padre legado no produjo una entidad compatible y deben verse como
-- incidencias en el gestor.
do $$
declare
	v_sin_destino integer;
begin
	select count(*)
	into v_sin_destino
	from public.migracion_terminos_metricos m
	where m.clasificacion_propuesta not in ('?')
		and not exists (
			select 1
			from public.migracion_termino_destinos d
			where d.termino_id = m.termino_id
		);

	if v_sin_destino > 0 then
		raise notice
			'La importación deja % términos no abiertos sin destino automático; deben revisarse en el gestor',
			v_sin_destino;
	end if;
end;
$$;

commit;
