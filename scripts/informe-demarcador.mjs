/**
 * Regenera el inventario del demarcador leyendo la base, no la memoria de nadie.
 *
 * **Qué es y qué no.** Este informe cuenta *con qué material trabaja* el demarcador hoy: qué formas
 * y arquitecturas entran, qué puede preguntar de cada una, qué rasgos quedan fuera y por qué, y qué
 * contrastes declara el catálogo para el recorrido de comprobación. **El porqué de cada decisión
 * —las escalas, la puntuación, el criterio de parada— no está aquí**: eso es diseño y vive escrito
 * a mano en `demarcador-metrico.md`, que este informe no sustituye ni repite.
 *
 * La división es deliberada. Lo que cambia cuando alguien toca el catálogo se regenera; lo que
 * cambia cuando alguien cambia de idea se escribe. Un documento que mezcle las dos cosas miente a
 * la semana siguiente, que es exactamente lo que ya pasó con el versionado del demarcador.
 *
 * Escribe `docs/dominio-metrico/informe-demarcador.md`, que por eso no se edita a mano.
 *
 *   npm run demarcador:informe
 */
import fs from 'node:fs';
import path from 'node:path';
import { query } from './lib/consulta.mjs';

const RAIZ = path.resolve(import.meta.dirname, '..');
const SALIDA = path.join(RAIZ, 'docs', 'dominio-metrico', 'informe-demarcador.md');

const lineas = [];
const escribe = (texto = '') => lineas.push(texto);
const tabla = (cabeceras, filas) => {
	escribe(`| ${cabeceras.join(' | ')} |`);
	escribe(`|${cabeceras.map(() => '---').join('|')}|`);
	for (const fila of filas) escribe(`| ${fila.join(' | ')} |`);
	escribe();
};

const hoy = new Date().toISOString().slice(0, 10);

escribe('# Con qué trabaja el demarcador');
escribe();
escribe(`Generado el ${hoy} desde la base enlazada con \`npm run demarcador:informe\`. **No se edita a mano.**`);
escribe();
escribe(
	'Este documento dice **qué material tiene** el demarcador. El **porqué** de cada decisión —las dos'
);
escribe(
	'escalas del catálogo, cómo se puntúa la compatibilidad, cómo se elige la pregunta siguiente y'
);
escribe(
	'cuándo se detiene el recorrido— está en [demarcador-metrico.md](./demarcador-metrico.md), escrito a'
);
escribe('mano porque cambia cuando alguien cambia de idea, no cuando alguien toca el catálogo.');
escribe();

// ---------------------------------------------------------------------------
escribe('## 1 · Qué entra y qué queda fuera');
escribe();
escribe(
	'El demarcador compila una **hipótesis por arquitectura**: la forma es la identidad del resultado y'
);
escribe('la arquitectura, la precisión de su realización.');
escribe();

const inventario = query(`
	select
		(select count(*) from formas_metricas where activo and tipo_registro = 'forma')::int as formas,
		(select count(*) from formas_metricas where activo and tipo_registro <> 'forma')::int as no_formas,
		(select count(*) from arquitecturas_forma a join formas_metricas f on f.forma_id = a.forma_id
		 where a.activo and a.demarcable and f.activo and f.tipo_registro = 'forma')::int as demarcables,
		(select count(*) from arquitecturas_forma a join formas_metricas f on f.forma_id = a.forma_id
		 where a.activo and not a.demarcable and f.activo)::int as no_demarcables,
		(select count(*) from arquitecturas_forma where not activo)::int as inactivas;`)[0];

tabla(
	['', 'cuántas'],
	[
		['Formas que el demarcador puede proponer', inventario.formas],
		['Registros que no son forma (tramos sin forma)', inventario.no_formas],
		['**Arquitecturas que compila**', `**${inventario.demarcables}**`],
		['Arquitecturas activas pero no demarcables', inventario.no_demarcables],
		['Arquitecturas inactivas', inventario.inactivas]
	]
);

const sinDemarcable = query(`
	select f.nombre
	from formas_metricas f
	where f.activo and f.tipo_registro = 'forma'
		and not exists (
			select 1 from arquitecturas_forma a
			where a.forma_id = f.forma_id and a.activo and a.demarcable
		)
	order by 1;`);
if (sinDemarcable.length > 0) {
	escribe(
		sinDemarcable.length === 1
			? `> **${sinDemarcable[0].nombre} no tiene ninguna arquitectura demarcable**, así que el demarcador no puede proponerla nunca.`
			: `> **${sinDemarcable.length} formas no tienen ninguna arquitectura demarcable**, así que el demarcador no puede proponerlas nunca: ${sinDemarcable
					.map((f) => f.nombre)
					.join(', ')}.`
	);
	escribe();
}

// ---------------------------------------------------------------------------
escribe('## 2 · Qué puede preguntar');
escribe();
escribe(
	'Cada dimensión sale de una parte distinta del catálogo. La **cobertura** dice cuántas de las'
);
escribe(
	'arquitecturas compiladas la declaran: una dimensión que casi nadie declara separa poco, por muy'
);
escribe('fácil de responder que sea.');
escribe();

