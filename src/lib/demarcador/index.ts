export type TipoPreguntaDemarcador = 'si_no_ns' | 'opcion';
export type FasePreguntaDemarcador = 'inicial' | 'intermedia' | 'avanzada';
export type ValorRespuestaDemarcador = boolean | string | number | 'desconocido';
export type ValorComparableDemarcador = string | number | boolean;
export type RasgosDemarcador = Record<string, unknown>;

export type OperadorCondicionDemarcador =
	| 'igual'
	| 'distinto'
	| 'contiene'
	| 'no_contiene'
	| 'contiene_conjunto'
	| 'no_contiene_conjunto'
	| 'patron_contiene'
	| 'patron_no_contiene'
	| 'umbral_minimo'
	| 'umbral_menor';

export interface CondicionRespuestaDemarcador {
	rasgo: string;
	operador: OperadorCondicionDemarcador;
	valor?: ValorComparableDemarcador | ValorComparableDemarcador[];
	umbral?: number;
	preguntaId?: string;
}

export interface MetricaDemarcador {
	metrosPosibles?: number[];
	metroPrincipal?: number | null;
	metroExclusivo?: boolean;
	patronMetrico?: number[] | null;
	regularidadMetrica?: string;
	confianza?: string;
	requiereRevision?: boolean;
}

export interface FamiliaDemarcador {
	slug: string;
	label: string;
	tipoForma?: string;
	rasgosBase: RasgosDemarcador;
	metrica: MetricaDemarcador;
	children: string[];
	confianzaFormalizacion?: string;
	requiereRevision?: boolean;
	notasRevision: string[];
}

export interface EstrofaDemarcador {
	id: string;
	slug: string;
	label: string;
	categoria?: string;
	nivel?: number;
	parentId?: string;
	parentSlug?: string;
	familySlug?: string;
	familyLabel?: string;
	tipoForma?: string;
	patronEspecifico?: string;
	definicion?: string;
	orden?: number;
	rasgos: RasgosDemarcador;
	metrica: MetricaDemarcador;
	confianzaFormalizacion?: string;
	requiereRevision?: boolean;
	notasRevision: string[];
	preguntasSugeridas: string[];
}

export interface PreguntaDemarcador {
	id: string;
	pregunta: string;
	tipo: TipoPreguntaDemarcador;
	rasgo: string;
	rasgoValor?: string;
	rasgoContiene?: string;
	rasgoConjunto?: string;
	rasgoPatronContiene?: string;
	rasgoDerivado?: string;
	valor?: ValorComparableDemarcador | ValorComparableDemarcador[];
	valores: ValorComparableDemarcador[];
	valorSi?: ValorComparableDemarcador;
	valorNo?: ValorComparableDemarcador;
	umbralSi?: number;
	fase: FasePreguntaDemarcador;
	prioridad: number;
	prioridadEditorial: number;
	bloque?: string;
	ayuda?: string;
	grupoExcluyente?: string;
	grupoLogico?: string;
	bloqueaGruposSiTrue: string[];
	bloqueadoPorGruposSiTrue: string[];
	bloqueaPreguntasSiTrue: string[];
	tipoPresencia?: string;
	opciones: Array<string | number>;
	admiteDesconocido: boolean;
	aplicaSi?: RasgosDemarcador;
	requiereRasgos?: RasgosDemarcador;
	requiereFamilias: string[];
	maxCandidatas?: number;
	nuncaPrimera: boolean;
}

export interface ReglaDemarcador {
	id: string;
	titulo: string;
	descripcion: string;
}

export interface RespuestaDemarcador {
	preguntaId: string;
	pregunta: string;
	tipo: TipoPreguntaDemarcador;
	valor: ValorRespuestaDemarcador;
	etiqueta: string;
	rasgo?: string;
	grupoExcluyente?: string;
	grupoLogico?: string;
	grupos: string[];
	bloqueaGruposSiTrue: string[];
	bloqueaPreguntasSiTrue: string[];
	condicion?: CondicionRespuestaDemarcador;
}

