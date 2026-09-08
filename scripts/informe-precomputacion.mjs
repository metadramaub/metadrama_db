/**
 * Regenera el mapa de la precomputación leyendo la base, no la memoria de nadie.
 *
 * Un documento escrito a mano sobre qué se guarda y qué se calcula en vivo envejece a la semana
 * siguiente: basta una columna nueva. Este informe **pregunta a la base** qué columnas tiene el
 * resumen, **ejecuta la ficha** sobre una obra real para ver qué claves devuelve, y **cuenta lo
 * anotado** para decir qué está registrado sin salir por ningún lado.
 *
 * Escribe `docs/mapa-precomputacion.md`, que por eso no se edita a mano.
 *
 *   npm run precomputacion:informe
 */
import fs from 'node:fs';
import path from 'node:path';
import { query } from './lib/consulta.mjs';

const RAIZ = path.resolve(import.meta.dirname, '..');
const SALIDA = path.join(RAIZ, 'docs', 'mapa-precomputacion.md');

const lit = (v) => `'${String(v).replaceAll("'", "''")}'`;
const scalar = (sql) => {
	const filas = query(sql);
	return filas.length ? Object.values(filas[0])[0] : null;
};

/**
 * Para qué sirve cada columna del resumen y quién la lee.
 *
 * Es lo único escrito a mano del informe, porque es lo único que la base no sabe. Una columna que
 * no esté aquí sale marcada como **sin describir**, que es la manera de que añadir una medida sin
 * decir para qué obligue a volver.
 */
const PARA_QUE = {
	total_versos: ['recuento', 'buscador, ficha'],
	n_secuencias: ['recuento', 'buscador'],
	n_jornadas: ['recuento', 'buscador'],
	n_formas_distintas: ['cuántas formas aparecen', 'buscador, perfil de autor'],
	numero_efectivo_formas: ['diversidad métrica: exp(H)', 'buscador, perfil de autor'],
	p_max: ['peso de la forma dominante', 'buscador'],
	densidad_transiciones: ['cambios de forma por cien versos', 'buscador'],
	pct_cantado: ['porcentaje de versos cantados', 'nadie todavía'],
	tramos: ['el código de barras: {i, f, s, t} por tramo fusionado', 'buscador'],
	perfil_formas: ['{forma_slug: versos}', 'buscador, perfil de autor'],
	formas_presentes: ['filtro', 'buscador'],
	metros_presentes: ['filtro', 'buscador'],
	tipos_forma_presentes: ['filtro: española / italiana', 'buscador'],
	subtipos_presentes: ['filtro: esquemas de rima', 'buscador'],
	variaciones_presentes: ['filtro', 'buscador'],
	tiene_versos_partidos: ['bandera', 'buscador'],
	tiene_cambio_espacio: ['bandera', 'buscador'],
	intervencion_femenina: ['agregado de la pregunta por secuencia', 'buscador'],
	intervencion_donaire: ['agregado de la pregunta por secuencia', 'buscador'],
	intervencion_sobrenaturales: ['agregado de la pregunta por secuencia', 'buscador'],
	metrica_sucia: ['control: hay que recomputar', 'dashboard'],
	actualizado_en: ['control', 'dashboard'],
	jornadas_tramos: ['los cortes de jornada que se dibujan sobre el barcode', 'buscador'],
	cuadros_tramos: ['los cortes de cuadro que se dibujan sobre el barcode', 'buscador'],
	ficha: [
		'**la ficha pública completa**, tal como la ve un anónimo: la construye `ficha_publica_json`',
		'la ficha de una obra publicada'
	],
	tiene_evento_sobrenatural: ['bandera', 'buscador'],
	obra_id: ['clave', '—'],
	autor_id: ['clave', '—'],
	alcance: ['qué obras entran en el agregado', 'perfil de autor'],
	n_obras_completas: ['recuento', 'perfil de autor'],
	n_jornadas_sueltas: ['recuento', 'perfil de autor'],
	total_versos_autor: ['recuento', 'perfil de autor'],
	numero_efectivo_formas_medio: ['diversidad media de sus obras', 'perfil de autor'],
	numero_efectivo_formas_agregado: ['diversidad del conjunto', 'perfil de autor'],
	perfil_formas_hijos: ['desglose por arquitectura', 'perfil de autor']
};

