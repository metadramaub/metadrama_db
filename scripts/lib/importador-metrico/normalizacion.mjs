/** Normalización local y reproducible. No lee archivos, no escribe en la DB ni adivina formas. */
import { z } from 'zod';
import { validarExtraccion } from './validacion.mjs';
import { pareadosEnDenominacion, cierreConExcepciones } from './pareados-declarados.mjs';

export class ErrorExtraccion extends Error {
	constructor(incidencias) {
		super('La extracción contiene datos que hay que corregir.');
		this.name = 'ErrorExtraccion';
		this.incidencias = incidencias;
	}
}

const texto = z.string().trim().min(1);
const candidataSchema = z.object({ forma_slug: texto, arquitectura_slug: texto.nullable() });
const aprobacionSchema = z
	.object({
		responsable: texto,
		fecha: z.iso.date(),
		fundamento: texto
	})
	.strict();
const reglaSchema = z.object({
	id: texto,
	literales: z.array(texto).min(1),
	tipo: z.enum(['equivalencia_propuesta', 'candidatas_orientativas', 'sin_resolver']),
	candidatas: z.array(candidataSchema),
	fundamento: texto,
	exhaustividad: texto,
	detalles_fuente: z.array(z.record(z.string(), z.unknown())),
	evidencias_bibliograficas: z.array(texto).default([]),
	ambito: z.object({ obras: z.array(texto).min(1) }).optional(),
	division: z.literal('soneto_y_estrambote_sin_identificar').optional(),
	nota_contiene: z.array(texto).min(1).optional(),
	patron: z
		.enum([
			'romance_con_asonancia',
			'lira_con_esquema_seis_posiciones',
			'sueltos_con_pareados_localizados',
			'sueltos_cierre_con_excepciones'
		])
		.optional(),
	aprobacion: aprobacionSchema.optional()
});
const reglasSchema = z.object({ version: texto, reglas: z.array(reglaSchema) });
const deviationSchema = z
	.object({
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		dimension: z.enum(['metro', 'estructura']),
		relacion_norma: z.enum(['menor_que_norma', 'mayor_que_norma', 'sobra', 'falta', 'otra']),
		metro_observado_slug: texto.optional()
	})
	.refine((d) => d.v_fin >= d.v_ini, 'Desviación con rango invertido');

function unionLength(rows) {
	const sorted = rows
		.filter((r) => r.v_ini !== null && r.v_fin !== null)
		.map(({ v_ini, v_fin }) => ({ v_ini, v_fin }))
		.sort((a, b) => a.v_ini - b.v_ini);
	let total = 0;
	let end = -1;
	for (const row of sorted) {
		total += Math.max(0, row.v_fin - Math.max(row.v_ini, end + 1) + 1);
		end = Math.max(end, row.v_fin);
	}
	return total;
}

function indexRules(reglas, catalogo, bibliografia) {
	const parsed = reglasSchema.parse(reglas);
	const evidenceIds = new Set(bibliografia?.hallazgos?.map((h) => h.id) ?? []);
	const forms = new Map(catalogo.formas.map((f) => [f.slug, f]));
	const ids = new Set();
	for (const rule of parsed.reglas) {
		if (ids.has(rule.id)) throw new Error(`Regla duplicada: ${rule.id}`);
		ids.add(rule.id);
		for (const id of rule.evidencias_bibliograficas) {
			if (!evidenceIds.has(id)) throw new Error(`Evidencia bibliográfica no registrada: ${id}`);
		}
		if (rule.tipo === 'equivalencia_propuesta' && rule.candidatas.length !== 1)
			throw new Error(`La equivalencia ${rule.id} debe tener un solo destino`);
		if (rule.tipo === 'sin_resolver' && rule.candidatas.length)
			throw new Error(`La regla sin resolver ${rule.id} no puede asignar candidatas`);
		for (const target of rule.candidatas) {
			const form = forms.get(target.forma_slug);
			if (!form) throw new Error(`Forma ajena a la referencia: ${target.forma_slug}`);
			if (
				target.arquitectura_slug &&
				!form.arquitecturas.some((a) => a.slug === target.arquitectura_slug)
			)
				throw new Error(`Arquitectura ajena a ${target.forma_slug}: ${target.arquitectura_slug}`);
		}
	}
	return parsed;
}