export interface DiagnosticoPreguntaDemarcador {
	id: string;
	pregunta: string;
	razon: string;
}

export interface DiagnosticoSeleccionDemarcador {
	candidatasRestantes: string[];
	preguntasAntesDelBloqueo: string[];
	preguntasEliminadasPorBloqueo: DiagnosticoPreguntaDemarcador[];
	preguntasEliminadasPorFaltaUtilidad: DiagnosticoPreguntaDemarcador[];
	preguntaElegida: string | null;
}

const ORDEN_FASE: Record<FasePreguntaDemarcador, number> = {
	inicial: 0,
	intermedia: 1,
	avanzada: 2
};

const UMBRAL_FAMILIAS_REQUERIDAS = 0.6;

function asRecord(value: unknown): Record<string, unknown> {
	return value && typeof value === 'object' && !Array.isArray(value)
		? (value as Record<string, unknown>)
		: {};
}

function asString(value: unknown, fallback = ''): string {
	return typeof value === 'string' ? value : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
	return typeof value === 'number' ? value : fallback;
}

function asOptionalNumber(value: unknown): number | undefined {
	return typeof value === 'number' ? value : undefined;
}

function asBoolean(value: unknown): boolean | undefined {
	return typeof value === 'boolean' ? value : undefined;
}

function asStringArray(value: unknown): string[] {
	return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];
}

function asNumberArray(value: unknown): number[] | undefined {
	if (!Array.isArray(value)) return undefined;
	const numbers = value.filter((item): item is number => typeof item === 'number');
	return numbers.length ? numbers : undefined;
}

function normalizeComparable(value: unknown): ValorComparableDemarcador | undefined {
	if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
		return value;
	}
	return undefined;
}

function normalizeComparableOrArray(
	value: unknown
): ValorComparableDemarcador | ValorComparableDemarcador[] | undefined {
	if (Array.isArray(value)) {
		return value
			.map(normalizeComparable)
			.filter((item): item is ValorComparableDemarcador => item !== undefined);
	}
	return normalizeComparable(value);
}

function normalizeComparableArray(value: unknown): ValorComparableDemarcador[] {
	return Array.isArray(value)
		? value
				.map(normalizeComparable)
				.filter((item): item is ValorComparableDemarcador => item !== undefined)
		: [];
}

function normalizeOption(value: unknown): string | number | undefined {
	if (typeof value === 'string' || typeof value === 'number') return value;
	return undefined;
}

function normalizeOptions(value: unknown): Array<string | number> {
	return Array.isArray(value)
		? value.map(normalizeOption).filter((item): item is string | number => item !== undefined)
		: [];
}

function normalizeFase(value: unknown): FasePreguntaDemarcador {
	if (value === 'intermedia' || value === 'avanzada') return value;
	return 'inicial';
}

export function normalizarMetrica(rawMetrica: unknown, rawRasgos: unknown = {}): MetricaDemarcador {
	const metrica = asRecord(rawMetrica);
	const rasgos = asRecord(rawRasgos);
	const metrosPosibles = asNumberArray(metrica.metros_posibles) ?? asNumberArray(rasgos.metros_posibles);
	const patronMetrico = asNumberArray(metrica.patron_metrico) ?? asNumberArray(rasgos.patron_metrico);
	const metroPrincipal =
		typeof metrica.metro_principal === 'number'
			? metrica.metro_principal
			: typeof rasgos.metro_principal === 'number'
				? rasgos.metro_principal
				: metrica.metro_principal === null || rasgos.metro_principal === null
					? null
					: undefined;

	return {
		metrosPosibles,
		metroPrincipal,
		metroExclusivo:
			typeof metrica.metro_exclusivo === 'boolean'
				? metrica.metro_exclusivo
				: asBoolean(rasgos.metro_exclusivo),
		patronMetrico:
			patronMetrico ??
			(metrica.patron_metrico === null || rasgos.patron_metrico === null ? null : undefined),
		regularidadMetrica:
			asString(metrica.regularidad_metrica) || asString(rasgos.regularidad_metrica) || undefined,
		confianza: asString(metrica.confianza) || undefined,
		requiereRevision: asBoolean(metrica.requiere_revision)
	};
}