/**
 * Lo que un editor puede registrar, y dónde habría que buscarlo.
 *
 * `cuantas` cuenta cuántas filas hay hoy; `clave` es la del JSON de la ficha, si llega. Lo que
 * tiene filas y no tiene clave es lo que está anotado y no se ve.
 */
const REGISTRABLE = [
	{
		nombre: 'Rasgos observados (asonancia, densidad de rima, final acentual)',
		cuantas: `select count(*) from public.anotacion_elecciones where valor_rasgo_id is not null`,
		clave: 'rasgos', columna: null
	},
	{
		nombre: 'Metro elegido por unidad',
		cuantas: `select count(*) from public.anotacion_elecciones where metro_id is not null`,
		clave: 'metros', columna: 'metros_presentes'
	},
	{
		nombre: 'Esquema de rima elegido por unidad',
		cuantas: `select count(*) from public.anotacion_elecciones where esquema_rima_id is not null`,
		clave: 'subtipos_estrofa', columna: 'subtipos_presentes'
	},
	{
		nombre: 'Desviaciones (lagunas, hipométricos, rima ajena)',
		cuantas: `select count(*) from public.anotacion_desviaciones`,
		clave: 'desviaciones', columna: null
	},
	{
		nombre: 'Partes de la unidad (estancia, mudanza, sirima)',
		cuantas: `select count(*) from public.anotacion_realizaciones where seccion_id is not null`,
		clave: null,
		columna: null
	},
	{
		nombre: 'Caracterizaciones por rango (cantado, prosa, evocación)',
		cuantas: `select count(*) from public.secuencias_caracterizaciones_rango`,
		clave: 'caracterizaciones_rango', columna: 'pct_cantado'
	},
	{
		nombre: 'Versos partidos',
		cuantas: `select count(*) from public.secuencias_metricas where versos_partidos`,
		clave: 'versos_partidos', columna: 'tiene_versos_partidos'
	},
	{
		nombre: 'Inaugura espacio',
		cuantas: `select count(*) from public.secuencias_metricas where inaugura_espacio`,
		clave: 'inaugura_espacio', columna: 'tiene_cambio_espacio'
	},
	{
		nombre: 'Evento sobrenatural',
		cuantas: `select count(*) from public.secuencias_metricas where evento_sobrenatural`,
		clave: 'evento_sobrenatural', columna: 'tiene_evento_sobrenatural'
	},
	{
		nombre: 'Intervención de personajes femeninos',
		cuantas: `select count(*) from public.secuencias_metricas where intervencion_personajes_femeninos <> 'sin_intervencion'`,
		clave: 'intervencion_personajes_femeninos', columna: 'intervencion_femenina'
	},
	{
		nombre: 'Intervención de figuras de donaire',
		cuantas: `select count(*) from public.secuencias_metricas where intervencion_figuras_donaire <> 'sin_intervencion'`,
		clave: 'intervencion_figuras_donaire', columna: 'intervencion_donaire'
	},
	{
		nombre: 'Intervención de personajes sobrenaturales',
		cuantas: `select count(*) from public.secuencias_metricas where intervencion_personajes_sobrenaturales <> 'sin_intervencion'`,
		clave: 'intervencion_personajes_sobrenaturales', columna: 'intervencion_sobrenaturales'
	}
];

function columnas(tabla) {
	return query(`
		select column_name, data_type
		from information_schema.columns
		where table_schema = 'public' and table_name = ${lit(tabla)}
		order by ordinal_position
	`);
}

