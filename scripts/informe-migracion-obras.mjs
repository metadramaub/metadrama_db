/**
 * Informe de migración por obra.
 *
 * Escribe un documento por obra con secuencias métricas, diciendo para cada una qué forma y
 * arquitectura del catálogo nuevo le corresponden y **cómo se ha llegado a esa
 * correspondencia**, para poder revisarlo con quien anotó la obra.
 *
 * Se genera, no se escribe a mano: cada decisión que se toma sobre el catálogo lo cambia, y
 * un documento escrito a mano caducaría el mismo día.
 *
 * Uso:
 *   node scripts/informe-migracion-obras.mjs                  # vuelca la base enlazada
 *   node scripts/informe-migracion-obras.mjs --dump copia.sql
 *   node scripts/informe-migracion-obras.mjs --salida docs/dominio-metrico/migracion
 */

import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dumpLinkedDatabase, readDump } from './lib/volcado.mjs';

const SALIDA_POR_DEFECTO = fileURLToPath(
	new URL('../docs/dominio-metrico/migracion', import.meta.url)
);

/** Entidades del catálogo que pueden declarar de qué término legado salieron. */
const TABLAS_CON_ORIGEN = [
	'formas_metricas',
	'arquitecturas_forma',
	'esquemas_rima',
	'esquemas_metricos',
	'rasgo_valores',
	'denominaciones_metricas',
	'repeticiones_metricas',
	'metros',
	'variedades_arquitectura'
];

function parseArguments(argv) {
	const options = { dump: null, salida: SALIDA_POR_DEFECTO };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--dump') options.dump = argv[index + 1] ?? null;
		if (argv[index] === '--salida') options.salida = argv[index + 1] ?? options.salida;
	}
	return options;
}

// --------------------------------------------------------------------------
// Resolución de la equivalencia
// --------------------------------------------------------------------------