function isDefined(value: unknown): boolean {
	return value !== undefined && value !== null && value !== '';
}

function stringifyValue(value: unknown): string {
	if (Array.isArray(value)) return value.map(String).sort().join('|');
	return String(value);
}

function valuesAreEqual(actual: unknown, expected: unknown): boolean {
	if (Array.isArray(actual)) {
		return actual.some((item) => valuesAreEqual(item, expected));
	}

	if (Array.isArray(expected)) {
		return expected.some((item) => valuesAreEqual(actual, item));
	}

	if (typeof actual === 'number' && typeof expected === 'number') return actual === expected;
	return String(actual) === String(expected);
}

function valueContains(actual: unknown, expected: unknown): boolean {
	if (Array.isArray(actual)) return actual.some((item) => valuesAreEqual(item, expected));
	return valuesAreEqual(actual, expected);
}

function valueContainsAll(actual: unknown, expected: unknown): boolean {
	const expectedValues = Array.isArray(expected) ? expected : [expected];
	return expectedValues.every((item) => valueContains(actual, item));
}

function patternContainsSequence(actual: unknown, expected: unknown): boolean {
	if (!Array.isArray(actual) || !Array.isArray(expected) || expected.length === 0) return false;
	if (expected.length > actual.length) return false;

	for (let index = 0; index <= actual.length - expected.length; index += 1) {
		const matches = expected.every((expectedItem, offset) =>
			valuesAreEqual(actual[index + offset], expectedItem)
		);
		if (matches) return true;
	}

	return false;
}

function numberValue(value: unknown): number | undefined {
	return typeof value === 'number' ? value : undefined;
}

function preguntaRasgoPrincipal(question: PreguntaDemarcador): string {
	return (
		question.rasgo ||
		question.rasgoValor ||
		question.rasgoContiene ||
		question.rasgoConjunto ||
		question.rasgoPatronContiene ||
		question.rasgoDerivado ||
		''
	);
}

function isSeguidilla(candidate: EstrofaDemarcador): boolean {
	return (
		candidate.slug === 'seguidilla' ||
		candidate.familySlug === 'seguidilla' ||
		candidate.parentSlug === 'seguidilla'
	);
}

function getMetricaValue(candidate: EstrofaDemarcador, key: string): unknown {
	switch (key) {
		case 'metros_posibles':
			return candidate.metrica.metrosPosibles;
		case 'metro_principal':
			return candidate.metrica.metroPrincipal;
		case 'metro_exclusivo':
			return candidate.metrica.metroExclusivo;
		case 'patron_metrico':
			return candidate.metrica.patronMetrico;
		case 'regularidad_metrica':
			return candidate.metrica.regularidadMetrica;
		case 'metro_unico':
			if (
				candidate.metrica.metroExclusivo === true &&
				candidate.metrica.metrosPosibles?.length === 1
			) {
				return candidate.metrica.metrosPosibles[0];
			}
			if (
				candidate.metrica.metroExclusivo !== undefined ||
				candidate.metrica.metrosPosibles !== undefined
			) {
				return '__sin_metro_unico__';
			}
			return undefined;
		default:
			return undefined;
	}
}

function isMetricaKey(key: string): boolean {
	return [
		'metros_posibles',
		'metro_principal',
		'metro_exclusivo',
		'patron_metrico',
		'regularidad_metrica',
		'metro_unico'
	].includes(key);
}

function getCandidateValue(candidate: EstrofaDemarcador, key: string): unknown {
	const metricValue = getMetricaValue(candidate, key);
	if (metricValue !== undefined) return metricValue;
	if (isMetricaKey(key)) return undefined;
	return candidate.rasgos[key];
}

function getQuestionValue(question: PreguntaDemarcador, candidate: EstrofaDemarcador): unknown {
	return getCandidateValue(candidate, preguntaRasgoPrincipal(question));
}

