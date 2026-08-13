import type {
	CatalogoDemarcador,
	EvidenciaNormativa,
	FormaDemarcable,
	HipotesisMetrica,
	ModalidadEvidencia,
	NivelEstructural,
	ObservabilidadEvidencia,
	ValorEvidencia
} from '$lib/demarcador-metrico/modelo';
import { construirRejilla } from '$lib/metrica/rejilla';

type DbClient = {
	rpc: (name: string) => any;
	from: (table: string) => { select: (columns: string) => any };
};
type Row = Record<string, any>;

function fallo(etiqueta: string, error: { message?: string } | null | undefined): void {
	if (error) throw new Error(`${etiqueta}: ${error.message ?? 'error desconocido'}`);
}

function modalidad(
	value: unknown,
	fallback: ModalidadEvidencia = 'definitoria'
): ModalidadEvidencia {
	return value === 'habitual' || value === 'admitida' || value === 'excepcional'
		? value
		: value === 'definitoria'
			? value
			: fallback;
}

function observabilidad(value: unknown): ObservabilidadEvidencia {
	return value === 'especializada' || value === 'derivada' ? value : 'directa';
}

function nivelEstructural(value: unknown): NivelEstructural {
	return value === 'verso' || value === 'serie' || value === 'composicion' ? value : 'estrofa';
}

function valor(clave: string, etiqueta: string): ValorEvidencia {
	return { clave, etiqueta };
}

function agregarEvidencia(lista: EvidenciaNormativa[], evidencia: EvidenciaNormativa): void {
	const existente = lista.find((item) => item.dimension === evidencia.dimension);
	if (!existente) {
		lista.push(evidencia);
		return;
	}
	for (const item of evidencia.valores) {
		if (!existente.valores.some((actual) => actual.clave === item.clave))
			existente.valores.push(item);
	}
	if (
		existente.minimo === null ||
		(evidencia.minimo !== null && evidencia.minimo < existente.minimo)
	) {
		existente.minimo = evidencia.minimo;
	}
	if (existente.maximo === null || evidencia.maximo === null) existente.maximo = null;
	else existente.maximo = Math.max(existente.maximo, evidencia.maximo);
}

function evidenciaBase(
	override: Partial<EvidenciaNormativa> &
		Pick<EvidenciaNormativa, 'dimension' | 'familiaCognitiva' | 'etiqueta' | 'pregunta'>
): EvidenciaNormativa {
	return {
		dimension: override.dimension,
		familiaCognitiva: override.familiaCognitiva,
		etiqueta: override.etiqueta,
		pregunta: override.pregunta,
		ayuda: override.ayuda ?? '',
		tipo: override.tipo ?? 'categoria',
		valores: override.valores ?? [],
		minimo: override.minimo ?? null,
		maximo: override.maximo ?? null,
		modulo: override.modulo ?? null,
		residuo: override.residuo ?? null,
		reglaLongitud: override.reglaLongitud ?? null,
		modalidad: override.modalidad ?? 'definitoria',
		observabilidad: override.observabilidad ?? 'directa',
		coste: override.coste ?? 0.3,
		orden: override.orden ?? 50,
		fuente: override.fuente ?? 'norma'
	};
}

function etiquetaVocabulario(row: Row | undefined, fallback: string): string {
	return row?.etiqueta?.trim() || row?.termino?.trim() || fallback;
}

function grupoMetro(silabas: number[]): ValorEvidencia {
	const unicas = [...new Set(silabas)].sort((a, b) => a - b);
	if (unicas.length !== 1)
		return valor('combinada_variable', 'Combinación de medidas o medida variable');
	if (unicas[0] <= 8) return valor('arte_menor', 'Arte menor (hasta 8 sílabas)');
	if (unicas[0] === 11) return valor('endecasilabos', 'Endecasílabos (11 sílabas)');
	return valor('otro_arte_mayor', 'Otro verso de arte mayor');
}

