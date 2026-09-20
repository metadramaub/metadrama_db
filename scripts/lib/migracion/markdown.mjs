/**
 * El informe escrito de una obra, en Markdown. Está redactado para la persona que anotó la obra:
 * le cuenta qué hemos encontrado, qué le pedimos y cómo contestar en el Excel que lo acompaña.
 * El mismo texto se vuelca a HTML.
 *
 * Las tablas del final —todas las secuencias, los subtipos— sirven para poder seguir la obra sin
 * consultar la base; el editor no tiene por qué leerlas enteras.
 */

const URL_CATALOGO = 'https://versologia.metadrama.org/recursos/catalogo-metrico';

// --------------------------------------------------------------------------
// Textos compartidos con el Excel
// --------------------------------------------------------------------------

/**
 * Cómo se rellena el Excel. Cada elemento es un párrafo; se usa aquí y en la pestaña de
 * instrucciones del propio Excel.
 */
export const instrucciones = ({ enExcel = false } = {}) => [
	`El Excel tiene cinco pestañas. En tres de ellas hay que escribir —**Responder**, **Confirmar** y **Desviaciones**— y las otras dos son de consulta: **Secuencias**, con todo lo que tiene anotado tu obra, e **Instrucciones**, ${enExcel ? 'donde estás ahora' : 'con este mismo texto'}. Solo hace falta escribir en las columnas de fondo amarillo, que son «Respuesta», «Excepciones / detalle» y «Comentario». El resto de columnas las genera el programa y las necesita tal cual para poder leer las respuestas, así que conviene no tocarlas.`,
	'En **Responder** están las preguntas que no he podido contestar con lo que ya tenías anotado. Cada fila corresponde a un pasaje y a una pregunta. Cuando la celda tiene desplegable, basta con elegir; cuando no, la columna «Cómo contestar» explica el formato. Las preguntas que se refieren a cada estrofa aparecen de dos maneras: si son pocas estrofas, hay una fila por estrofa; si son muchas, hay una sola fila cuya respuesta vale para todas, y las estrofas que se aparten de ella se anotan en «Excepciones / detalle» indicando los versos y la respuesta, por ejemplo «191–194: Cruzada · abab; 203–206: Cruzada · abab».',
	'Las filas marcadas como **Decidir** señalan pasajes cuyo número de versos no encaja con la forma que tienen asignada. En ellas hay que elegir en el desplegable qué ocurre y explicarlo al lado. Si se trata de una laguna que no se contó, indica en qué verso está y cuántos versos faltan, porque los añadiré a la numeración y todo lo que viene después se desplazará. Si lo que falla es el rango, escribe el rango correcto.',
	'En **Confirmar** aparecen las respuestas que he rellenado yo a partir del término que elegiste en su día: la asonancia de un romance, el esquema de una octava real «regular», o que un endecasílabo suelto «puro» no lleva pareados. Solo hay que revisarlas. Si alguna no es así, elige «No es así» y escribe al lado lo que corresponde.',
	'En **Desviaciones** están los versos hipométricos e hipermétricos, las rimas defectuosas y las lagunas que anotaste, con tus notas, y cómo quedan en el modelo nuevo. Se trasladan tal cual. Si tienes a mano el número de sílabas de algún verso hipométrico o hipermétrico, ponlo en la columna «Sílabas»; si no, se registra simplemente que el verso tiene menos o más sílabas de las que le tocan, sin dar una cifra.',
	'Si algo no está claro o no sabes cómo contestarlo, pregúntamelo antes de dejarlo a medias. Una vez hecha la migración podrás ver cada secuencia de tu obra con el editor nuevo en el dashboard y comprobar allí que la migración no dejó ningún hueco.'
];

/** Los formatos de respuesta cuando no hay desplegable, para la pestaña de instrucciones. */
export const FORMATOS = [
	'Medidas: el número de sílabas de cada verso, en orden y separados por espacios. Por ejemplo, «7 11 7 7 11 7 11 11».',
	'Posiciones: en qué versos de la estrofa cae el quebrado y cuántas sílabas tiene cada uno, separados por comas. Por ejemplo, «3: 4, 8: 5» quiere decir que el verso 3 tiene cuatro sílabas y el 8 tiene cinco.',
	'Esquema de rima: una letra por verso, en mayúscula si el verso es de arte mayor y un guion si queda suelto. Por ejemplo, «aBab-B».',
	'Excepciones: los versos de la estrofa y la respuesta que le corresponde, separando cada estrofa con punto y coma. Por ejemplo, «191–194: Cruzada · abab; 203–206: Cruzada · abab».'
];

