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
 * **La equivalencia no se calcula aquí.** La resuelve la vista `propuesta_metrica_secuencia`,
 * la misma que consume la anotación en sombra del dashboard. Antes este script llevaba su
 * propia copia de las reglas y había que mantener las dos a la vez; ahora hay una sola
 * fuente, y cambiar la vista cambia los dos sitios.
 *
 * Uso:
 *   node scripts/informe-migracion-obras.mjs
 *   node scripts/informe-migracion-obras.mjs --salida docs/dominio-metrico/migracion
 */

import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const SALIDA_POR_DEFECTO = fileURLToPath(
	new URL('../docs/dominio-metrico/migracion', import.meta.url)
);

function parseArguments(argv) {
	const options = { salida: SALIDA_POR_DEFECTO };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--salida') options.salida = argv[index + 1] ?? options.salida;
	}
	return options;
}

// --------------------------------------------------------------------------
// Datos
// --------------------------------------------------------------------------

/** Una fila por secuencia real, ya resuelta por la vista. */
const SQL_SECUENCIAS = `
	select
		p.secuencia_id, p.obra_id, o.titulo as obra_titulo,
		e.nombre_completo as editor,
		p.v_ini, p.v_fin, s.n_versos,
		p.termino_legado, p.forma_propuesta, p.arquitectura_propuesta_id,
		p.arquitectura_propuesta, p.via, p.detalle, p.heredado_de,
		p.longitud_compatible, p.motivo_revision,
		a.unidad_versos_min, a.unidad_versos_max
	from public.propuesta_metrica_secuencia p
	join public.secuencias_metricas s on s.secuencia_id = p.secuencia_id
	join public.obras o on o.obra_id = p.obra_id
	left join public.editores e on e.user_id = o.editor_asignado
	left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
	order by o.titulo, p.v_ini
`;

const SQL_SUBTIPOS = `
	select sse.secuencia_id, v.termino, sse.v_ini, sse.v_fin
	from public.secuencias_subtipos_estrofa sse
	left join public.vocabularios v on v.termino_id = sse.subtipo_estrofa_id
	order by sse.v_ini
`;

const SQL_CARACTERIZACIONES = `
	select scr.secuencia_id, v.termino, scr.v_ini, scr.v_fin
	from public.secuencias_caracterizaciones_rango scr
	left join public.vocabularios v on v.termino_id = scr.tipo_caracterizacion_rango_id
	order by scr.v_ini
`;

const SQL_JORNADAS = `select obra_id, v_ini, v_fin from public.jornadas`;

/**
 * Qué le pide el catálogo nuevo a cada arquitectura. Solo lo obligatorio: no responder al final
 * acentual o al dístico final no deja ningún hueco, y contarlas como huecos daba un retrato mucho
 * peor que el real.
 */
const SQL_PREGUNTAS = `
	select g.arquitectura_id, g.grupo_eleccion_id, g.nombre, g.alcance
	from public.grupos_eleccion_metrica_resueltos g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where g.activo and a.activo and g.selecciones_min >= 1
`;

/**
 * Lo que la migración ya sabe responder, y de dónde lo saca: `anotada` es lo que alguien miró
 * verso a verso y se traslada; `derivada` se deduce del término legado y hay que revisarlo.
 */
const SQL_RESPUESTAS = `
	select secuencia_id, grupo_eleccion_id, alcance, origen, count(*) as filas,
		count(distinct unidad_v_ini) as estrofas
	from public.propuesta_elecciones_secuencia
	group by 1, 2, 3, 4
`;

// --------------------------------------------------------------------------
// Redacción
// --------------------------------------------------------------------------

/**
 * Los subtipos y las caracterizaciones de una secuencia, con su rango cuando no la ocupan entera.
 *
 * **El rango importa y por eso no se resume.** Una hipometría es de un verso concreto y una prosa
 * ocupa un tramo: decir solo «hipométrico» obligaría a volver a la base justo para lo que hay que
 * revisar con quien lo anotó.
 */