function construir(tables) {
	const t = (name) => tables.get(name) ?? [];

	const vocabulario = new Map(t('vocabularios').map((row) => [row.termino_id, row]));
	const formas = new Map(t('formas_metricas').map((row) => [row.forma_id, row]));
	const arquitecturas = t('arquitecturas_forma');

	// Quién reclama cada término legado, y con qué entidad.
	const reclamado = new Map();
	for (const tabla of TABLAS_CON_ORIGEN) {
		for (const row of t(tabla)) {
			if (row.origen_termino_id) reclamado.set(row.origen_termino_id, { tabla, row });
		}
	}
	// Una forma que reutiliza el UUID del término legado también lo reclama.
	for (const forma of formas.values()) {
		if (vocabulario.has(forma.forma_id) && !reclamado.has(forma.forma_id)) {
			reclamado.set(forma.forma_id, { tabla: 'formas_metricas', row: forma });
		}
	}

	const arquitecturaPrincipal = new Map();
	for (const arquitectura of arquitecturas) {
		if (arquitectura.activo === false) continue;
		const actual = arquitecturaPrincipal.get(arquitectura.forma_id);
		if (!actual || arquitectura.principal === true) {
			arquitecturaPrincipal.set(arquitectura.forma_id, arquitectura);
		}
	}

	/** La forma a la que apunta una entidad del catálogo, sea cual sea su tabla. */
	function formaDe(entrada) {
		if (!entrada) return null;
		const { tabla, row } = entrada;
		if (tabla === 'formas_metricas') return row;
		if (row.forma_id) return formas.get(row.forma_id) ?? null;
		if (row.arquitectura_id) {
			const arquitectura = arquitecturas.find((a) => a.arquitectura_id === row.arquitectura_id);
			return arquitectura ? (formas.get(arquitectura.forma_id) ?? null) : null;
		}
		return null;
	}

	function arquitecturaDe(entrada, forma) {
		if (!entrada) return null;
		const { tabla, row } = entrada;
		if (tabla === 'arquitecturas_forma') return row;
		if (row.arquitectura_id) {
			return arquitecturas.find((a) => a.arquitectura_id === row.arquitectura_id) ?? null;
		}
		return forma ? (arquitecturaPrincipal.get(forma.forma_id) ?? null) : null;
	}

	const rasgos = new Map(t('rasgos_metricos').map((row) => [row.rasgo_id, row.nombre]));

	/** Qué aporta la entidad que reclama un término: a veces una forma, a veces solo un rasgo. */
	function detalleDe(entrada) {
		if (entrada.tabla === 'rasgo_valores') {
			const rasgo = rasgos.get(entrada.row.rasgo_id);
			return `${rasgo ?? 'rasgo'} = ${entrada.row.nombre ?? entrada.row.slug}`;
		}
		if (entrada.tabla === 'esquemas_rima') return `esquema de rima «${entrada.row.nombre}»`;
		if (entrada.tabla === 'esquemas_metricos') return `esquema métrico «${entrada.row.nombre}»`;
		if (entrada.tabla === 'variedades_arquitectura') return `variedad «${entrada.row.nombre}»`;
		if (entrada.tabla === 'repeticiones_metricas') return `repetición «${entrada.row.nombre}»`;
		return null;
	}

	/** Sube por la jerarquía hasta el primer ascendiente que aporte una forma. */
	function formaPorAscendencia(terminoId) {
		let actual = vocabulario.get(terminoId);
		let saltos = 0;
		while (actual?.termino_padre_id && saltos < 8) {
			actual = vocabulario.get(actual.termino_padre_id);
			saltos += 1;
			if (!actual) break;
			const heredado = reclamado.get(actual.termino_id);
			const forma = formaDe(heredado);
			if (forma) return { forma, arquitectura: arquitecturaDe(heredado, forma), desde: actual.termino };
		}
		return null;
	}

	/**
	 * Cómo se resuelve un término legado:
	 *   directa      — algo del catálogo lo reclama y de ahí sale la forma;
	 *   rasgo        — lo reclama un rasgo o un esquema, que no dice forma: esa viene del padre.
	 *                  Es el caso de los romances, cuyo término codifica la asonancia;
	 *   ascendencia  — no lo reclama nadie, pero un ascendiente sí. Da forma y arquitectura,
	 *                  no las respuestas;
	 *   sin_destino  — nadie lo reclama en toda su línea;
	 *   sin_tipo     — la secuencia no declara forma.
	 */
	function resolver(terminoId) {
		if (!terminoId) return { via: 'sin_tipo' };

		const directo = reclamado.get(terminoId);
		if (directo) {
			const forma = formaDe(directo);
			if (forma) {
				return { via: 'directa', forma, arquitectura: arquitecturaDe(directo, forma) };
			}
			// Lo reclamado no es una forma: hay que buscarla arriba y quedarse con el detalle.
			const heredado = formaPorAscendencia(terminoId);
			return {
				via: 'rasgo',
				forma: heredado?.forma ?? null,
				arquitectura: heredado?.arquitectura ?? null,
				desde: heredado?.desde ?? null,
				detalle: detalleDe(directo)
			};
		}

		const heredado = formaPorAscendencia(terminoId);
		if (heredado) return { via: 'ascendencia', ...heredado };
		return { via: 'sin_destino' };
	}

	return { t, vocabulario, resolver };
}

// --------------------------------------------------------------------------
// Redacción
// --------------------------------------------------------------------------

const ETIQUETA_VIA = {
	directa: 'directa',
	rasgo: 'rasgo + forma del padre',
	ascendencia: 'por ascendencia',
	sin_destino: '**sin destino**',
	sin_tipo: '**no declara forma**'
};

function slugify(texto) {
	return String(texto)
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.slice(0, 80);
}