// --------------------------------------------------------------------------
// Utilidades
// --------------------------------------------------------------------------

const ETIQUETA_VIA = {
	directa: 'directa',
	rasgo: 'rasgo + forma del padre',
	ascendencia: 'por ascendencia',
	sin_destino: '**sin destino**',
	sin_tipo: '**no declara forma**'
};

const plural = (n, singular, plural_) => `${n} ${n === 1 ? singular : plural_}`;

/**
 * Los subtipos y las caracterizaciones de una secuencia, con su rango cuando no la ocupan entera.
 * El rango importa: una hipometría es de un verso concreto y una prosa ocupa un tramo.
 */
function enumerarRangos(filas, secuencia) {
	if (!filas || filas.length === 0) return '—';
	return filas
		.map((fila) => {
			const cubreLaSecuencia =
				Number(fila.v_ini) === Number(secuencia.v_ini) &&
				Number(fila.v_fin) === Number(secuencia.v_fin);
			const nombre = fila.termino ? `\`${fila.termino}\`` : '—';
			const rango =
				Number(fila.v_ini) === Number(fila.v_fin) ? `${fila.v_ini}` : `${fila.v_ini}–${fila.v_fin}`;
			return cubreLaSecuencia ? nombre : `${nombre} (${rango})`;
		})
		.join('<br>');
}

function contar(filas, clave) {
	const cuenta = new Map();
	for (const fila of filas) {
		const valor = fila[clave] ?? '(sin término)';
		cuenta.set(valor, (cuenta.get(valor) ?? 0) + 1);
	}
	return [...cuenta].sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0]), 'es'));
}

const celda = (texto) =>
	String(texto ?? '')
		.replaceAll('|', '\\|')
		.replaceAll('\n', ' ');

// --------------------------------------------------------------------------
// El informe de una obra
// --------------------------------------------------------------------------