function esquemaRima(pattern: Row, positions: Row[]): string | null {
	const notation = pattern.notacion?.trim();
	if (notation) return notation;
	const finales = positions
		.filter((position) => position.ubicacion === 'final')
		.sort((a, b) => a.bloque - b.bloque || a.posicion - b.posicion);
	if (finales.length === 0) return null;
	const compact = finales
		.map((position) => (position.suelto ? '-' : position.clase_rima?.trim() || '?'))
		.join('');
	// Misma convención que la notación guardada: un ciclo se marca `[…]…`, con sus posiciones
	// escritas una sola vez. Hoy no se llega aquí —toda rima con posiciones tiene notación—,
	// pero si se llegara, la etiqueta derivada debe leerse igual que la declarada.
	return pattern.tipo_secuencia === 'ciclo' ? `[${compact}]…` : compact;
}

function etiquetaEstructura(sections: Row[]): string | null {
	const ordered = [...sections]
		.filter((section) => section.seccion_padre_id === null)
		.sort((a, b) => a.orden - b.orden);
	const visible =
		ordered.length === 1
			? [...sections]
					.filter((section) => section.seccion_padre_id === ordered[0].seccion_id)
					.sort((a, b) => a.orden - b.orden)
			: ordered;
	if (visible.length < 2) return null;
	return visible.map((section) => section.nombre?.trim() || section.tipo_seccion).join(' + ');
}

function familiaEleccion(dimension: string): EvidenciaNormativa['familiaCognitiva'] {
	if (dimension === 'metro') return 'metro';
	if (dimension === 'rima') return 'rima';
	if (dimension === 'repeticion') return 'repeticion';
	if (dimension === 'estructura' || dimension === 'combinacion') return 'estructura';
	return 'rasgo';
}