function informeDeObra({ obra, secuencias, t, vocabulario, resolver, editor, fecha }) {
	const nombre = (id) => vocabulario.get(id)?.termino ?? null;
	const idsSecuencia = new Set(secuencias.map((s) => s.secuencia_id));
	const subtipos = t('secuencias_subtipos_estrofa').filter((r) => idsSecuencia.has(r.secuencia_id));
	const caracterizaciones = t('secuencias_caracterizaciones_rango').filter((r) =>
		idsSecuencia.has(r.secuencia_id)
	);

	const resueltas = secuencias.map((secuencia) => ({
		secuencia,
		resultado: resolver(secuencia.estrofa_tipo_id)
	}));
	const cuenta = { directa: 0, rasgo: 0, ascendencia: 0, sin_destino: 0, sin_tipo: 0 };
	for (const fila of resueltas) cuenta[fila.resultado.via] += 1;

	const dudas = resueltas.filter(
		(fila) => fila.resultado.via === 'sin_destino' || fila.resultado.via === 'sin_tipo'
	);
	const porAscendencia = resueltas.filter((fila) => fila.resultado.via === 'ascendencia');

	const lineas = [];
	lineas.push(`# Migración métrica · ${obra.titulo}`);
	lineas.push('');
	lineas.push(`Generado el ${fecha} por \`npm run migracion:informe\`. **No editar a mano:**`);
	lineas.push('se regenera y se pierde lo escrito. Las decisiones van a');
	lineas.push('[equivalencias pendientes](../equivalencias-pendientes.md).');
	lineas.push('');
	lineas.push(`- **Editor asignado:** ${editor ?? '—'}`);
	lineas.push(`- **Secuencias métricas:** ${secuencias.length}`);
	lineas.push(`- **Subtipos estróficos:** ${subtipos.length}`);
	lineas.push(`- **Caracterizaciones por rango:** ${caracterizaciones.length}`);
	lineas.push('');

	// Lo primero es saber si hay que llamar a alguien.
	if (dudas.length === 0 && porAscendencia.length === 0) {
		lineas.push('## Nada que consultar');
		lineas.push('');
		lineas.push('Todas las secuencias resuelven su equivalencia de forma directa.');
	} else {
		lineas.push('## Qué hay que consultar');
		lineas.push('');
		if (dudas.length > 0) {
			lineas.push(
				`- **${dudas.length} secuencia(s) sin equivalencia.** Es lo que hay que decidir con el editor.`
			);
		}
		if (porAscendencia.length > 0) {
			lineas.push(
				`- **${porAscendencia.length} secuencia(s) resueltas por ascendencia.** La forma y la arquitectura`
			);
			lineas.push(
				'  se heredan del término padre, pero las respuestas concretas —pareados, dístico final,'
			);
			lineas.push('  encadenamiento— no se deducen y las tiene que confirmar quien anotó.');
		}
	}
	lineas.push('');
	lineas.push(
		`Resolución: ${cuenta.directa} directas · ${cuenta.rasgo} con rasgo propio · ` +
			`${cuenta.ascendencia} por ascendencia · ${cuenta.sin_destino} sin destino · ` +
			`${cuenta.sin_tipo} sin forma declarada.`
	);
	lineas.push('');

	if (dudas.length > 0) {
		lineas.push('## Dudas, una por una');
		lineas.push('');
		lineas.push('| Versos | Término actual | Qué pasa |');
		lineas.push('| --- | --- | --- |');
		for (const { secuencia, resultado } of dudas.sort((a, b) => a.secuencia.v_ini - b.secuencia.v_ini)) {
			const termino = nombre(secuencia.estrofa_tipo_id);
			const que =
				resultado.via === 'sin_tipo'
					? 'La secuencia no declara ninguna forma métrica.'
					: `\`${termino}\` no tiene equivalencia en el catálogo nuevo, ni él ni ningún ascendiente suyo.`;
			lineas.push(
				`| ${secuencia.v_ini}–${secuencia.v_fin} (${secuencia.n_versos} v) | ${termino ? `\`${termino}\`` : '—'} | ${que} |`
			);
		}
		lineas.push('');
	}

	lineas.push('## Secuencias');
	lineas.push('');
	lineas.push('| Versos | v | Término actual | Forma propuesta | Arquitectura | Además | Vía |');
	lineas.push('| --- | ---: | --- | --- | --- | --- | --- |');
	for (const { secuencia, resultado } of resueltas.sort((a, b) => a.secuencia.v_ini - b.secuencia.v_ini)) {
		const termino = nombre(secuencia.estrofa_tipo_id);
		const via =
			resultado.via === 'ascendencia'
				? `por ascendencia (${resultado.desde})`
				: ETIQUETA_VIA[resultado.via];
		lineas.push(
			`| ${secuencia.v_ini}–${secuencia.v_fin} | ${secuencia.n_versos} | ${termino ? `\`${termino}\`` : '—'} | ` +
				`${resultado.forma?.nombre ?? '—'} | ${resultado.arquitectura?.nombre ?? '—'} | ` +
				`${resultado.detalle ?? '—'} | ${via} |`
		);
	}
	lineas.push('');

	if (subtipos.length > 0) {
		const porTermino = new Map();
		for (const fila of subtipos) {
			const clave = nombre(fila.subtipo_estrofa_id) ?? '(sin término)';
			porTermino.set(clave, (porTermino.get(clave) ?? 0) + 1);
		}
		lineas.push('## Subtipos estróficos');
		lineas.push('');
		lineas.push(
			'Pasan a ser unidades y secciones del modelo nuevo. La correspondencia de término existe;'
		);
		lineas.push('lo que hay que revisar es la estructura, no el nombre.');
		lineas.push('');
		lineas.push('| Subtipo | Rangos |');
		lineas.push('| --- | ---: |');
		for (const [clave, total] of [...porTermino].sort((a, b) => b[1] - a[1])) {
			lineas.push(`| \`${clave}\` | ${total} |`);
		}
		lineas.push('');
	}

	if (caracterizaciones.length > 0) {
		const porTipo = new Map();
		for (const fila of caracterizaciones) {
			const clave = nombre(fila.tipo_caracterizacion_rango_id) ?? '(sin tipo)';
			porTipo.set(clave, (porTipo.get(clave) ?? 0) + 1);
		}
		lineas.push('## Caracterizaciones por rango');
		lineas.push('');
		lineas.push(
			'Buena parte de estas no son caracterizaciones sino **desviaciones**, y en el modelo nuevo'
		);
		lineas.push(
			'se registran como tales. Las de medida —hipometría e hipermetría— no conservan el número'
		);
		lineas.push('de sílabas observado, así que hay que revisarlas con quien las anotó.');
		lineas.push('');
		lineas.push('| Tipo | Rangos |');
		lineas.push('| --- | ---: |');
		for (const [clave, total] of [...porTipo].sort((a, b) => b[1] - a[1])) {
			lineas.push(`| \`${clave}\` | ${total} |`);
		}
		lineas.push('');
	}

	return lineas.join('\n');
}