const cobertura = query(`
	with demarcables as (
		select a.arquitectura_id
		from arquitecturas_forma a join formas_metricas f on f.forma_id = a.forma_id
		where a.activo and a.demarcable and f.activo and f.tipo_registro = 'forma'
	)
	select
		(select count(*) from demarcables)::int as total,
		(select count(distinct em.arquitectura_id) from esquemas_metricos em
		 join demarcables d on d.arquitectura_id = em.arquitectura_id)::int as metro,
		(select count(distinct rl.arquitectura_id) from arquitecturas_reglas_longitud rl
		 join demarcables d on d.arquitectura_id = rl.arquitectura_id)::int as extension,
		(select count(distinct er.arquitectura_id) from esquemas_rima er
		 join demarcables d on d.arquitectura_id = er.arquitectura_id)::int as rima,
		(select count(distinct es.arquitectura_id) from estructuras_secciones es
		 join demarcables d on d.arquitectura_id = es.arquitectura_id)::int as secciones,
		(select count(distinct ar.arquitectura_id) from arquitectura_rasgos ar
		 join demarcables d on d.arquitectura_id = ar.arquitectura_id
		 join rasgos_metricos rm on rm.rasgo_id = ar.rasgo_id where rm.demarcable)::int as rasgos;`)[0];

const pct = (n) => `${n} de ${cobertura.total}`;
tabla(
	['familia', 'de dónde sale', 'cobertura'],
	[
		['Metro', 'esquemas métricos: posiciones y opciones', pct(cobertura.metro)],
		['Extensión', 'reglas de longitud derivadas de la unidad', pct(cobertura.extension)],
		['Rima', 'esquemas de rima y su tipo', pct(cobertura.rima)],
		['Estructura', 'secciones internas y su orden', pct(cobertura.secciones)],
		['Rasgo', 'rasgos marcados como demarcables', pct(cobertura.rasgos)]
	]
);

// ---------------------------------------------------------------------------
escribe('## 3 · Los rasgos, y por qué algunos no se preguntan');
escribe();
escribe(
	'Un rasgo solo se pregunta si el catálogo lo marca `demarcable`. La regla que hay detrás es que la'
);
escribe(
	'interfaz solo debe preguntar **hechos que el usuario pueda observar**: lo demás se calcula o se'
);
escribe('calla.');
escribe();

const rasgos = query(`
	select rm.nombre, rm.observabilidad, rm.demarcable, rm.tipo_valor,
		(select count(*) from rasgo_valores rv where rv.rasgo_id = rm.rasgo_id and rv.activo)::int as valores,
		(select count(*) from arquitectura_rasgos ar where ar.rasgo_id = rm.rasgo_id)::int as usos
	from rasgos_metricos rm where rm.activo order by rm.demarcable desc, rm.nombre;`);
tabla(
	['rasgo', 'se pregunta', 'observabilidad', 'valores', 'lo declaran'],
	rasgos.map((r) => [
		r.nombre,
		r.demarcable ? 'sí' : '**no**',
		r.observabilidad,
		r.valores === 0 ? 'booleano' : r.valores === 1 ? '1 · es de presencia' : String(r.valores),
		String(r.usos)
	])
);
escribe(
	'*Un rasgo de **un solo valor** es de presencia: su contenido entero es estar presente, así que se'
);
escribe(
	'pregunta como booleano —«¿se observa…?», sí o no— y no como una lista de un elemento. Sin eso, un'
);
escribe('pasaje que **no** lo lleva no se podría decir, y el rasgo no podría contradecir a ninguna forma.*');
escribe();

// ---------------------------------------------------------------------------
escribe('## 4 · Contra quién se contrasta una hipótesis');
escribe();
escribe(
	'El recorrido de comprobación no compara la forma propuesta contra el catálogo entero, sino contra'
);
escribe(
	'**sus rivales**: los que el catálogo declara en `forma_relaciones`, más los que las respuestas'
);
escribe(
	'hayan puesto arriba, más los estructuralmente próximos cuando no hay contraste declarado. Estas'
);
escribe('son las declaraciones de hoy, y su nota es lo que la pantalla enseña al terminar.');
escribe();

const contrastes = query(`
	select o.nombre as origen, d.nombre as destino, fr.tipo_relacion,
		coalesce(nullif(btrim(fr.nota), ''), '—') as nota
	from forma_relaciones fr
	join formas_metricas o on o.forma_id = fr.forma_origen_id
	join formas_metricas d on d.forma_id = fr.forma_destino_id
	where fr.tipo_relacion in ('contrasta_con', 'derivada_de')
	order by fr.tipo_relacion, o.nombre;`);