function enumerarRangos(filas, secuencia) {
	if (!filas || filas.length === 0) return '—';
	return filas
		.map((fila) => {
			const cubreLaSecuencia =
				Number(fila.v_ini) === Number(secuencia.v_ini) &&
				Number(fila.v_fin) === Number(secuencia.v_fin);
			const nombre = fila.termino ? `\`${fila.termino}\`` : '—';
			return cubreLaSecuencia ? nombre : `${nombre} (${fila.v_ini}–${fila.v_fin})`;
		})
		.join('<br>');
}

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

function contar(filas, clave) {
	const cuenta = new Map();
	for (const fila of filas) {
		const valor = fila[clave] ?? '(sin término)';
		cuenta.set(valor, (cuenta.get(valor) ?? 0) + 1);
	}
	return [...cuenta].sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0]), 'es'));
}

/**
 * Tramos que el modelo viejo obligó a partir y el nuevo recoge como una sola secuencia.
 *
 * El criterio lo da la propia arquitectura. Si declara la extensión de su unidad —una
 * quintilla son cinco versos, un sexteto-lira seis—, el pasaje se compone de unidades
 * repetidas y lo que varía entre ellas es una respuesta por unidad: cuatro sextetos-lira
 * seguidos con esquemas distintos son **una** secuencia de cuatro unidades. Si la unidad no
 * tiene extensión declarada —romance, silva—, la secuencia *es* la unidad y su norma vale
 * para todo el tramo: dos romances contiguos con asonancia distinta son dos tiradas y no se
 * tocan.
 *
 * Se respeta además la frontera de jornada: partir ahí es una decisión editorial, no un
 * artefacto del vocabulario.
 */
function tramosFundibles(secuencias, jornadas) {
	const cortes = new Set(jornadas.map((jornada) => Number(jornada.v_fin)));
	const tramos = [];
	let actual = [];

	const cerrar = () => {
		if (actual.length > 1) tramos.push(actual);
		actual = [];
	};

	for (const fila of secuencias) {
		const unidadAcotada = fila.unidad_versos_min != null && fila.unidad_versos_max != null;
		if (!unidadAcotada) {
			cerrar();
			continue;
		}
		if (actual.length === 0) {
			actual = [fila];
			continue;
		}
		const anterior = actual[actual.length - 1];
		const contigua = Number(fila.v_ini) === Number(anterior.v_fin) + 1;
		const mismaArquitectura =
			anterior.arquitectura_propuesta_id === fila.arquitectura_propuesta_id;
		const cruzaJornada = cortes.has(Number(anterior.v_fin));

		if (contigua && mismaArquitectura && !cruzaJornada) actual.push(fila);
		else {
			cerrar();
			actual = [fila];
		}
	}
	cerrar();
	return tramos;
}