// --------------------------------------------------------------------------
// Ejecución
// --------------------------------------------------------------------------

const options = parseArguments(process.argv.slice(2));
const tables = readDump(options.dump ?? dumpLinkedDatabase());
const { t, vocabulario, resolver } = construir(tables);

const fecha = new Date().toISOString().slice(0, 10);
const editores = new Map(
	t('editores').map((row) => [
		row.user_id,
		row.nombre_completo ?? row.nombre ?? row.email ?? row.user_id
	])
);

const secuenciasPorObra = new Map();
for (const secuencia of t('secuencias_metricas')) {
	const lista = secuenciasPorObra.get(secuencia.obra_id) ?? [];
	lista.push(secuencia);
	secuenciasPorObra.set(secuencia.obra_id, lista);
}

const obras = t('obras')
	.filter((obra) => secuenciasPorObra.has(obra.obra_id))
	.sort((a, b) => a.titulo.localeCompare(b.titulo, 'es'));

mkdirSync(options.salida, { recursive: true });
// Una obra que deja de tener secuencias no debe dejar su informe atrás mintiendo.
for (const fichero of readdirSync(options.salida)) {
	if (fichero.endsWith('.md') && fichero !== 'README.md') {
		rmSync(join(options.salida, fichero));
	}
}

const resumen = [];
for (const obra of obras) {
	const secuencias = secuenciasPorObra.get(obra.obra_id);
	const editor = editores.get(obra.editor_asignado) ?? null;
	const texto = informeDeObra({ obra, secuencias, t, vocabulario, resolver, editor, fecha });
	const fichero = `${slugify(obra.titulo)}.md`;
	writeFileSync(join(options.salida, fichero), `${texto}\n`, 'utf-8');

	const cuenta = { directa: 0, rasgo: 0, ascendencia: 0, sin_destino: 0, sin_tipo: 0 };
	for (const secuencia of secuencias) cuenta[resolver(secuencia.estrofa_tipo_id).via] += 1;
	resumen.push({ obra, editor, fichero, cuenta, total: secuencias.length });
}