/** Las aprobaciones se aportan explícitamente; una candidata única de IA sigue siendo propuesta. */
export function normalizarExtraccion(
	extraccion,
	{ reglas, catalogo, fuentes, bibliografia, decisiones = [] }
) {
	const validation = validarExtraccion(extraccion, fuentes ? { fuentes } : {});
	if (validation.errores.length || validation.advertencias.length)
		throw new ErrorExtraccion([...validation.errores, ...validation.advertencias]);
	const reference = indexRules(reglas, catalogo, bibliografia);
	const source = structuredClone(extraccion);
	const rowsById = new Map(source.tramos.map((r) => [r.id, r]));
	const notesById = new Map(source.notas.map((n) => [n.id, n]));
	const localDecisions = decisiones.filter((d) => d.obra_ref === source.obra_ref);
	for (const decision of localDecisions) {
		if (decision.estado !== 'acordada')
			throw new Error('No se aplican decisiones de segmentación sin acordar');
		const row = rowsById.get(decision.tramo_ref);
		const note = notesById.get(decision.nota_ref);
		const deviation = deviationSchema.parse(decision.desviacion);
		if (!row || !note || !row.notas_ref.includes(note.id) || !note.tramos_ref.includes(row.id))
			throw new Error('Desviación sin enlace recíproco con fila y nota de fuente');
		if (
			row.v_ini === null ||
			row.v_fin === null ||
			deviation.v_ini < row.v_ini ||
			deviation.v_fin > row.v_fin ||
			deviation.v_ini !== note.v_ini ||
			deviation.v_fin !== note.v_fin
		)
			throw new Error('Desviación fuera del rango documentado en la nota');
	}
	const segmentos = source.tramos.flatMap((row) => {
		const literalComparado = row.denominacion_literal?.replace(/\s+/gu, ' ').trim();
		const claveLiteral = (literal) => literal?.replace(/\s+/gu, ' ').trim().toLowerCase();
		const vocales = literalComparado
			?.normalize('NFD')
			.replace(/\p{M}/gu, '')
			.toLowerCase()
			.match(/^romances?\s+(?:en\s+)?[-–—]?\s*([aeiou])(?:\s*[-–—]?\s*([aeiou]))?$/u);
		const liraDeSeis = /^liras?\s+(?:\(\s*[a-f](?:\s*[a-f]){5}\s*\)|[a-f](?:\s*[a-f]){5})$/iu.test(literalComparado ?? '');
		const pareados = pareadosEnDenominacion(literalComparado, row);
		const matches = reference.reglas.filter(
			(r) =>
				(r.patron === 'romance_con_asonancia'
					? Boolean(vocales)
					: r.patron === 'sueltos_con_pareados_localizados'
						? Boolean(pareados)
						: r.patron === 'lira_con_esquema_seis_posiciones'
							? liraDeSeis
							: r.literales.some((l) => claveLiteral(l) === claveLiteral(literalComparado))) &&
				(!r.ambito || r.ambito.obras.includes(source.obra_ref)) &&
				(!r.nota_contiene ||
					row.notas_ref.some((id) => {
						const n = notesById.get(id);
						const textoNota = n?.texto_literal?.replace(/\s+/gu, ' ').toLowerCase();
						return (
							n?.tramos_ref.includes(row.id) &&
							textoNota &&
							r.nota_contiene.every((fragmento) => textoNota.includes(fragmento))
						);
					}))
		);
		// Una precisión explícita en una nota enlazada prevalece sobre el nombre ambiguo.
		const precisas = matches.filter((r) => r.nota_contiene);
		// Si una regla exige todas las mismas evidencias y otra más, es más específica.
		// Las condiciones independientes siguen siendo un conflicto: no decide el orden del JSON.
		const aplicables = precisas.length
			? precisas.filter(
					(r) =>
						!precisas.some(
							(otra) =>
								otra.nota_contiene.length > r.nota_contiene.length &&
								r.nota_contiene.every((fragmento) => otra.nota_contiene.includes(fragmento))
						)
				)
			: matches;
		if (aplicables.length > 1)
			throw new Error(`Equivalencias en conflicto para ${source.obra_ref}/${row.id}`);
		let rule = aplicables[0];
		let avisoFuente = null;
		if (rule?.patron === 'sueltos_con_pareados_localizados') {
			rule = {
				...rule,
				detalles_fuente: [
					{ literal: literalComparado },
					...(pareados.disticoFinal
						? [
								{
									literal: 'Pareado final localizado en la edición',
									rasgo_slug: 'distico_final',
									valor_slug: 'presente'
								}
							]
						: [])
				]
			};
			avisoFuente = pareados.aviso;
		}
		if (rule?.patron === 'sueltos_cierre_con_excepciones') {
			const notas = row.notas_ref
				.map((id) => notesById.get(id))
				.filter((n) => n?.tramos_ref.includes(row.id));
			const decisiones = notas
				.map((n) => cierreConExcepciones(n, row, rowsById, rule.literales.map(claveLiteral)))
				.filter((v) => v !== null);
			rule = {
				...rule,
				detalles_fuente:
					decisiones.length && decisiones.every((v) => v === true)
						? [
								{
									literal: 'Pareado final declarado en nota',
									rasgo_slug: 'distico_final',
									valor_slug: 'presente'
								}
							]
						: []
			};
		}
		if (rule?.patron === 'romance_con_asonancia') {
			const valor = vocales[2] ? `${vocales[1]}-${vocales[2]}` : vocales[1];
			const literalAsonancia = literalComparado.replace(/^romances?\s+(?:en\s+)?/iu, '');
			const rasgo = catalogo.rasgos?.find((r) => r.slug === 'vocales_asonancia');
			const admitido =
				rasgo?.valores.some((v) => v.slug === valor) &&
				rasgo.contextos.some(
					(c) =>
						c.forma === 'romance' &&
						c.arquitectura === 'octosilabica' &&
						(c.valor_slug === null || c.valor_slug === valor)
				);
			rule = {
				...rule,
				detalles_fuente: [
					admitido
						? { literal: literalAsonancia, rasgo_slug: 'vocales_asonancia', valor_slug: valor }
						: { literal: literalAsonancia, dimension: 'asonancia' }
				]
			};
		}
		// Sin extensión suficiente no se inventa ni el corte ni un soneto completo.
		if (
			rule?.division &&
			(row.v_ini === null || row.v_fin === null || row.v_fin - row.v_ini + 1 <= 14)
		)
			rule = undefined;
		const exact = rule?.tipo === 'equivalencia_propuesta' ? rule.candidatas[0] : null;
		const reviewed = exact && rule.aprobacion ? exact : null;
		const segmento = {
			id: row.id,
			jornada: row.jornada,
			v_ini: row.v_ini,
			v_fin: row.v_fin,
			fuente: structuredClone(row),
			regla_id: rule?.id ?? null,
			...(avisoFuente ? { nota: avisoFuente, aviso_fuente: avisoFuente } : {}),
			estado_identificacion: reviewed
				? 'revisada'
				: exact
					? 'propuesta'
					: rule?.candidatas.length
						? 'candidatas'
						: 'sin_resolver',
			identificacion_revisada: reviewed,
			propuesta: exact && !reviewed ? exact : null,
			candidatas: exact ? [] : structuredClone(rule?.candidatas ?? []),
			exhaustividad: exact ? null : (rule?.exhaustividad ?? 'no_justificada'),
			fundamento:
				rule?.fundamento ?? 'No hay una regla aplicable; se conserva la denominación original.',
			aprobacion: rule?.aprobacion ?? null,
			evidencias_bibliograficas: rule?.evidencias_bibliograficas ?? [],
			// Estos detalles están declarados en la fuente: no equivalen a respuestas completas del editor.
			detalles_fuente: structuredClone(rule?.detalles_fuente ?? []),
			caracterizaciones: [],
			desviaciones: localDecisions
				.filter((d) => d.tramo_ref === row.id)
				.map((d) => ({
					...deviationSchema.parse(d.desviacion),
					nota_ref: d.nota_ref,
					texto_fuente: notesById.get(d.nota_ref).texto_literal,
					fundamento: d.fundamento
				}))
		};
		if (!rule?.division) return [segmento];
		if (rowsById.has(`${row.id}.1`) || rowsById.has(`${row.id}.2`))
			throw new Error('Los identificadores de la división coinciden con otra fila fuente.');
		return [
			{ ...segmento, id: `${row.id}.1`, v_fin: row.v_ini + 13 },
			{
				...structuredClone(segmento),
				id: `${row.id}.2`,
				v_ini: row.v_ini + 14,
				estado_identificacion: 'sin_resolver',
				identificacion_revisada: null,
				propuesta: null,
				candidatas: [],
				detalles_fuente: [],
				nota: 'Estrambote declarado por la edición. Se conserva como secuencia sin forma identificada mientras el catálogo no admite este remate en el soneto; criterio pendiente.'
			}
		];
	});
	const total = unionLength(segmentos);
	const measure = (predicate) => {
		const rows = segmentos.filter(predicate);
		const verses = unionLength(rows);
		return {
			segmentos: rows.length,
			versos: verses,
			porcentaje_sobre_rangos_conocidos: total ? (100 * verses) / total : null
		};
	};
	return {
		esquema: 'versologia-normalizacion-local/0.1',
		avisos_fuente: segmentos
			.filter((s) => s.aviso_fuente)
			.map((s) => ({
				codigo: 'localizacion_pareado',
				ruta: `segmentos.${s.id}`,
				mensaje: `vv. ${s.v_ini}–${s.v_fin}: ${s.aviso_fuente}`
			})),
		estado: 'borrador_de_trabajo',
		apta_para_corpus: false,
		obra_ref: source.obra_ref,
		reglas_version: reference.version,
		catalogo_referencia: { estado: catalogo.estado, fecha_consulta: catalogo.fecha_consulta },
		metadatos: source.metadatos,
		jornadas: source.jornadas.map((j) => {
			const rows = segmentos.filter(
				(s) => s.jornada === j.numero && s.v_ini !== null && s.v_fin !== null
			);
			return {
				...j,
				v_ini: rows.length ? Math.min(...rows.map((s) => s.v_ini)) : null,
				v_fin: rows.length ? Math.max(...rows.map((s) => s.v_fin)) : null,
				versos_con_rango: unionLength(rows)
			};
		}),
		segmentos,
		cobertura: {
			denominador: 'union_de_rangos_conocidos',
			versos: total,
			segmentos_sin_rango: segmentos.filter((s) => s.v_ini === null || s.v_fin === null).length,
			forma_revisada: measure((s) => Boolean(s.identificacion_revisada)),
			arquitectura_revisada: measure((s) => Boolean(s.identificacion_revisada?.arquitectura_slug)),
			forma_solo_propuesta: measure((s) => Boolean(s.propuesta)),
			arquitectura_solo_propuesta: measure((s) => Boolean(s.propuesta?.arquitectura_slug)),
			con_candidatas: measure((s) => s.estado_identificacion === 'candidatas'),
			sin_resolver: measure((s) => s.estado_identificacion === 'sin_resolver')
		},
		limites: [
			'Las filas fuente se conservan; una regla explícita puede dividirlas en segmentos provisionales para revisar antes de guardar.',
			'La aceptación de la transcripción no aprueba equivalencias ni afirma conformidad normativa.',
			'Los porcentajes miden cobertura; no son probabilidades de acierto ni tolerancias del corpus.',
			'Las candidatas no se cuentan como formas identificadas; los tramos pendientes conservan sus versos.',
			'No se deducen medidas, canto, ausencia de rasgos ni unidades por división de la longitud.'
		]
	};
}