function informeDeObra({
	titulo,
	editor,
	secuencias,
	subtipos,
	caracterizaciones,
	jornadas,
	fecha
}) {
	const cuenta = {
		directa: 0,
		rasgo: 0,
		ascendencia: 0,
		sin_destino: 0,
		sin_tipo: 0,
		revision_longitud: 0
	};
	for (const fila of secuencias) cuenta[fila.via] = (cuenta[fila.via] ?? 0) + 1;
	cuenta.revision_longitud = secuencias.filter((fila) => fila.motivo_revision).length;

	const dudas = secuencias.filter(
		(fila) => fila.via === 'sin_destino' || fila.via === 'sin_tipo' || fila.motivo_revision
	);
	const porAscendencia = secuencias.filter((fila) => fila.via === 'ascendencia');
	const fundibles = tramosFundibles(secuencias, jornadas);

	const lineas = [];
	lineas.push(`# Migración métrica · ${titulo}`);
	lineas.push('');
	lineas.push(`Generado el ${fecha} por \`npm run migracion:informe\`. **No editar a mano:**`);
	lineas.push('se regenera y se pierde lo escrito. El procedimiento está en');
	lineas.push('[cómo se migra una obra](../como-se-migra-una-obra.md) y las decisiones van a');
	lineas.push('[equivalencias pendientes](../equivalencias-pendientes.md).');
	lineas.push('');
	lineas.push(`- **Editor asignado:** ${editor ?? '—'}`);
	lineas.push(`- **Secuencias métricas:** ${secuencias.length}`);
	lineas.push(`- **Subtipos estróficos:** ${subtipos.length}`);
	lineas.push(`- **Caracterizaciones por rango:** ${caracterizaciones.length}`);
	lineas.push('');

	if (dudas.length === 0 && porAscendencia.length === 0 && fundibles.length === 0) {
		lineas.push('## Nada que consultar');
		lineas.push('');
		lineas.push('La equivalencia de todas las secuencias se resuelve sin ambigüedad.');
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
		if (fundibles.length > 0) {
			const total = fundibles.reduce((suma, tramo) => suma + tramo.length, 0);
			lineas.push(
				`- **${total} secuencias que pasan a ser ${fundibles.length}.** El vocabulario viejo obligaba a`
			);
			lineas.push(
				'  partirlas porque el esquema cambiaba de estrofa a estrofa; en el modelo nuevo son una sola'
			);
			lineas.push('  secuencia con varias unidades. Conviene confirmarlo antes de fundirlas.');
		}
	}
	lineas.push('');
	lineas.push(
		`Resolución: ${cuenta.directa} directas · ${cuenta.rasgo} con rasgo propio · ` +
			`${cuenta.ascendencia} por ascendencia · ${cuenta.sin_destino} sin destino · ` +
			`${cuenta.sin_tipo} sin forma declarada · ${cuenta.revision_longitud} con longitud por revisar.`
	);
	lineas.push('');

	if (fundibles.length > 0) {
		lineas.push('## Secuencias que se funden en una');
		lineas.push('');
		lineas.push(
			'Cada tramo pasa a ser **una** secuencia con tantas unidades como tenía de secuencias, y lo'
		);
		lineas.push(
			'que las distinguía se conserva como respuesta de cada unidad. Es lo mismo que ya se hacía'
		);
		lineas.push('con las quintillas.');
		lineas.push('');
		for (const tramo of fundibles) {
			const desde = Number(tramo[0].v_ini);
			const hasta = Number(tramo[tramo.length - 1].v_fin);
			const unidad = Number(tramo[0].unidad_versos_min);
			const versos = hasta - desde + 1;
			const unidades = versos / unidad;
			lineas.push(
				`**vv. ${desde}–${hasta}** → ${tramo[0].forma_propuesta} · ${tramo[0].arquitectura_propuesta}` +
					` — ${tramo.length} secuencias en una, con ` +
					(Number.isInteger(unidades) ? `${unidades}` : `¿${versos} / ${unidad}?`) +
					` unidades de ${unidad} versos`
			);
			lineas.push('');
			lineas.push('| Versos | v | Término actual | Pasa a ser |');
			lineas.push('| --- | ---: | --- | --- |');
			for (const fila of tramo) {
				lineas.push(
					`| ${fila.v_ini}–${fila.v_fin} | ${fila.n_versos} | ` +
						`${fila.termino_legado ? `\`${fila.termino_legado}\`` : '—'} | ` +
						`unidad con ${fila.detalle ?? 'su propia respuesta'} |`
				);
			}
			lineas.push('');
			if (!Number.isInteger(unidades)) {
				lineas.push(
					`> El tramo mide ${versos} versos y la unidad ${unidad}: no es múltiplo exacto, así que hay`
				);
				lineas.push('> algo que revisar antes de fundirlo.');
				lineas.push('');
			}
		}
	}

	if (dudas.length > 0) {
		lineas.push('## Dudas, una por una');
		lineas.push('');
		lineas.push('| Versos | Término actual | Qué pasa |');
		lineas.push('| --- | --- | --- |');
		for (const fila of dudas) {
			const que = fila.motivo_revision
				? fila.motivo_revision
				: fila.via === 'sin_tipo'
					? 'La secuencia no declara ninguna forma métrica.'
					: `\`${fila.termino_legado}\` no tiene equivalencia en el catálogo nuevo, ni él ni ningún ascendiente suyo.`;
			lineas.push(
				`| ${fila.v_ini}–${fila.v_fin} (${fila.n_versos} v) | ` +
					`${fila.termino_legado ? `\`${fila.termino_legado}\`` : '—'} | ${que} |`
			);
		}
		lineas.push('');
	}

	const incompletas = secuencias.filter((fila) => fila.faltan?.length > 0);
	if (incompletas.length > 0) {
		lineas.push('## Lo que hay que completar');
		lineas.push('');
		lineas.push(
			`**${incompletas.length} de ${secuencias.length} secuencias** llegan al editor con algo sin`
		);
		lineas.push(
			'responder. El resto se puede aceptar de un vistazo. Lo que falta aquí no lo arregla ninguna'
		);
		lineas.push('equivalencia: es lectura del texto.');
		lineas.push('');
		lineas.push('| Versos | Forma | Estrofas | Qué falta |');
		lineas.push('| --- | --- | ---: | --- |');
		for (const fila of incompletas) {
			const unidad = Number(fila.unidad_versos_min);
			const estrofas = unidad > 0 ? Math.floor(Number(fila.n_versos) / unidad) : '—';
			lineas.push(
				`| ${fila.v_ini}–${fila.v_fin} | ${fila.forma_propuesta ?? '—'} | ${estrofas} | ` +
					`${fila.faltan.join(', ')} |`
			);
		}
		lineas.push('');
	}

	// Se indexan por secuencia una sola vez: la tabla los mira fila a fila.
	const subtiposPorSecuencia = new Map();
	for (const fila of subtipos) {
		const lista = subtiposPorSecuencia.get(fila.secuencia_id) ?? [];
		lista.push(fila);
		subtiposPorSecuencia.set(fila.secuencia_id, lista);
	}
	const caracterizacionesPorSecuencia = new Map();
	for (const fila of caracterizaciones) {
		const lista = caracterizacionesPorSecuencia.get(fila.secuencia_id) ?? [];
		lista.push(fila);
		caracterizacionesPorSecuencia.set(fila.secuencia_id, lista);
	}

	lineas.push('## Secuencias');
	lineas.push('');
	lineas.push(
		'**Todo lo que la obra tiene anotado de cada secuencia**, salvo la sinopsis y los comentarios'
	);
	lineas.push(
		'internos: así se puede recorrer la migración con el editor sin consultar la base. Los subtipos'
	);
	lineas.push(
		'y las caracterizaciones llevan su rango entre paréntesis cuando no ocupan la secuencia entera.'
	);
	lineas.push('');
	lineas.push(
		'La columna **Propuesta** dice qué trae ya puesto el editor: lo *anotado* se miró verso a verso'
	);
	lineas.push(
		'en su día y se traslada tal cual; lo *derivado* se deduce del término legado y hay que revisarlo.'
	);
	lineas.push('');
	lineas.push(
		'| # | Versos | v | Término actual | Forma propuesta | Arquitectura | Subtipos | Caracterizaciones | Estado | Propuesta | Vía |'
	);
	lineas.push('| ---: | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |');
	let numero = 0;
	for (const fila of secuencias) {
		numero += 1;
		const via =
			fila.via === 'ascendencia' ? `por ascendencia (${fila.heredado_de})` : ETIQUETA_VIA[fila.via];
		const estado = fila.motivo_revision
			? `**Revisar:** ${fila.motivo_revision}`
			: fila.faltan?.length > 0
				? `**falta:** ${fila.faltan.join(', ')}`
				: fila.estado;
		const plural = (n, singular, plural_) => `${n} ${n === 1 ? singular : plural_}`;
		const propuesta =
			[
				fila.anotadas > 0 ? plural(fila.anotadas, 'anotada', 'anotadas') : null,
				fila.derivadas > 0 ? plural(fila.derivadas, 'derivada', 'derivadas') : null
			]
				.filter(Boolean)
				.join(' · ') || '—';
		lineas.push(
			`| ${numero} | ${fila.v_ini}–${fila.v_fin} | ${fila.n_versos} | ` +
				`${fila.termino_legado ? `\`${fila.termino_legado}\`` : '—'} | ` +
				`${fila.forma_propuesta ?? '—'} | ${fila.arquitectura_propuesta ?? '—'} | ` +
				`${enumerarRangos(subtiposPorSecuencia.get(fila.secuencia_id), fila)} | ` +
				`${enumerarRangos(caracterizacionesPorSecuencia.get(fila.secuencia_id), fila)} | ` +
				`${estado} | ${propuesta} | ${via} |`
		);
	}
	lineas.push('');

	if (subtipos.length > 0) {
		lineas.push('## Subtipos estróficos');
		lineas.push('');
		lineas.push(
			'Pasan a ser unidades y secciones del modelo nuevo. La correspondencia de término existe;'
		);
		lineas.push('lo que hay que revisar es la estructura, no el nombre.');
		lineas.push('');
		lineas.push('| Subtipo | Rangos |');
		lineas.push('| --- | ---: |');
		for (const [clave, total] of contar(subtipos, 'termino')) {
			lineas.push(`| \`${clave}\` | ${total} |`);
		}
		lineas.push('');
	}

	if (caracterizaciones.length > 0) {
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
		for (const [clave, total] of contar(caracterizaciones, 'termino')) {
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

const secuencias = query(SQL_SECUENCIAS);
const subtipos = query(SQL_SUBTIPOS);
const caracterizaciones = query(SQL_CARACTERIZACIONES);
const jornadas = query(SQL_JORNADAS);
const preguntas = query(SQL_PREGUNTAS);
const respuestas = query(SQL_RESPUESTAS);

// --------------------------------------------------------------------------
// Qué le falta a cada secuencia
//
// El informe decía «directa · —» de una redondilla sin disposición, que es justo el agujero que
// el editor tiene que tapar. Aquí se cruza lo que el catálogo pide con lo que la migración sabe
// responder, y cada secuencia queda con su estado y con el nombre de lo que le falta.
// --------------------------------------------------------------------------

const preguntasPorArquitectura = new Map();
for (const fila of preguntas) {
	const lista = preguntasPorArquitectura.get(fila.arquitectura_id) ?? [];
	lista.push(fila);
	preguntasPorArquitectura.set(fila.arquitectura_id, lista);
}

const respuestasPorSecuencia = new Map();
for (const fila of respuestas) {
	const lista = respuestasPorSecuencia.get(fila.secuencia_id) ?? [];
	lista.push(fila);
	respuestasPorSecuencia.set(fila.secuencia_id, lista);
}

for (const fila of secuencias) {
	const pedidas = preguntasPorArquitectura.get(fila.arquitectura_propuesta_id) ?? [];
	const dadas = respuestasPorSecuencia.get(fila.secuencia_id) ?? [];
	const respondidas = new Set(dadas.map((r) => r.grupo_eleccion_id));

	fila.faltan = pedidas.filter((p) => !respondidas.has(p.grupo_eleccion_id)).map((p) => p.nombre);
	fila.anotadas = dadas
		.filter((r) => r.origen === 'anotada')
		.reduce((total, r) => total + Number(r.filas), 0);
	fila.derivadas = dadas
		.filter((r) => r.origen === 'derivada')
		.reduce((total, r) => total + Number(r.filas), 0);
	fila.estrofasPropuestas = Math.max(
		0,
		...dadas.filter((r) => r.alcance === 'unidad').map((r) => Number(r.estrofas))
	);

	fila.estado = !fila.arquitectura_propuesta_id
		? 'sin arquitectura'
		: fila.faltan.length > 0
			? 'incompleta'
			: fila.anotadas > 0
				? 'lista · con anotación'
				: 'lista';
}

const agrupar = (filas, clave) => {
	const grupos = new Map();
	for (const fila of filas) {
		const lista = grupos.get(fila[clave]) ?? [];
		lista.push(fila);
		grupos.set(fila[clave], lista);
	}
	return grupos;
};

const secuenciasPorObra = agrupar(secuencias, 'obra_id');
const jornadasPorObra = agrupar(jornadas, 'obra_id');
const secuenciaAObra = new Map(secuencias.map((fila) => [fila.secuencia_id, fila.obra_id]));

const porObra = (filas) => {
	const grupos = new Map();
	for (const fila of filas) {
		const obraId = secuenciaAObra.get(fila.secuencia_id);
		if (!obraId) continue;
		const lista = grupos.get(obraId) ?? [];
		lista.push(fila);
		grupos.set(obraId, lista);
	}
	return grupos;
};
const subtiposPorObra = porObra(subtipos);
const caracterizacionesPorObra = porObra(caracterizaciones);

const fecha = new Date().toISOString().slice(0, 10);

mkdirSync(options.salida, { recursive: true });
// Una obra que deja de tener secuencias no debe dejar su informe atrás mintiendo.
for (const fichero of readdirSync(options.salida)) {
	if (fichero.endsWith('.md')) rmSync(join(options.salida, fichero));
}

const resumen = [];
for (const [obraId, filas] of secuenciasPorObra) {
	const titulo = filas[0].obra_titulo;
	const editor = filas[0].editor ?? null;
	const texto = informeDeObra({
		titulo,
		editor,
		secuencias: filas,
		subtipos: subtiposPorObra.get(obraId) ?? [],
		caracterizaciones: caracterizacionesPorObra.get(obraId) ?? [],
		jornadas: jornadasPorObra.get(obraId) ?? [],
		fecha
	});
	const fichero = `${slugify(titulo)}.md`;
	writeFileSync(join(options.salida, fichero), `${texto}\n`, 'utf-8');

	const cuenta = {
		directa: 0,
		rasgo: 0,
		ascendencia: 0,
		sin_destino: 0,
		sin_tipo: 0,
		revision_longitud: filas.filter((fila) => fila.motivo_revision).length
	};
	for (const fila of filas) cuenta[fila.via] = (cuenta[fila.via] ?? 0) + 1;
	resumen.push({ titulo, editor, fichero, cuenta, total: filas.length });
}

const indice = [];
indice.push('# Migración métrica, obra por obra');
indice.push('');
indice.push(`Generado el ${fecha} por \`npm run migracion:informe\`. **No editar a mano.**`);
indice.push('');
indice.push('Un documento por obra con secuencias métricas, para revisar con quien la anotó.');
indice.push('El procedimiento está en [cómo se migra una obra](../como-se-migra-una-obra.md);');
indice.push('las decisiones que salgan de cada revisión van a');
indice.push('[equivalencias pendientes](../equivalencias-pendientes.md).');
indice.push('');
indice.push('| Obra | Editor | Secs | Directas | Rasgo | Ascend. | Dudas |');
indice.push('| --- | --- | ---: | ---: | ---: | ---: | ---: |');
for (const fila of resumen.sort(
	(a, b) =>
		b.cuenta.sin_destino +
			b.cuenta.sin_tipo +
			b.cuenta.revision_longitud -
			(a.cuenta.sin_destino + a.cuenta.sin_tipo + a.cuenta.revision_longitud) ||
		b.cuenta.ascendencia - a.cuenta.ascendencia ||
		b.total - a.total
)) {
	const dudas = fila.cuenta.sin_destino + fila.cuenta.sin_tipo + fila.cuenta.revision_longitud;
	indice.push(
		`| [${fila.titulo}](./${fila.fichero}) | ${fila.editor ?? '—'} | ${fila.total} | ` +
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
		dudas:
			acumulado.dudas +
			fila.cuenta.sin_destino +
			fila.cuenta.sin_tipo +
			fila.cuenta.revision_longitud
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