export function informeDeObra(obra, fecha) {
	const { secuencias, cuestionario, fundibles } = obra;
	const cuenta = { directa: 0, rasgo: 0, ascendencia: 0, sin_destino: 0 };
	for (const s of secuencias) cuenta[s.via] = (cuenta[s.via] ?? 0) + 1;

	const decisiones = cuestionario.responder.filter((f) => f.tipo === 'decidir');
	const respuestas = cuestionario.responder.filter((f) => f.tipo !== 'decidir');
	const secuenciasConRespuesta = new Set(respuestas.map((f) => f.secuencia_id)).size;
	const confirmaciones = cuestionario.confirmar;
	const conSilabas = cuestionario.desviaciones.filter((f) => f.tipo === 'silabas');
	const aConfirmar = cuestionario.desviaciones.filter((f) => f.tipo === 'confirmar');
	const nadaQuePedir =
		decisiones.length +
			respuestas.length +
			confirmaciones.length +
			conSilabas.length +
			aConfirmar.length ===
		0;

	const l = [];
	const w = (t = '') => l.push(t);

	w(`# Migración métrica · ${obra.titulo}`);
	w();
	w(`Informe para ${obra.editor ?? 'la persona que anotó la obra'}, generado el ${fecha}. Se`);
	w('regenera con `npm run migracion:informe`, así que no conviene editarlo a mano. Va acompañado');
	w('de un Excel con el mismo nombre, que es lo que hay que devolver rellenado.');
	w();

	w('## De qué va esto');
	w();
	w('Estoy trasladando la anotación métrica de las obras al catálogo nuevo, el que se publica en');
	w(
		`[recursos/catalogo-metrico](${URL_CATALOGO}). La mayor parte del trabajo la hace un programa:`
	);
	w('cada término del vocabulario anterior tiene su forma y su arquitectura en el catálogo, y las');
	w('tipologías de quintilla, las asonancias de los romances o los esquemas de los sonetos que');
	w(
		'anotaste en su día se conservan tal cual. Hay, sin embargo, algunas cosas que el catálogo nuevo'
	);
	w('registra y que el vocabulario anterior no recogía, y eso es lo que te pido en el Excel. Con');
	w('esas respuestas hago la migración de una vez y no hace falta que vuelvas a anotar nada.');
	w();
	w('Mientras tanto tu obra no cambia: en el dashboard sigue tal como está hasta que devuelvas el');
	w(
		'Excel. Cuando la migración esté hecha, podrás ver cada secuencia con el editor nuevo y comprobar'
	);
	w('allí que la migración no dejó ningún hueco.');
	w();

	w('## Tu obra en cifras');
	w();
	w(
		`- ${plural(secuencias.length, 'secuencia métrica', 'secuencias métricas')}. De ellas, ${cuenta.directa} tienen equivalencia directa en el`
	);
	w(
		`  catálogo, ${cuenta.rasgo} llevan además un rasgo (la asonancia de un romance, por ejemplo) y`
	);
	w(
		`  ${cuenta.ascendencia} toman la forma del término padre porque el suyo no tiene equivalencia propia.`
	);
	w(
		`- ${plural(obra.subtipos.length, 'subtipo estrófico', 'subtipos estróficos')} (las tipologías de quintilla, estrofa a estrofa), que se conservan sin cambios.`
	);
	w(
		`- ${plural(obra.caracterizaciones.length, 'caracterización por rango', 'caracterizaciones por rango')}${obra.caracterizaciones.length === 1 ? ', que se convierte en una desviación o se mantiene como está.' : ', que se convierten en desviaciones o se mantienen como están.'}`
	);
	w();

	w('## Qué te pido');
	w();
	if (nadaQuePedir) {
		w('Nada. En tu obra todo se resuelve sin preguntas; te mando el informe de todos modos para');
		w('que sepas cómo queda y por si ves algo que no cuadra.');
	} else {
		if (decisiones.length > 0) {
			w(
				`- ${plural(decisiones.length, 'decisión', 'decisiones')} sobre pasajes cuyo número de versos no encaja, o sobre tramos que van a unirse en una sola secuencia.`
			);
		}
		if (respuestas.length > 0) {
			w(
				`- ${plural(respuestas.length, 'respuesta', 'respuestas')}, en ${plural(secuenciasConRespuesta, 'secuencia', 'secuencias')}, a preguntas que el vocabulario anterior no recogía.`
			);
		}
		if (confirmaciones.length > 0) {
			w(
				`- ${plural(confirmaciones.length, 'confirmación', 'confirmaciones')} de respuestas que ya he rellenado yo.`
			);
		}
		if (conSilabas.length > 0) {
			w(
				`- ${plural(conSilabas.length, 'verso hipométrico o hipermétrico', 'versos hipométricos o hipermétricos')} en los que puedes indicar el número de sílabas si lo tienes a mano. Es opcional.`
			);
		}
		if (aConfirmar.length > 0) {
			w(
				`- ${plural(aConfirmar.length, 'caracterización', 'caracterizaciones')} que conviene que revises, porque su traducción al modelo nuevo no es automática.`
			);
		}
	}
	w();

	if (decisiones.length > 0) {
		w('## Pasajes que no encajan');
		w();
		w('Son secuencias cuyo número de versos no se corresponde con la forma que tienen asignada, y');
		w(
			'tramos que el vocabulario anterior obligaba a dividir. Aparecen en la pestaña **Responder**'
		);
		w('del Excel, marcadas como *Decidir*.');
		w();
		for (const d of decisiones) {
			w(`- **vv. ${d.versos}** · ${d.forma}. ${d.asunto}`);
		}
		w();
		if (fundibles.length > 0) {
			w('Cuando un tramo se une en una sola secuencia, los indicadores de escena de las partes se');
			w(
				'combinan: basta con que una tenga versos partidos para que la secuencia entera los tenga, y'
			);
			w(
				'si las intervenciones de personajes no coinciden quedan como «compartida». La sinopsis del'
			);
			w(
				'pasaje la escribes tú; en el Excel van las actuales, una detrás de otra, para partir de ellas.'
			);
			w();
		}
	}

	if (respuestas.length > 0) {
		w('## Preguntas pendientes');
		w();
		w('Estas son las preguntas que hace el catálogo nuevo y que no he podido responder con lo que');
		w('había anotado; hace falta mirar el texto. Están en la pestaña **Responder**.');
		w();
		w('| Versos | Forma | Pregunta | Cómo contestar |');
		w('| --- | --- | --- | --- |');
		const porSecuencia = new Map();
		for (const r of respuestas) {
			const clave = `${r.versos}|${r.pregunta ?? r.asunto}`;
			const entrada = porSecuencia.get(clave) ?? { ...r, filas: 0 };
			entrada.filas += 1;
			porSecuencia.set(clave, entrada);
		}
		for (const r of porSecuencia.values()) {
			const que = r.pregunta
				? r.filas > 1
					? `${r.pregunta}, en ${plural(r.filas, 'estrofa', 'estrofas')} (una fila por estrofa)`
					: r.asunto
				: r.asunto;
			w(`| ${r.versos} | ${celda(r.forma)} | ${celda(que)} | ${celda(r.formato?.ayuda ?? '')} |`);
		}
		w();
	}

	if (confirmaciones.length > 0) {
		w('## Respuestas ya rellenas');
		w();
		w('Estas respuestas se deducen del término que elegiste en su día, y las he rellenado yo.');
		w('Conviene echarles un vistazo por si en alguna estrofa las cosas eran de otra');
		w('manera. Están en la pestaña **Confirmar**.');
		w();
		w('| Versos | Forma | Pregunta | Respuesta | Vocabulario anterior |');
		w('| --- | --- | --- | --- | --- |');
		for (const c of confirmaciones) {
			w(
				`| ${c.versos} | ${celda(c.forma)} | ${celda(c.asunto)} | ${celda(c.propuesta)} | ${celda(c.origen ?? '—')} |`
			);
		}
		w();
	}

	if (obra.caracterizaciones.length > 0) {
		w('## Desviaciones');
		w();
		w('Las caracterizaciones por rango que anotaste, y cómo quedan en el modelo nuevo. Los versos');
		w(
			'hipométricos e hipermétricos pasan a ser desviaciones de medida; si tienes a mano el número'
		);
		w('de sílabas puedes indicarlo, y si no se registra que el verso tiene menos o más sílabas de');
		w('las que le tocan, sin dar una cifra. Están en la pestaña **Desviaciones**.');
		w();
		w('| Tipo | Rangos | Cómo queda |');
		w('| --- | ---: | --- |');
		const destinoPorTipo = new Map(cuestionario.desviaciones.map((d) => [d.termino, d.asunto]));
		for (const [tipo, total] of contar(obra.caracterizaciones, 'termino')) {
			w(`| \`${tipo}\` | ${total} | ${celda(destinoPorTipo.get(tipo) ?? '—')} |`);
		}
		w();
	}

	w('## Cómo rellenar el Excel');
	w();
	for (const parrafo of instrucciones()) {
		w(parrafo);
		w();
	}
	w('Cuando no hay desplegable, los formatos son estos:');
	w();
	for (const formato of FORMATOS) w(`- ${formato}`);
	w();

	w('## Todas las secuencias');
	w();
	w('Para terminar, la lista completa de secuencias con todo lo que la obra tiene anotado de cada');
	w('una, salvo la sinopsis y los comentarios internos, de modo que se pueda seguir la migración');
	w('sin consultar la base. Cuando un subtipo o una caracterización no ocupa la secuencia entera,');
	w('lleva su rango entre paréntesis. La columna «Propuesta» indica cuántas respuestas trae ya la');
	w('secuencia: las anotadas son las que se miraron verso a verso en su día y se conservan; las');
	w('derivadas se deducen del término y aparecen en la pestaña Confirmar.');
	w();
	w(
		'| # | Versos | v | Vocabulario anterior | Forma | Arquitectura | Subtipos | Caracterizaciones | Estado | Propuesta | Vía |'
	);
	w('| ---: | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |');
	secuencias.forEach((s, i) => {
		const via =
			s.via === 'ascendencia' ? `por ascendencia (${s.heredado_de})` : ETIQUETA_VIA[s.via];
		const estado = s.diagnostico
			? `**Revisar:** ${s.diagnostico.texto}`
			: s.faltan.length > 0
				? `**Falta:** ${s.faltan.join(', ')}`
				: s.estado;
		const propuesta =
			[
				s.anotadas > 0 ? plural(s.anotadas, 'anotada', 'anotadas') : null,
				s.derivadas > 0 ? plural(s.derivadas, 'derivada', 'derivadas') : null
			]
				.filter(Boolean)
				.join(' · ') || '—';
		w(
			`| ${i + 1} | ${s.v_ini}–${s.v_fin} | ${s.n_versos} | ` +
				`${s.termino_legado ? `\`${s.termino_legado}\`` : '—'} | ` +
				`${s.forma_propuesta ?? '—'} | ${s.arquitectura_propuesta ?? '—'} | ` +
				`${enumerarRangos(s.subtipos, s)} | ${enumerarRangos(s.caracterizaciones, s)} | ` +
				`${celda(estado)} | ${propuesta} | ${via} |`
		);
	});
	w();

	if (obra.subtipos.length > 0) {
		w('## Subtipos estróficos');
		w();
		w('Los subtipos pasan a ser las estrofas del modelo nuevo, cada una con su esquema, y no hace');
		w('falta revisarlos.');
		w();
		w('| Subtipo | Rangos |');
		w('| --- | ---: |');
		for (const [clave, total] of contar(obra.subtipos, 'termino')) w(`| \`${clave}\` | ${total} |`);
		w();
	}

	return l.join('\n');
}