const cell = (value) =>
	String(value ?? '—')
		.replaceAll('|', '\\|')
		.replaceAll('\n', ' ');
const table = (headers, rows) =>
	[
		`| ${headers.map(cell).join(' | ')} |`,
		`| ${headers.map(() => '---').join(' | ')} |`,
		...rows.map((r) => `| ${r.map(cell).join(' | ')} |`)
	].join('\n');

export function informeNormalizacion(result) {
	const coverage = result.cobertura;
	const metrics = [
		'forma_revisada',
		'arquitectura_revisada',
		'forma_solo_propuesta',
		'arquitectura_solo_propuesta',
		'con_candidatas',
		'sin_resolver'
	];
	return (
		[
			`# ${result.metadatos?.titulo ?? result.obra_ref}: normalización local`,
			'**Borrador de trabajo. No importado ni apto para incorporarse automáticamente al corpus.**',
			`Reglas ${result.reglas_version}; catálogo revisión ${result.catalogo_referencia.estado.revision}. La revisión de transcripción se registra por separado con el hash del original.`,
			`Fechas conservadas: ${result.metadatos?.fecha_inicio ?? '—'}–${result.metadatos?.fecha_fin ?? '—'}. Fuente: ${result.metadatos?.fuente_fecha ?? '—'}`,
			'## Cobertura por versos',
			`Denominador: ${coverage.versos} versos con rango conocido; ${coverage.segmentos_sin_rango} segmentos sin rango. Las arquitecturas son un subconjunto de sus formas: no se suman las filas de esta tabla.`,
			table(
				['Medida', 'Segmentos', 'Versos', '%'],
				metrics.map((k) => [
					k.replaceAll('_', ' '),
					coverage[k].segmentos,
					coverage[k].versos,
					coverage[k].porcentaje_sobre_rangos_conocidos?.toFixed(3)
				])
			),
			'## Correspondencias, fila por fila',
			table(
				[
					'Fila',
					'Jornada',
					'Rango',
					'Denominación de fuente',
					'Estado',
					'Forma revisada',
					'Propuesta',
					'Candidatas',
					'Detalles declarados',
					'Desviaciones'
				],
				result.segmentos.map((s) => [
					s.id,
					s.jornada,
					`${s.v_ini ?? '?'}–${s.v_fin ?? '?'}`,
					s.fuente.denominacion_literal,
					s.estado_identificacion,
					s.identificacion_revisada?.forma_slug,
					s.propuesta?.forma_slug,
					s.candidatas.map((c) => c.forma_slug).join('; ') || '—',
					s.detalles_fuente
						.map((d) => (d.nombre ? `${d.nombre}: ${d.literal}` : d.literal))
						.join('; ') || '—',
					s.desviaciones
						.map((d) => `${d.v_ini}–${d.v_fin}: ${d.dimension}/${d.relacion_norma}`)
						.join('; ') || '—'
				])
			),
			'## Límites',
			...result.limites.map((l) => `- ${l}`)
		].join('\n\n') + '\n'
	);
}