function conditionIsMet(
	value: unknown,
	condition: CondicionRespuestaDemarcador,
	candidate?: EstrofaDemarcador
): boolean {
	switch (condition.operador) {
		case 'igual':
			return valuesAreEqual(value, condition.valor);
		case 'distinto':
			return !valuesAreEqual(value, condition.valor);
		case 'contiene':
			return valueContains(value, condition.valor);
		case 'no_contiene':
			return !valueContains(value, condition.valor);
		case 'contiene_conjunto':
			return valueContainsAll(value, condition.valor);
		case 'no_contiene_conjunto':
			return !valueContainsAll(value, condition.valor);
		case 'patron_contiene':
			if (patternContainsSequence(value, condition.valor)) return true;
			return (
				condition.preguntaId === 'patron_7_5' &&
				candidate !== undefined &&
				isSeguidilla(candidate) &&
				valueContainsAll(candidate.metrica.metrosPosibles, condition.valor)
			);
		case 'patron_no_contiene':
			return !patternContainsSequence(value, condition.valor);
		case 'umbral_minimo': {
			const numericValue = numberValue(value);
			return numericValue !== undefined && condition.umbral !== undefined
				? numericValue >= condition.umbral
				: false;
		}
		case 'umbral_menor': {
			const numericValue = numberValue(value);
			return numericValue !== undefined && condition.umbral !== undefined
				? numericValue < condition.umbral
				: false;
		}
	}
}

function candidateMatchesCondition(
	candidate: EstrofaDemarcador,
	condition: CondicionRespuestaDemarcador
): boolean {
	const value = getCandidateValue(candidate, condition.rasgo);
	return !isDefined(value) || conditionIsMet(value, condition, candidate);
}

function criteriaAreSatisfied(candidates: EstrofaDemarcador[], criteria: RasgosDemarcador): boolean {
	return Object.entries(criteria).every(([key, expected]) => {
		let hasConfirmingCandidate = false;

		for (const candidate of candidates) {
			const actual = getCandidateValue(candidate, key);
			if (!isDefined(actual)) continue;
			if (!valuesAreEqual(actual, expected)) return false;
			hasConfirmingCandidate = true;
		}

		return hasConfirmingCandidate;
	});
}

function requiredFamiliesAreSatisfied(
	candidates: EstrofaDemarcador[],
	requiredFamilies: string[]
): boolean {
	if (!requiredFamilies.length) return true;

	const candidatesWithFamily = candidates.filter((candidate) => candidate.familySlug || candidate.parentSlug);
	if (!candidatesWithFamily.length) return false;

	const matching = candidatesWithFamily.filter((candidate) => {
		const family = candidate.familySlug ?? candidate.parentSlug;
		return family ? requiredFamilies.includes(family) : false;
	});

	return matching.length / candidatesWithFamily.length >= UMBRAL_FAMILIAS_REQUERIDAS;
}

function questionExpectedValue(
	question: PreguntaDemarcador
): ValorComparableDemarcador | ValorComparableDemarcador[] | undefined {
	return question.valores.length ? question.valores : question.valor;
}

function questionScalarRasgo(question: PreguntaDemarcador): string {
	return question.rasgo || question.rasgoValor || '';
}

function uniqueStrings(values: Array<string | undefined>): string[] {
	return [...new Set(values.filter((value): value is string => Boolean(value)))];
}

function gruposPregunta(question: PreguntaDemarcador): string[] {
	return uniqueStrings([
		question.grupoLogico,
		question.grupoExcluyente,
		question.id.startsWith('metro_unico_') ? 'metro_unico' : undefined,
		question.id.startsWith('metro_contiene_') && !question.grupoLogico
			? 'metro_presencia_general'
			: undefined
	]);
}