tabla(
	['par', 'relación', 'qué las separa, según el catálogo'],
	contrastes.map((c) => [
		`${c.origen} ↔ ${c.destino}`,
		c.tipo_relacion,
		c.nota.length > 150 ? `${c.nota.slice(0, 150)}…` : c.nota
	])
);

const sinContraste = query(`
	select f.nombre
	from formas_metricas f
	where f.activo and f.tipo_registro = 'forma'
		and not exists (
			select 1 from forma_relaciones fr
			where (fr.forma_origen_id = f.forma_id or fr.forma_destino_id = f.forma_id)
				and fr.tipo_relacion in ('contrasta_con', 'derivada_de')
		)
	order by 1;`);
escribe(
	`**${sinContraste.length} formas no declaran ningún contraste.** Para ellas el recorrido de comprobación`
);
escribe(
	'cae en la afinidad estructural —las que predicen lo mismo en más dimensiones—, que cubre el hueco'
);
escribe('pero no sabe lo que sabe un filólogo:');
escribe();
escribe(`> ${sinContraste.map((f) => f.nombre).join(' · ')}`);
escribe();

// ---------------------------------------------------------------------------
escribe('## 5 · Conjuntos de medidas: admitir no es mezclar');
escribe();
escribe(
	'Un esquema de `tipo_secuencia = conjunto` enumera las medidas admitidas. **`medida_uniforme`**'
);
escribe(
	'decide qué significa esa lista: si es `true`, la arquitectura admite *cualquiera* de ellas pero una'
);
escribe(
	'sola cada vez —el pareado de cualquier medida es isosilábico—; si es `false`, las **combina** dentro'
);
escribe(
	'de la unidad, como la silva alterna siete y once. Declararlo mal hace que el demarcador resuma el'
);
escribe('repertorio en «mixto» y **contradiga** a la forma en la primera pregunta.');
escribe();

const conjuntos = query(`
	select f.nombre as forma, a.nombre as arq, em.medida_uniforme,
		(select count(distinct m.silabas) from esquema_metrico_opciones o
		 join metros m on m.metro_id = o.metro_id where o.esquema_metrico_id = em.esquema_metrico_id)::int as medidas
	from esquemas_metricos em
	join arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join formas_metricas f on f.forma_id = a.forma_id
	where em.tipo_secuencia = 'conjunto' and a.activo
	order by 3 desc nulls first, 1;`);
tabla(
	['forma · arquitectura', 'medidas admitidas', 'qué declara'],
	conjuntos.map((c) => [
		`${c.forma} · ${c.arq}`,
		String(c.medidas),
		c.medida_uniforme === true
			? 'una cualquiera de ellas'
			: c.medida_uniforme === false
				? 'las combina'
				: '**sin declarar**'
	])
);

// ---------------------------------------------------------------------------
escribe('## 6 · Avisos');
escribe();
const avisos = [];

const uniformeSinDeclarar = conjuntos.filter((c) => c.medida_uniforme === null);
if (uniformeSinDeclarar.length > 0) {
	avisos.push(
		`**${uniformeSinDeclarar.length} conjuntos no declaran \`medida_uniforme\`**, así que el demarcador no sabe si admiten una medida cualquiera o las combinan: ${uniformeSinDeclarar
			.map((c) => `${c.forma} · ${c.arq}`)
			.join(', ')}.`
	);
}

const contrasteNoDemarcable = query(`
	select distinct f.nombre
	from forma_relaciones fr
	join formas_metricas f on f.forma_id in (fr.forma_origen_id, fr.forma_destino_id)
	where fr.tipo_relacion in ('contrasta_con', 'derivada_de')
		and not exists (
			select 1 from arquitecturas_forma a
			where a.forma_id = f.forma_id and a.activo and a.demarcable
		)
	order by 1;`);
if (contrasteNoDemarcable.length > 0) {
	avisos.push(
		`**Hay contrastes declarados contra formas que el demarcador no puede proponer**: ${contrasteNoDemarcable
			.map((f) => f.nombre)
			.join(', ')}. El contraste no llega a usarse.`
	);
}

const rasgosPresencia = rasgos.filter((r) => r.demarcable && r.valores === 1);
if (rasgosPresencia.length > 0) {
	avisos.push(
		`**${rasgosPresencia.length} ${rasgosPresencia.length === 1 ? 'rasgo de presencia se pregunta' : 'rasgos de presencia se preguntan'} como booleano**: ${rasgosPresencia
			.map((r) => r.nombre)
			.join(', ')}. Si ganara un segundo valor dejaría de ser una presencia, y la pregunta cambiaría sola.`
	);
}

if (avisos.length === 0) escribe('Sin avisos.');
else for (const aviso of avisos) escribe(`- ${aviso}`);
escribe();

fs.mkdirSync(path.dirname(SALIDA), { recursive: true });
fs.writeFileSync(SALIDA, `${lineas.join('\n')}\n`, 'utf-8');
console.log(`Informe escrito en ${path.relative(RAIZ, SALIDA)} · ${lineas.length} líneas.`);