// --------------------------------------------------------------------------
// El índice
// --------------------------------------------------------------------------

export function indiceDeObras(obras, fecha) {
	const l = [];
	const w = (t = '') => l.push(t);
	w('# Migración métrica, obra por obra');
	w();
	w(`Generado el ${fecha} por \`npm run migracion:informe\`. **No editar a mano.**`);
	w();
	w(
		'Hay un informe por cada obra con secuencias del vocabulario anterior, escrito para la persona'
	);
	w(
		'que la anotó. En [cuestionarios/](./cuestionarios/) están el mismo informe en HTML y el Excel'
	);
	w(
		'que se le envía; las respuestas devueltas van a [respuestas/](./respuestas/). El procedimiento'
	);
	w('completo está en [el plan de migración](../plan-migracion-anotaciones.md).');
	w();
	w('| Obra | Editor | Secs | Directas | Rasgo | Ascend. | Decidir | Responder | Confirmar |');
	w('| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
	const resumen = obras.map((o) => {
		const cuenta = { directa: 0, rasgo: 0, ascendencia: 0 };
		for (const s of o.secuencias) cuenta[s.via] = (cuenta[s.via] ?? 0) + 1;
		const decidir = o.cuestionario.responder.filter((f) => f.tipo === 'decidir').length;
		const responder = o.cuestionario.responder.length - decidir;
		return { ...o, cuenta, decidir, responder, confirmar: o.cuestionario.confirmar.length };
	});
	resumen.sort(
		(a, b) =>
			b.decidir - a.decidir ||
			b.responder - a.responder ||
			b.secuencias.length - a.secuencias.length
	);
	for (const o of resumen) {
		w(
			`| [${o.titulo}](./${o.slug}.md) | ${o.editor ?? '—'} | ${o.secuencias.length} | ` +
				`${o.cuenta.directa} | ${o.cuenta.rasgo} | ${o.cuenta.ascendencia} | ` +
				`${o.decidir > 0 ? `**${o.decidir}**` : '—'} | ${o.responder || '—'} | ${o.confirmar || '—'} |`
		);
	}
	w();
	const totales = resumen.reduce(
		(acc, o) => ({
			secuencias: acc.secuencias + o.secuencias.length,
			directa: acc.directa + o.cuenta.directa,
			rasgo: acc.rasgo + o.cuenta.rasgo,
			ascendencia: acc.ascendencia + o.cuenta.ascendencia,
			decidir: acc.decidir + o.decidir,
			responder: acc.responder + o.responder,
			confirmar: acc.confirmar + o.confirmar
		}),
		{ secuencias: 0, directa: 0, rasgo: 0, ascendencia: 0, decidir: 0, responder: 0, confirmar: 0 }
	);
	w(
		`En total, ${totales.secuencias} secuencias en ${obras.length} obras: ${totales.directa} con equivalencia directa, ` +
			`${totales.rasgo} con un rasgo además de la forma y ${totales.ascendencia} que la heredan del término padre. ` +
			`A los editores se les piden ${totales.decidir} decisiones, ${totales.responder} respuestas y ${totales.confirmar} confirmaciones.`
	);
	return l.join('\n');
}