export async function cargarCatalogoDemarcador(client: unknown): Promise<CatalogoDemarcador> {
	const db = client as DbClient;
	const [projection, lengthRulesProjection, structuralLevelsProjection] = await Promise.all([
		db.rpc('obtener_catalogo_demarcador'),
		db
			.from('arquitecturas_reglas_longitud')
			.select(
				'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion'
			),
		db.from('formas_metricas').select('forma_id,nivel_estructural')
	]);
	fallo('No se pudo cargar la proyección pública del catálogo', projection.error);
	fallo('No se pudieron cargar las reglas de longitud', lengthRulesProjection.error);
	fallo('No se pudieron cargar los niveles estructurales', structuralLevelsProjection.error);
	const payload = (projection.data ?? {}) as Record<string, Row[]>;
	payload.lengthRules = Array.isArray(lengthRulesProjection.data) ? lengthRulesProjection.data : [];
	const responses = [
		'forms',
		'architectures',
		'metricPatterns',
		'metricPositions',
		'metricOptions',
		'metres',
		'rhymePatterns',
		'rhymePositions',
		'rhymeLinks',
		'sections',
		'repetitions',
		'traits',
		'traitValues',
		'architectureTraits',
		'choiceGroups',
		'choiceOptions',
		'vocabularies',
		'lengthRules'
	].map((key) => ({ data: Array.isArray(payload[key]) ? payload[key] : [], error: null }));

	const labels = [
		'formas',
		'arquitecturas',
		'esquemas métricos',
		'posiciones métricas',
		'opciones métricas',
		'metros',
		'esquemas de rima',
		'posiciones de rima',
		'enlaces de rima',
		'secciones',
		'repeticiones',
		'rasgos',
		'valores de rasgo',
		'rasgos de arquitectura',
		'grupos de elección',
		'opciones de elección',
		'vocabularios'
	];
	responses.forEach((response, index) =>
		fallo(`No se pudieron cargar ${labels[index]}`, response.error)
	);
	const [
		formsResponse,
		architecturesResponse,
		metricPatternsResponse,
		metricPositionsResponse,
		metricOptionsResponse,
		metresResponse,
		rhymePatternsResponse,
		rhymePositionsResponse,
		rhymeLinksResponse,
		sectionsResponse,
		repetitionsResponse,
		traitsResponse,
		traitValuesResponse,
		architectureTraitsResponse,
		choiceGroupsResponse,
		choiceOptionsResponse,
		vocabulariesResponse,
		lengthRulesResponse
	] = responses;

	const forms = (formsResponse.data ?? []) as Row[];
	const architectures = (architecturesResponse.data ?? []) as Row[];
	const formById = new Map(forms.map((form) => [form.forma_id, form]));
	const structuralLevelByForm = new Map(
		((structuralLevelsProjection.data ?? []) as Row[]).map((form) => [
			form.forma_id,
			nivelEstructural(form.nivel_estructural)
		])
	);
	const vocabularyById = new Map(
		((vocabulariesResponse.data ?? []) as Row[]).map((item) => [item.termino_id, item])
	);
	const lengthRuleByArchitecture = new Map(
		((lengthRulesResponse.data ?? []) as Row[]).map((rule) => [rule.arquitectura_id, rule])
	);
	const metreById = new Map(
		((metresResponse.data ?? []) as Row[]).map((item) => [item.metro_id, item])
	);
	const patternArchitecture = new Map(
		((metricPatternsResponse.data ?? []) as Row[])
			.filter((pattern) => !pattern.seccion_id)
			.map((pattern) => [pattern.esquema_metrico_id, pattern.arquitectura_id])
	);
	const metresByArchitecture = new Map<string, Row[]>();
	const metricPositionsByPattern = new Map<string, Row[]>();
	for (const row of (metricPositionsResponse.data ?? []) as Row[]) {
		metricPositionsByPattern.set(row.esquema_metrico_id, [
			...(metricPositionsByPattern.get(row.esquema_metrico_id) ?? []),
			row
		]);
	}
	const metricOptionsByPattern = new Map<string, Row[]>();
	for (const row of (metricOptionsResponse.data ?? []) as Row[]) {
		metricOptionsByPattern.set(row.esquema_metrico_id, [
			...(metricOptionsByPattern.get(row.esquema_metrico_id) ?? []),
			row
		]);
	}
	for (const row of [
		...((metricPositionsResponse.data ?? []) as Row[]),
		...((metricOptionsResponse.data ?? []) as Row[])
	]) {
		const architectureId = patternArchitecture.get(row.esquema_metrico_id);
		const metre = metreById.get(row.metro_id);
		if (!architectureId || !metre) continue;
		const current = metresByArchitecture.get(architectureId) ?? [];
		if (!current.some((item) => item.metro_id === metre.metro_id)) current.push(metre);
		metresByArchitecture.set(architectureId, current);
	}

	const rhymePositionsByPattern = new Map<string, Row[]>();
	for (const position of (rhymePositionsResponse.data ?? []) as Row[]) {
		rhymePositionsByPattern.set(position.esquema_rima_id, [
			...(rhymePositionsByPattern.get(position.esquema_rima_id) ?? []),
			position
		]);
	}
	const rhymeLinksByPattern = new Map<string, Row[]>();
	for (const link of (rhymeLinksResponse.data ?? []) as Row[]) {
		rhymeLinksByPattern.set(link.esquema_rima_id, [
			...(rhymeLinksByPattern.get(link.esquema_rima_id) ?? []),
			link
		]);
	}
	/** Las sílabas de un metro, que es lo único que la rejilla dibuja de él. */
	const silabasDe = (metreId: unknown): string | null => {
		const metre = metreById.get(metreId);
		return metre?.silabas === null || metre?.silabas === undefined ? null : String(metre.silabas);
	};
	const sectionNameById = new Map(
		((sectionsResponse.data ?? []) as Row[]).map((section) => [
			String(section.seccion_id),
			String(section.nombre)
		])
	);
	const architectureNameById = new Map(
		architectures.map((item) => [String(item.arquitectura_id), String(item.nombre)])
	);
	const rhymePatternsByArchitecture = new Map<string, Row[]>();
	for (const pattern of (rhymePatternsResponse.data ?? []) as Row[]) {
		if (pattern.seccion_id) continue;
		rhymePatternsByArchitecture.set(pattern.arquitectura_id, [
			...(rhymePatternsByArchitecture.get(pattern.arquitectura_id) ?? []),
			pattern
		]);
	}
	const sectionsByArchitecture = new Map<string, Row[]>();
	for (const section of (sectionsResponse.data ?? []) as Row[]) {
		sectionsByArchitecture.set(section.arquitectura_id, [
			...(sectionsByArchitecture.get(section.arquitectura_id) ?? []),
			section
		]);
	}
	const repetitionsByArchitecture = new Map<string, Row[]>();
	for (const repetition of (repetitionsResponse.data ?? []) as Row[]) {
		repetitionsByArchitecture.set(repetition.arquitectura_id, [
			...(repetitionsByArchitecture.get(repetition.arquitectura_id) ?? []),
			repetition
		]);
	}
	const traitById = new Map(
		((traitsResponse.data ?? []) as Row[]).map((item) => [item.rasgo_id, item])
	);
	const traitValueById = new Map(
		((traitValuesResponse.data ?? []) as Row[]).map((item) => [item.valor_id, item])
	);
	const traitsByArchitecture = new Map<string, Row[]>();
	for (const item of (architectureTraitsResponse.data ?? []) as Row[]) {
		if (!traitById.has(item.rasgo_id)) continue;
		traitsByArchitecture.set(item.arquitectura_id, [
			...(traitsByArchitecture.get(item.arquitectura_id) ?? []),
			item
		]);
	}
	const optionsByGroup = new Map<string, Row[]>();
	for (const option of (choiceOptionsResponse.data ?? []) as Row[]) {
		optionsByGroup.set(option.grupo_eleccion_id, [
			...(optionsByGroup.get(option.grupo_eleccion_id) ?? []),
			option
		]);
	}
	const groupsByArchitecture = new Map<string, Row[]>();
	for (const group of (choiceGroupsResponse.data ?? []) as Row[]) {
		groupsByArchitecture.set(group.arquitectura_id, [
			...(groupsByArchitecture.get(group.arquitectura_id) ?? []),
			group
		]);
	}

	const advertencias: string[] = [];
	const hipotesis: HipotesisMetrica[] = [];
	for (const architecture of architectures) {
		const form = formById.get(architecture.forma_id);
		if (!form || form.tipo_registro !== 'forma') continue;
		const formLevel =
			structuralLevelByForm.get(form.forma_id) ?? nivelEstructural(form.nivel_estructural);
		const unitVerses =
			architecture.unidad_versos_min !== null &&
			architecture.unidad_versos_min === architecture.unidad_versos_max
				? Number(architecture.unidad_versos_min)
				: null;
		const evidencias: EvidenciaNormativa[] = [];
		const metres = (metresByArchitecture.get(architecture.arquitectura_id) ?? []).sort(
			(a, b) => a.silabas - b.silabas
		);
		let metricDescription: string | null = null;
		if (metres.length > 0) {
			const syllables = metres.map((metre) => Number(metre.silabas));
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'metro:grupo',
					familiaCognitiva: 'metro',
					etiqueta: 'Medida predominante',
					pregunta: '¿Qué medida predomina en los versos?',
					ayuda:
						'No necesitas decidir la medida exacta: distingue entre arte menor, endecasílabos, otro arte mayor o una combinación.',
					valores: [grupoMetro(syllables)],
					observabilidad: 'directa',
					coste: 0.12,
					orden: 1,
					fuente: 'esquema'
				})
			);
			const exactLabel = metres.map((metre) => `${metre.silabas} sílabas`).join(' + ');
			metricDescription = exactLabel;
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'metro:exacto',
					familiaCognitiva: 'metro',
					etiqueta: 'Medida exacta',
					pregunta: '¿Cuál es la medida métrica de los versos?',
					ayuda: 'Elige esta precisión solo si has realizado o comprobado el cómputo métrico.',
					valores: [valor(syllables.join('+'), exactLabel)],
					observabilidad: 'especializada',
					coste: 0.55,
					orden: 40,
					fuente: 'esquema'
				})
			);
		}

		const lengthRule = lengthRuleByArchitecture.get(architecture.arquitectura_id);
		if (
			lengthRule ||
			architecture.unidad_versos_min !== null ||
			architecture.unidad_versos_max !== null
		) {
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'extension:versos',
					familiaCognitiva: 'extension',
					etiqueta: 'Extensión del pasaje',
					pregunta: '¿Cuántos versos abarca el pasaje que quieres identificar?',
					ayuda:
						'Cuenta todo el fragmento seleccionado. Puede contener una sola unidad o varias; el demarcador comprobará si se divide regularmente.',
					tipo: 'numero',
					minimo: lengthRule?.minimo_versos ?? architecture.unidad_versos_min,
					maximo: lengthRule ? null : architecture.unidad_versos_max,
					modulo: lengthRule?.modulo_versos ?? null,
					residuo: lengthRule?.residuo_versos ?? null,
					reglaLongitud: lengthRule?.explicacion ?? null,
					observabilidad: 'directa',
					coste: 0.28,
					orden: 8,
					fuente: 'norma'
				})
			);
		}
		if (unitVerses !== null && unitVerses > 1 && formLevel !== 'serie') {
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: `estructura:agrupacion:${unitVerses}`,
					familiaCognitiva: 'estructura',
					etiqueta: `Grupos de ${unitVerses} versos`,
					pregunta: `¿Se distinguen grupos regulares de ${unitVerses} versos dentro del pasaje?`,
					ayuda:
						'No necesitas nombrar la estrofa: comprueba únicamente si las fronteras se repiten a esa distancia.',
					tipo: 'booleano',
					valores: [valor('si', 'Sí')],
					observabilidad: 'directa',
					coste: 0.2,
					orden: 9,
					fuente: 'norma'
				})
			);
		}

		const rhymeTypeId =
			architecture.tipo_rima_id ??
			rhymePatternsByArchitecture
				.get(architecture.arquitectura_id)
				?.find((pattern) => pattern.tipo_rima_id)?.tipo_rima_id;
		let rhymeTypeLabel: string | null = null;
		if (rhymeTypeId) {
			const vocabulary = vocabularyById.get(rhymeTypeId);
			rhymeTypeLabel = etiquetaVocabulario(vocabulary, rhymeTypeId);
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'rima:tipo',
					familiaCognitiva: 'rima',
					etiqueta: 'Tipo de rima',
					pregunta: '¿Qué relación de rima predomina?',
					ayuda:
						'En la asonancia coinciden las vocales finales; en la consonancia coinciden vocales y consonantes.',
					valores: [
						valor(vocabulary?.termino ?? rhymeTypeId, etiquetaVocabulario(vocabulary, rhymeTypeId))
					],
					observabilidad: 'especializada',
					coste: 0.42,
					orden: 15,
					fuente: 'norma'
				})
			);
		}
		const visualRhymeSchemes: Array<{
			id: string;
			nombre: string | null;
			notacion: string;
			modalidad: ModalidadEvidencia;
		}> = [];
		for (const pattern of rhymePatternsByArchitecture.get(architecture.arquitectura_id) ?? []) {
			const label = esquemaRima(
				pattern,
				rhymePositionsByPattern.get(pattern.esquema_rima_id) ?? []
			);
			if (!label) continue;
			visualRhymeSchemes.push({
				id: pattern.esquema_rima_id,
				nombre: pattern.nombre?.trim() || null,
				notacion: label,
				modalidad: modalidad(pattern.modalidad)
			});
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'rima:distribucion',
					familiaCognitiva: 'rima',
					etiqueta: 'Distribución de la rima',
					pregunta: '¿Cómo se distribuyen los versos rimados y sueltos?',
					ayuda: 'Las letras iguales representan rimas iguales y el guion un verso suelto.',
					valores: [valor(pattern.slug ?? pattern.esquema_rima_id, label)],
					modalidad: modalidad(pattern.modalidad),
					observabilidad: 'especializada',
					coste: 0.6,
					orden: 45,
					fuente: 'esquema'
				})
			);
		}

		const sections = sectionsByArchitecture.get(architecture.arquitectura_id) ?? [];
		const structureLabel = etiquetaEstructura(sections);
		const topSections = sections.filter((section) => section.seccion_padre_id === null);
		const openSection = topSections.find(
			(section) =>
				section.repeticiones_max === null &&
				section.versos_min !== null &&
				section.versos_min === section.versos_max
		);
		const fixedClosureVerses = topSections
			.filter(
				(section) =>
					section !== openSection &&
					section.versos_min !== null &&
					section.versos_min === section.versos_max &&
					section.repeticiones_min === section.repeticiones_max
			)
			.reduce(
				(total, section) =>
					total + Number(section.versos_min) * Number(section.repeticiones_min ?? 1),
				0
			);
		if (openSection && fixedClosureVerses > 0) {
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: `estructura:serie:${openSection.versos_min}:${fixedClosureVerses}`,
					familiaCognitiva: 'estructura',
					etiqueta: 'Serie con cierre',
					pregunta: `¿Se observan grupos sucesivos de ${openSection.versos_min} versos y un cierre final de ${fixedClosureVerses}?`,
					ayuda:
						'Busca la articulación del pasaje; la pregunta no exige conocer el nombre de la forma.',
					tipo: 'booleano',
					valores: [valor('si', 'Sí')],
					observabilidad: 'especializada',
					coste: 0.42,
					orden: 24,
					fuente: 'seccion'
				})
			);
		}
		agregarEvidencia(
			evidencias,
			evidenciaBase({
				dimension: 'estructura:secciones',
				familiaCognitiva: 'estructura',
				etiqueta: 'Secciones internas',
				pregunta: '¿Se distinguen varias partes o secciones internas?',
				ayuda:
					'Busca cambios claros de organización, estrofas con funciones distintas o una división repetida.',
				tipo: 'booleano',
				valores: [valor(structureLabel ? 'si' : 'no', structureLabel ? 'Sí' : 'No')],
				observabilidad: 'directa',
				coste: 0.26,
				orden: 20,
				fuente: 'seccion'
			})
		);
		if (structureLabel) {
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'estructura:orden',
					familiaCognitiva: 'estructura',
					etiqueta: 'Organización interna',
					pregunta: '¿Qué organización interna reconoces?',
					ayuda: 'Elige el orden de las partes solo si puedes reconocer la unidad completa.',
					valores: [valor(structureLabel, structureLabel)],
					observabilidad: 'especializada',
					coste: 0.64,
					orden: 55,
					fuente: 'seccion'
				})
			);
		}

		const repetitions = repetitionsByArchitecture.get(architecture.arquitectura_id) ?? [];
		agregarEvidencia(
			evidencias,
			evidenciaBase({
				dimension: 'repeticion:presencia',
				familiaCognitiva: 'repeticion',
				etiqueta: 'Repetición estructural',
				pregunta: '¿Hay palabras, versos o secciones que reaparecen de forma reconocible?',
				ayuda:
					'Cuenta solo repeticiones que organizan la forma, como un estribillo o palabras finales recurrentes.',
				tipo: 'booleano',
				valores: [
					valor(repetitions.length > 0 ? 'si' : 'no', repetitions.length > 0 ? 'Sí' : 'No')
				],
				observabilidad: 'directa',
				coste: 0.22,
				orden: 18,
				fuente: 'repeticion'
			})
		);
		for (const repetition of repetitions) {
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: 'repeticion:tipo',
					familiaCognitiva: 'repeticion',
					etiqueta: 'Tipo de repetición',
					pregunta: '¿Qué elemento se repite de forma estructural?',
					ayuda:
						repetition.descripcion?.trim() ||
						'Elige el elemento que reaparece y organiza la forma.',
					valores: [valor(repetition.tipo, repetition.descripcion?.trim() || repetition.tipo)],
					modalidad: modalidad(repetition.modalidad),
					observabilidad: 'directa',
					coste: 0.34,
					orden: 28,
					fuente: 'repeticion'
				})
			);
		}

		const visualTraits: Array<{
			nombre: string;
			valor: string;
			descripcion: string | null;
			modalidad: ModalidadEvidencia;
		}> = [];
		for (const item of traitsByArchitecture.get(architecture.arquitectura_id) ?? []) {
			const trait = traitById.get(item.rasgo_id);
			if (!trait) continue;
			// El valor de un rasgo es siempre de vocabulario desde el 9 de agosto de 2026: cuando
			// no lo declara, la arquitectura solo dice que el rasgo está presente.
			const traitValue = traitValueById.get(item.valor_id);
			const rawValue = traitValue?.slug ?? 'si';
			const rawLabel = traitValue?.nombre ?? 'Sí';
			const boolean = trait.tipo_valor === 'booleano';
			visualTraits.push({
				nombre: trait.nombre,
				valor: boolean ? 'Sí' : String(rawLabel),
				descripcion: trait.descripcion?.trim() || item.nota?.trim() || null,
				modalidad: modalidad(item.modalidad)
			});
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: `rasgo:${trait.slug}`,
					familiaCognitiva: 'rasgo',
					etiqueta: trait.nombre,
					pregunta: boolean
						? `¿Se observa ${trait.nombre.toLocaleLowerCase('es')}?`
						: `¿Qué valor presenta «${trait.nombre}»?`,
					ayuda: trait.descripcion?.trim() || item.nota?.trim() || '',
					tipo: boolean ? 'booleano' : 'categoria',
					valores: [valor(boolean ? 'si' : String(rawValue), boolean ? 'Sí' : String(rawLabel))],
					modalidad: modalidad(item.modalidad),
					observabilidad: observabilidad(trait.observabilidad),
					coste: trait.observabilidad === 'especializada' ? 0.62 : 0.38,
					orden: 60,
					fuente: 'rasgo'
				})
			);
		}

		// La misma rejilla que dibuja la ficha pública. Antes esto se pintaba aquí a mano, fila a
		// fila de la tabla de posiciones, y por eso las alternativas de una posición se contaban
		// como posiciones distintas.
		const rejilla = construirRejilla({
			metricos: ((metricPatternsResponse.data ?? []) as Row[])
				.filter((pattern) => pattern.arquitectura_id === architecture.arquitectura_id)
				.map((pattern) => ({
					tipoSecuencia: pattern.tipo_secuencia ? String(pattern.tipo_secuencia) : null,
					medidaUniforme:
						pattern.medida_uniforme === null || pattern.medida_uniforme === undefined
							? null
							: pattern.medida_uniforme === true,
					seccion: pattern.seccion_id
						? (sectionNameById.get(String(pattern.seccion_id)) ?? null)
						: null,
					posiciones: (metricPositionsByPattern.get(pattern.esquema_metrico_id) ?? []).map(
						(position) => ({
							posicion: Number(position.posicion),
							silabas: silabasDe(position.metro_id),
							alternativa:
								position.alternativa === null || position.alternativa === undefined
									? null
									: Number(position.alternativa),
							opcional: position.opcional === true
						})
					),
					opciones: (metricOptionsByPattern.get(pattern.esquema_metrico_id) ?? []).map(
						(option) => ({
							silabas: silabasDe(option.metro_id),
							rol: option.rol ? String(option.rol) : null
						})
					)
				})),
			rimas: ((rhymePatternsResponse.data ?? []) as Row[])
				.filter((pattern) => pattern.arquitectura_id === architecture.arquitectura_id)
				.map((pattern) => ({
					id: String(pattern.esquema_rima_id),
					nombre: pattern.nombre ? String(pattern.nombre) : null,
					notacion: pattern.notacion ? String(pattern.notacion) : null,
					seccion: pattern.seccion_id
						? (sectionNameById.get(String(pattern.seccion_id)) ?? null)
						: null,
					modalidad: pattern.modalidad ? String(pattern.modalidad) : null,
					posiciones: (rhymePositionsByPattern.get(pattern.esquema_rima_id) ?? []).map(
						(position) => ({
							bloque: Number(position.bloque ?? 1),
							posicion: Number(position.posicion),
							clase: position.clase_rima ? String(position.clase_rima) : null,
							suelto: position.suelto === true,
							seccion: position.seccion ? String(position.seccion) : null
						})
					),
					enlaces: (rhymeLinksByPattern.get(pattern.esquema_rima_id) ?? []).map((link) => ({
						desde: Number(link.posicion_origen),
						hasta: Number(link.posicion_destino),
						desplazamiento: Number(link.desplazamiento_bloque),
						nota: link.nota ? String(link.nota) : null
					}))
				})),
			secciones: (sectionsByArchitecture.get(architecture.arquitectura_id) ?? [])
				.filter((section) => !section.seccion_padre_id)
				.sort((a, b) => Number(a.orden ?? 0) - Number(b.orden ?? 0))
				.map((section) => ({
					nombre: String(section.nombre),
					versosMin: section.versos_min === null ? null : Number(section.versos_min),
					versosMax: section.versos_max === null ? null : Number(section.versos_max),
					repeticionesMin:
						section.repeticiones_min === null ? null : Number(section.repeticiones_min),
					repeticionesMax:
						section.repeticiones_max === null ? null : Number(section.repeticiones_max),
					reutiliza: section.arquitectura_referenciada_id
						? {
								nombre:
									architectureNameById.get(String(section.arquitectura_referenciada_id)) ??
									'otra forma',
								slug: null
							}
						: null
				})),
			unidadMin:
				architecture.unidad_versos_min === null ? null : Number(architecture.unidad_versos_min),
			unidadMax:
				architecture.unidad_versos_max === null ? null : Number(architecture.unidad_versos_max)
		});

		for (const group of groupsByArchitecture.get(architecture.arquitectura_id) ?? []) {
			const options = [...(optionsByGroup.get(group.grupo_eleccion_id) ?? [])].sort(
				(a, b) => (a.orden ?? 999) - (b.orden ?? 999)
			);
			if (options.length < 2) continue;
			agregarEvidencia(
				evidencias,
				evidenciaBase({
					dimension: `eleccion:${group.grupo_eleccion_id}`,
					familiaCognitiva: familiaEleccion(group.dimension),
					etiqueta: group.nombre,
					pregunta: group.nombre.endsWith('?') ? group.nombre : `¿${group.nombre}?`,
					ayuda: group.ayuda_editor?.trim() || '',
					valores: options.map((option) => valor(option.slug, option.nombre)),
					modalidad: group.define_norma ? 'definitoria' : 'admitida',
					observabilidad: 'especializada',
					coste: 0.7,
					orden: 70,
					fuente: 'eleccion'
				})
			);
		}

		hipotesis.push({
			id: architecture.arquitectura_id,
			formaId: form.forma_id,
			formaSlug: form.slug,
			formaNombre: form.nombre,
			formaDefinicion: form.definicion?.trim() || null,
			nivelEstructural: formLevel,
			arquitecturaId: architecture.arquitectura_id,
			arquitecturaSlug: architecture.slug,
			arquitecturaNombre: architecture.nombre,
			arquitecturaDescripcion: architecture.descripcion?.trim() || null,
			arquitecturaPrincipal: Boolean(architecture.principal),
			unidadVersos: unitVerses,
			presentacion: {
				rejilla,
				metro: { descripcion: metricDescription },
				rima: { tipo: rhymeTypeLabel, esquemas: visualRhymeSchemes },
				estructura: structureLabel,
				repeticiones: repetitions
					.map((repetition) => repetition.descripcion?.trim() || repetition.regla?.trim())
					.filter((description): description is string => Boolean(description)),
				rasgos: visualTraits
			},
			evidencias
		});
	}

	for (const form of forms.filter((item) => item.tipo_registro === 'forma')) {
		if (!hipotesis.some((item) => item.formaId === form.forma_id)) {
			advertencias.push(`«${form.nombre}» no tiene arquitecturas activas y demarcables.`);
		}
	}
	const formas: FormaDemarcable[] = [...new Set(hipotesis.map((item) => item.formaId))]
		.map((formId) => {
			const form = formById.get(formId)!;
			return {
				id: form.forma_id,
				slug: form.slug,
				nombre: form.nombre,
				definicion: form.definicion?.trim() || null,
				nivelEstructural:
					structuralLevelByForm.get(form.forma_id) ?? nivelEstructural(form.nivel_estructural),
				arquitecturas: hipotesis
					.filter((item) => item.formaId === formId)
					.map((item) => ({
						id: item.arquitecturaId,
						nombre: item.arquitecturaNombre,
						descripcion: item.arquitecturaDescripcion
					}))
			};
		})
		.sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));

	return { formas, hipotesis, advertencias };
}