// Índice, para saber a quién hay que llamar sin abrir once ficheros.
const indice = [];
indice.push('# Migración métrica, obra por obra');
indice.push('');
indice.push(`Generado el ${fecha} por \`npm run migracion:informe\`. **No editar a mano.**`);
indice.push('');
indice.push('Un documento por obra con secuencias métricas, para revisar con quien la anotó.');
indice.push('Las decisiones que salgan de esas revisiones van a');
indice.push('[equivalencias pendientes](../equivalencias-pendientes.md), que es el documento vivo.');
indice.push('');
indice.push('| Obra | Editor | Secs | Directas | Rasgo | Ascend. | Dudas |');
indice.push('| --- | --- | ---: | ---: | ---: | ---: | ---: |');
for (const fila of resumen.sort(
	(a, b) =>
		b.cuenta.sin_destino + b.cuenta.sin_tipo - (a.cuenta.sin_destino + a.cuenta.sin_tipo) ||
		b.cuenta.ascendencia - a.cuenta.ascendencia ||
		b.total - a.total
)) {
	const dudas = fila.cuenta.sin_destino + fila.cuenta.sin_tipo;
	indice.push(
		`| [${fila.obra.titulo}](./${fila.fichero}) | ${fila.editor ?? '—'} | ${fila.total} | ` +
			`${fila.cuenta.directa} | ${fila.cuenta.rasgo} | ${fila.cuenta.ascendencia} | ` +
			`${dudas > 0 ? `**${dudas}**` : '—'} |`
	);
}
indice.push('');
const totales = resumen.reduce(
	(acumulado, fila) => ({
		total: acumulado.total + fila.total,
		directa: acumulado.directa + fila.cuenta.directa,
		rasgo: acumulado.rasgo + fila.cuenta.rasgo,
		ascendencia: acumulado.ascendencia + fila.cuenta.ascendencia,
		dudas: acumulado.dudas + fila.cuenta.sin_destino + fila.cuenta.sin_tipo
	}),
	{ total: 0, directa: 0, rasgo: 0, ascendencia: 0, dudas: 0 }
);
indice.push(
	`**${totales.total} secuencias en ${resumen.length} obras:** ${totales.directa} directas, ` +
		`${totales.rasgo} con rasgo propio, ${totales.ascendencia} por ascendencia, ` +
		`${totales.dudas} por decidir.`
);
writeFileSync(join(options.salida, 'README.md'), `${indice.join('\n')}\n`, 'utf-8');

console.log(`${resumen.length} informes escritos en ${options.salida}`);
console.log(
	`${totales.total} secuencias · ${totales.directa} directas · ${totales.rasgo} con rasgo · ` +
		`${totales.ascendencia} por ascendencia · ${totales.dudas} por decidir`
);