function motivoBloqueoPorRespuestaAfirmativa(
	question: PreguntaDemarcador,
	answers: RespuestaDemarcador[]
): string | null {
	const questionGroups = gruposPregunta(question);

	for (const answer of answers) {
		if (answer.valor !== true) continue;
		const answerGroups = answer.grupos?.length
			? answer.grupos
			: uniqueStrings([answer.grupoLogico, answer.grupoExcluyente]);
		if ((answer.bloqueaPreguntasSiTrue ?? []).includes(question.id)) {
			return `bloqueada por ${answer.preguntaId}`;
		}

		const grupoBloqueado = (answer.bloqueaGruposSiTrue ?? []).find((group) =>
			questionGroups.includes(group)
		);
		if (grupoBloqueado) return `grupo bloqueado por ${answer.preguntaId}: ${grupoBloqueado}`;

		const grupoInverso = question.bloqueadoPorGruposSiTrue.find((group) =>
			answerGroups.includes(group)
		);
		if (grupoInverso) return `bloqueada por grupo afirmado: ${grupoInverso}`;
	}

	return null;
}

function buildYesCondition(question: PreguntaDemarcador): CondicionRespuestaDemarcador | undefined {
	if (question.rasgoContiene) {
		return {
			rasgo: question.rasgoContiene,
			operador: 'contiene',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoConjunto) {
		return {
			rasgo: question.rasgoConjunto,
			operador: 'contiene_conjunto',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoPatronContiene) {
		return {
			rasgo: question.rasgoPatronContiene,
			operador: 'patron_contiene',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoDerivado) {
		return {
			rasgo: question.rasgoDerivado,
			operador: 'umbral_minimo',
			umbral: question.umbralSi,
			preguntaId: question.id
		};
	}

	const rasgo = questionScalarRasgo(question);
	if (!rasgo) return undefined;

	return {
		rasgo,
		operador: 'igual',
		valor: question.valorSi ?? question.valor ?? true,
		preguntaId: question.id
	};
}

function buildNoCondition(question: PreguntaDemarcador): CondicionRespuestaDemarcador | undefined {
	if (question.rasgoContiene) {
		return {
			rasgo: question.rasgoContiene,
			operador: 'no_contiene',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoConjunto) {
		return {
			rasgo: question.rasgoConjunto,
			operador: 'no_contiene_conjunto',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoPatronContiene) {
		return {
			rasgo: question.rasgoPatronContiene,
			operador: 'patron_no_contiene',
			valor: questionExpectedValue(question),
			preguntaId: question.id
		};
	}

	if (question.rasgoDerivado) {
		return {
			rasgo: question.rasgoDerivado,
			operador: 'umbral_menor',
			umbral: question.umbralSi,
			preguntaId: question.id
		};
	}

	const rasgo = questionScalarRasgo(question);
	if (!rasgo) return undefined;

	if (question.valorNo !== undefined) {
		return {
			rasgo,
			operador: 'igual',
			valor: question.valorNo,
			preguntaId: question.id
		};
	}

	if (question.valorSi !== undefined || question.valor !== undefined) {
		return {
			rasgo,
			operador: 'distinto',
			valor: question.valorSi ?? question.valor,
			preguntaId: question.id
		};
	}

	return {
		rasgo,
		operador: 'igual',
		valor: false,
		preguntaId: question.id
	};
}

function buildConditionForAnswer(
	question: PreguntaDemarcador,
	value: ValorRespuestaDemarcador
): CondicionRespuestaDemarcador | undefined {
	if (value === 'desconocido') return undefined;

	if (question.tipo === 'opcion') {
		const rasgo = questionScalarRasgo(question);
		return rasgo
			? {
					rasgo,
					operador: 'igual',
					valor: value,
					preguntaId: question.id
				}
			: undefined;
	}

	if (value === true) return buildYesCondition(question);
	if (value === false) return buildNoCondition(question);

	const rasgo = questionScalarRasgo(question);
	return rasgo
		? {
				rasgo,
				operador: 'igual',
				valor: value,
				preguntaId: question.id
			}
		: undefined;
}

function outcomeForQuestion(question: PreguntaDemarcador, candidate: EstrofaDemarcador): string | null {
	const value = getQuestionValue(question, candidate);
	if (!isDefined(value)) return null;

	const yesCondition = buildYesCondition(question);
	const noCondition = buildNoCondition(question);

	if (question.tipo === 'si_no_ns' && yesCondition) {
		if (conditionIsMet(value, yesCondition, candidate)) return 'si';
		if (noCondition && conditionIsMet(value, noCondition, candidate)) return 'no';
	}

	return stringifyValue(value);
}

function questionGroups(question: PreguntaDemarcador, candidates: EstrofaDemarcador[]) {
	const groups = new Map<string, number>();
	let definedCount = 0;

	for (const candidate of candidates) {
		const outcome = outcomeForQuestion(question, candidate);
		if (!outcome) continue;
		definedCount += 1;
		groups.set(outcome, (groups.get(outcome) ?? 0) + 1);
	}

	return { groups, definedCount };
}

function questionScore(question: PreguntaDemarcador, candidates: EstrofaDemarcador[]) {
	const { groups, definedCount } = questionGroups(question, candidates);
	const largestGroup = Math.max(0, ...groups.values());
	const balance = definedCount - largestGroup;

	return {
		question,
		groupCount: groups.size,
		definedCount,
		balance
	};
}

function compareQuestionScores(
	a: ReturnType<typeof questionScore>,
	b: ReturnType<typeof questionScore>
): number {
	const phaseDiff = ORDEN_FASE[a.question.fase] - ORDEN_FASE[b.question.fase];
	if (phaseDiff !== 0) return phaseDiff;
	if (a.question.prioridadEditorial !== b.question.prioridadEditorial) {
		return a.question.prioridadEditorial - b.question.prioridadEditorial;
	}
	if (b.groupCount !== a.groupCount) return b.groupCount - a.groupCount;
	if (b.balance !== a.balance) return b.balance - a.balance;
	if (b.definedCount !== a.definedCount) return b.definedCount - a.definedCount;
	return a.question.prioridad - b.question.prioridad;
}

export function normalizarFamilias(raw: unknown): FamiliaDemarcador[] {
	return Array.isArray(raw)
		? raw.map((item) => {
				const record = asRecord(item);
				return {
					slug: asString(record.slug),
					label: asString(record.label, asString(record.slug)),
					tipoForma: asString(record.tipo_forma) || undefined,
					rasgosBase: asRecord(record.rasgos_base),
					metrica: normalizarMetrica(record.metrica, record.rasgos_base),
					children: asStringArray(record.children),
					confianzaFormalizacion: asString(record.confianza_formalizacion) || undefined,
					requiereRevision: asBoolean(record.requiere_revision),
					notasRevision: asStringArray(record.notas_revision)
				};
			})
		: [];
}

export function normalizarEstrofas(
	raw: unknown,
	familias: FamiliaDemarcador[] = []
): EstrofaDemarcador[] {
	const familiasPorSlug = new Map(familias.map((familia) => [familia.slug, familia]));

	return Array.isArray(raw)
		? raw
				.map((item) => {
					const record = asRecord(item);
					const familySlug = asString(record.family_slug) || asString(record.parent_slug);
					const familia = familiasPorSlug.get(familySlug);
					const rasgos = asRecord(record.rasgos);

					return {
						id: asString(record.termino_id, asString(record.slug)),
						slug: asString(record.slug),
						label: asString(record.label, asString(record.slug)),
						categoria: asString(record.categoria) || undefined,
						nivel: typeof record.nivel === 'number' ? record.nivel : undefined,
						parentId: asString(record.parent_id) || undefined,
						parentSlug: asString(record.parent_slug) || undefined,
						familySlug: familySlug || undefined,
						familyLabel: familia?.label,
						tipoForma: asString(record.tipo_forma) || familia?.tipoForma,
						patronEspecifico: asString(record.patron_especifico) || undefined,
						definicion: asString(record.definicion) || undefined,
						orden: typeof record.orden === 'number' ? record.orden : undefined,
						rasgos,
						metrica: normalizarMetrica(record.metrica, rasgos),
						confianzaFormalizacion: asString(record.confianza_formalizacion) || undefined,
						requiereRevision: asBoolean(record.requiere_revision),
						notasRevision: asStringArray(record.notas_revision),
						preguntasSugeridas: asStringArray(record.preguntas_sugeridas)
					};
				})
				.filter((estrofa) => estrofa.slug && estrofa.label)
		: [];
}

export function normalizarPreguntas(raw: unknown): PreguntaDemarcador[] {
	return Array.isArray(raw)
		? raw
				.map((item) => {
					const record = asRecord(item);
					const tipo: TipoPreguntaDemarcador =
						asString(record.tipo) === 'opcion' ? 'opcion' : 'si_no_ns';
					const rasgo = asString(record.rasgo);
					const rasgoValor = asString(record.rasgo_valor);
					const rasgoContiene = asString(record.rasgo_contiene);
					const rasgoConjunto = asString(record.rasgo_conjunto);
					const rasgoPatronContiene = asString(record.rasgo_patron_contiene);
					const rasgoDerivado = asString(record.rasgo_derivado);

					return {
						id: asString(record.id),
						pregunta: asString(record.pregunta),
						tipo,
						rasgo,
						rasgoValor: rasgoValor || undefined,
						rasgoContiene: rasgoContiene || undefined,
						rasgoConjunto: rasgoConjunto || undefined,
						rasgoPatronContiene: rasgoPatronContiene || undefined,
						rasgoDerivado: rasgoDerivado || undefined,
						valor: normalizeComparableOrArray(record.valor),
						valores: normalizeComparableArray(record.valores),
						valorSi: normalizeComparable(record.valor_si),
						valorNo: normalizeComparable(record.valor_no),
						umbralSi: asOptionalNumber(record.umbral_si),
						fase: normalizeFase(record.fase),
						prioridad: asNumber(record.prioridad),
						prioridadEditorial: asNumber(record.prioridad_editorial, asNumber(record.prioridad)),
						bloque: asString(record.bloque) || undefined,
						ayuda: asString(record.ayuda) || undefined,
						grupoExcluyente: asString(record.grupo_excluyente) || undefined,
						grupoLogico: asString(record.grupo_logico) || undefined,
						bloqueaGruposSiTrue: asStringArray(record.bloquea_grupos_si_true),
						bloqueadoPorGruposSiTrue: asStringArray(record.bloqueado_por_grupos_si_true),
						bloqueaPreguntasSiTrue: asStringArray(record.bloquea_preguntas_si_true),
						tipoPresencia: asString(record.tipo_presencia) || undefined,
						opciones: normalizeOptions(record.opciones),
						admiteDesconocido: record.admite_desconocido !== false,
						aplicaSi: Object.keys(asRecord(record.aplica_si)).length
							? asRecord(record.aplica_si)
							: undefined,
						requiereRasgos: Object.keys(asRecord(record.requiere_rasgos)).length
							? asRecord(record.requiere_rasgos)
							: undefined,
						requiereFamilias: asStringArray(record.requiere_familias),
						maxCandidatas: asOptionalNumber(record.max_candidatas),
						nuncaPrimera: record.nunca_primera === true
					};
				})
				.filter((pregunta) => pregunta.id && pregunta.pregunta && preguntaRasgoPrincipal(pregunta))
		: [];
}

export function normalizarReglas(raw: unknown): ReglaDemarcador[] {
	return Array.isArray(raw)
		? raw
				.map((item) => {
					const record = asRecord(item);
					return {
						id: asString(record.id),
						titulo: asString(record.titulo),
						descripcion: asString(record.descripcion)
					};
				})
				.filter((regla) => regla.id && regla.titulo)
		: [];
}

export function crearRespuestaDemarcador(
	question: PreguntaDemarcador,
	value: ValorRespuestaDemarcador,
	label: string
): RespuestaDemarcador {
	const condition = buildConditionForAnswer(question, value);
	const groups = gruposPregunta(question);

	return {
		preguntaId: question.id,
		pregunta: question.pregunta,
		tipo: question.tipo,
		valor: value,
		etiqueta: label,
		rasgo: condition?.rasgo ?? preguntaRasgoPrincipal(question),
		grupoExcluyente: question.grupoExcluyente,
		grupoLogico: question.grupoLogico,
		grupos: groups,
		bloqueaGruposSiTrue: question.bloqueaGruposSiTrue,
		bloqueaPreguntasSiTrue: question.bloqueaPreguntasSiTrue,
		condicion: condition
	};
}

export function filtrarCandidatas(
	candidates: EstrofaDemarcador[],
	answers: RespuestaDemarcador[]
): EstrofaDemarcador[] {
	return candidates.filter((candidate) =>
		answers.every((answer) => {
			if (answer.valor === 'desconocido' || !answer.condicion) return true;
			return candidateMatchesCondition(candidate, answer.condicion);
		})
	);
}

function motivoNoAplicableSinBloqueo(
	question: PreguntaDemarcador,
	candidates: EstrofaDemarcador[],
	answers: RespuestaDemarcador[]
): string | null {
	if (answers.some((answer) => answer.preguntaId === question.id)) return 'respondida';
	if (answers.length === 0 && question.nuncaPrimera) return 'nunca_primera';
	if (question.maxCandidatas !== undefined && candidates.length > question.maxCandidatas) {
		return 'max_candidatas';
	}
	if (question.requiereRasgos && !criteriaAreSatisfied(candidates, question.requiereRasgos)) {
		return 'requiere_rasgos';
	}
	if (!requiredFamiliesAreSatisfied(candidates, question.requiereFamilias)) {
		return 'requiere_familias';
	}

	const { groups, definedCount } = questionGroups(question, candidates);
	if (definedCount === 0) return 'sin_valores_definidos';
	if (groups.size > 1 || definedCount < candidates.length) return null;

	return 'no_separa_candidatas';
}

export function esPreguntaAplicable(
	question: PreguntaDemarcador,
	candidates: EstrofaDemarcador[],
	answers: RespuestaDemarcador[]
): boolean {
	if (motivoBloqueoPorRespuestaAfirmativa(question, answers)) return false;
	return motivoNoAplicableSinBloqueo(question, candidates, answers) === null;
}

export function diagnosticarSeleccionPreguntas(
	candidates: EstrofaDemarcador[],
	questions: PreguntaDemarcador[],
	answers: RespuestaDemarcador[]
): DiagnosticoSeleccionDemarcador {
	const preguntasAntesDelBloqueo = questions
		.filter((question) => !answers.some((answer) => answer.preguntaId === question.id))
		.map((question) => question.id);
	const preguntasEliminadasPorBloqueo: DiagnosticoPreguntaDemarcador[] = [];
	const preguntasEliminadasPorFaltaUtilidad: DiagnosticoPreguntaDemarcador[] = [];
	const scored: ReturnType<typeof questionScore>[] = [];

	for (const question of questions) {
		if (answers.some((answer) => answer.preguntaId === question.id)) continue;

		const motivoBloqueo = motivoBloqueoPorRespuestaAfirmativa(question, answers);
		if (motivoBloqueo) {
			preguntasEliminadasPorBloqueo.push({
				id: question.id,
				pregunta: question.pregunta,
				razon: motivoBloqueo
			});
			continue;
		}

		const motivoNoAplicable = motivoNoAplicableSinBloqueo(question, candidates, answers);
		if (motivoNoAplicable) {
			preguntasEliminadasPorFaltaUtilidad.push({
				id: question.id,
				pregunta: question.pregunta,
				razon: motivoNoAplicable
			});
			continue;
		}

		scored.push(questionScore(question, candidates));
	}

	scored.sort(compareQuestionScores);

	return {
		candidatasRestantes: candidates.map((candidate) => candidate.slug),
		preguntasAntesDelBloqueo,
		preguntasEliminadasPorBloqueo,
		preguntasEliminadasPorFaltaUtilidad,
		preguntaElegida: scored[0]?.question.id ?? null
	};
}

export function elegirSiguientePregunta(
	candidates: EstrofaDemarcador[],
	questions: PreguntaDemarcador[],
	answers: RespuestaDemarcador[]
): PreguntaDemarcador | null {
	const scored = questions
		.filter((question) => esPreguntaAplicable(question, candidates, answers))
		.map((question) => questionScore(question, candidates));

	if (!scored.length) return null;

	scored.sort(compareQuestionScores);

	return scored[0].question;
}