function tablaDeColumnas(tabla) {
	const filas = columnas(tabla).map((c) => {
		const dicho = PARA_QUE[c.column_name];
		return `| \`${c.column_name}\` | ${c.data_type} | ${dicho ? dicho[0] : '**sin describir**'} | ${dicho ? dicho[1] : '—'} |`;
	});
	return ['| columna | tipo | qué es | quién la lee |', '|---|---|---|---|', ...filas].join('\n');
}

// --------------------------------------------------------------------------

const obra = scalar(`
	select sm.obra_id
	from public.secuencias_metricas sm
	join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
	group by sm.obra_id
	order by count(*) desc
	limit 1
`);
if (!obra) {
	console.error('No hay ninguna obra anotada con el catálogo nuevo: el informe no diría nada.');
	process.exit(1);
}

// **La ficha se ejecuta.** Es la única manera de saber qué claves devuelve de verdad, y de paso
// comprueba que compila: un cuerpo entrecomillado no se revalida al borrar una columna.
const admin = scalar(`
	select e.user_id from public.editores e
	join public.vocabularios rol on rol.termino_id = e.role
	where lower(rol.termino) in ('admin', 'ip')
	order by e.created_at limit 1
`);
const claves = query(`
	select jsonb_object_keys(v) as k
	from (
		select set_config('request.jwt.claims', json_build_object('sub', ${lit(admin)})::text, false),
		       public.get_obra_ficha_publica_base_without_slugs(${lit(obra)}::uuid, true) as v
	) t
`).map((r) => r.k);
const clavesSecuencia = query(`
	select jsonb_object_keys(v#>'{metrica,secuencias,0}') as k
	from (
		select set_config('request.jwt.claims', json_build_object('sub', ${lit(admin)})::text, false),
		       public.get_obra_ficha_publica_base_without_slugs(${lit(obra)}::uuid, true) as v
	) t
`).map((r) => r.k);

const columnasResumen = new Set(columnas('obras_resumen').map((c) => c.column_name));
const inventario = REGISTRABLE.map((r) => {
	const cuantas = Number(scalar(r.cuantas) ?? 0);
	const enFicha = r.clave && clavesSecuencia.includes(r.clave);
	// **El nombre no tiene por qué coincidir**: los versos partidos se guardan como
	// `tiene_versos_partidos` y lo cantado como `pct_cantado`, así que la columna se dice aparte.
	const enResumen = Boolean(r.columna && columnasResumen.has(r.columna));
	return { ...r, cuantas, enFicha, enResumen };
});

const cuentas = {
	obras: scalar(`select count(*) from public.obras`),
	publicadas: scalar(`
		select count(*) from public.obras o
		join public.vocabularios v on v.termino_id = o.estado
		where v.termino = 'publicado'
	`),
	resumen: scalar(`select count(*) from public.obras_resumen`),
	secuencias: scalar(`select count(*) from public.secuencias_metricas`),
	anotadas: scalar(`select count(*) from public.anotaciones_metricas`),
	legadas: scalar(`select count(*) from public.secuencias_metricas where estrofa_tipo_id is not null`),
	sinCuadro: scalar(`
		select count(*) from jsonb_array_elements(
			public.get_obra_ficha_publica_base_without_slugs(${lit(obra)}::uuid, true)->'metrica'->'secuencias'
		) s where s->>'cuadro_id' is null
	`)
};

const hoy = new Date().toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' });

const doc = `# Mapa de la precomputación

> **Este documento se genera.** Lo escribe \`npm run precomputacion:informe\` leyendo la base y
> **ejecutando la ficha**, así que no se edita a mano: lo que se cambia es el guion. Lo que la base
> no puede saber —para qué sirve cada columna y quién la lee— vive en \`scripts/informe-precomputacion.mjs\`,
> y una columna que nadie haya descrito sale marcada como **sin describir**.

Regenerado el ${hoy}.

## Las tres capas

**1 · Lo anotado.** \`secuencias_metricas\` y, colgando de ella, \`anotaciones_metricas\` →
\`anotacion_realizaciones\` (las unidades y sus partes), \`anotacion_elecciones\` (las respuestas) y
\`anotacion_desviaciones\`. Aparte, \`secuencias_caracterizaciones_rango\`, y la estructura en
\`jornadas\` y \`cuadros\`.

**2 · Lo precomputado.** \`obras_resumen\` y \`autores_resumen\`. Se rehacen al pulsar «Actualizar
datos públicos» o con \`recompute_all()\`, y **solo para obras publicadas**.

**3 · La ficha.** \`get_obra_ficha_publica_base_without_slugs(obra, include_hidden)\` lee hoy las
tablas crudas en cada visita. Lo pactado el 8 de septiembre de 2026 es que **eso se quede solo para
la vista previa** y que una obra publicada esté enteramente precomputada; los cinco pasos están en
[el contexto métrico](dominio-metrico/CONTEXTO-PARA-CONTINUAR.md#el-plan-pactado-en-cinco-pasos).

Mientras las dos superficies se escriban por separado, **cada medida hay que escribirla dos veces**
—en \`recompute_obra_resumen_metricas\` y en la función de ficha— o solo aparece en un sitio. Ese es
el problema que el paso 1 del plan viene a cerrar.

## Cuántas hay

| | |
|---|--:|
| obras | ${cuentas.obras} |
| obras publicadas | ${cuentas.publicadas} |
| filas en \`obras_resumen\` | ${cuentas.resumen} |
| secuencias | ${cuentas.secuencias} |
| secuencias con anotación del catálogo nuevo | ${cuentas.anotadas} |
| secuencias que aún hablan el vocabulario legado | ${cuentas.legadas} |

## Qué guarda \`obras_resumen\`

${tablaDeColumnas('obras_resumen')}

## Qué guarda \`autores_resumen\`

${tablaDeColumnas('autores_resumen')}

## Qué devuelve la ficha

Ejecutada sobre la obra con más secuencias anotadas.

Bloques: ${claves.map((k) => `\`${k}\``).join(', ')}.

Y de cada secuencia: ${clavesSecuencia.map((k) => `\`${k}\``).join(', ')}.

## Lo que se puede registrar, y dónde aparece

Lo que tiene filas y no llega a ninguna de las dos superficies está anotado y no se ve.

| dato | filas hoy | columna del resumen | en la ficha |
|---|--:|---|:--:|
${inventario
	.map(
		(r) =>
			`| ${r.nombre} | ${r.cuantas} | ${r.enResumen ? `\`${r.columna}\`` : '—'} | ${r.enFicha ? 'sí' : '**no**'} |`
	)
	.join('\n')}

## Comprobaciones

- **Secuencias sin cuadro en la obra de muestra: ${cuentas.sinCuadro}.** Debe ser cero: una secuencia
  pertenece al cuadro donde empieza, y que la tirada siga sonando después del corte se dice en
  \`cuadro_continua\`. Si esto sube, alguien ha vuelto a exigir que la secuencia quepa entera.
- **Columnas sin describir:** ${
		[...columnasResumen].filter((c) => !PARA_QUE[c]).length +
		columnas('autores_resumen').filter((c) => !PARA_QUE[c.column_name]).length
	}. Cada una es una medida que se añadió sin decir para qué sirve.
`;

fs.writeFileSync(SALIDA, doc, 'utf8');
console.log(`Escrito ${path.relative(RAIZ, SALIDA)}`);
console.log(`  ${cuentas.anotadas} secuencias anotadas · ${cuentas.legadas} con vocabulario legado`);
const invisibles = inventario.filter((r) => r.cuantas > 0 && !r.enFicha);
console.log(
	invisibles.length === 0
		? '  Todo lo registrado llega a la ficha.'
		: `  No llegan a la ficha: ${invisibles.map((r) => r.nombre).join('; ')}`
);
