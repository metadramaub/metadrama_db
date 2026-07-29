import { createHash } from 'node:crypto';
import type {
	ArtefactoDemarcadorNuevo,
	CandidatoDemarcadorNuevo,
	RasgosCandidatoDemarcador,
	ValorCatalogado
} from '$lib/demarcador-nuevo/modelo';

type UntypedSupabaseClient = {
	from: (table: string) => any;
};

type FormRow = {
	forma_id: string;
	slug: string;
	nombre: string;
	definicion: string | null;
	nivel_estructural: 'verso' | 'estrofa' | 'serie' | 'composicion' | 'compuesta';
	residual: boolean;
	updated_at: string;
};

type ConfigurationRow = {
	configuracion_id: string;
	forma_id: string;
	slug: string;
	nombre: string;
	descripcion: string | null;
	principal: boolean;
	tipo_rima_id: string | null;
	numero_versos: number | null;
	updated_at: string;
};

type VocabularyRow = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	numero_silabas: number | null;
};

type PatternRow = {
	patron_metrico_id: string;
	configuracion_id: string;
};

type MetricPositionRow = {
	patron_metrico_id: string;
	metro_id: string | null;
	modelo_verso_id: string | null;
	posicion: number;
};

type VerseModelRow = {
	modelo_verso_id: string;
	metro_id: string | null;
	silabas_totales: number | null;
	nombre: string;
	slug: string;
	tipo: 'simple' | 'compuesto';
};

type RhymePatternRow = {
	patron_rima_id: string;
	configuracion_id: string;
	nombre: string | null;
	tipo_rima_id: string | null;
	esquema: string | null;
	comportamiento:
		| 'secuencia_fija'
		| 'secuencia_repetible'
		| 'restricciones'
		| 'libre'
		| 'pendiente_revision';
};

type RhymePositionRow = {
	patron_rima_id: string;
	bloque: number;
	posicion: number;
	ubicacion: 'final' | 'interior';
	clase_rima: string | null;
	suelto: boolean;
	opcional: boolean;
};

type RhymeLinkRow = {
	patron_rima_id: string;
	bloque_origen: number;
	posicion_origen: number;
	ubicacion_origen: 'final' | 'interior';
	desplazamiento_bloque: number;
	bloque_destino: number | null;
	posicion_destino: number;
	ubicacion_destino: 'final' | 'interior';
	tipo_enlace: string;
	obligatorio: boolean;
};

type RhymeRestrictionRow = {
	patron_rima_id: string;
	tipo: string;
	valor_numero: number | null;
	valor_texto: string | null;
	descripcion: string | null;
	obligatoria: boolean;
};

type SectionRow = {
	seccion_id: string;
	configuracion_id: string;
	seccion_padre_id: string | null;
	tipo_seccion: string;
	nombre: string | null;
	orden: number;
	repeticiones_min: number | null;
	repeticiones_max: number | null;
	versos_min: number | null;
	versos_max: number | null;
	configuracion_referenciada_id: string | null;
};

type CompiledRhymePattern = {
	tipo_rima_id: string | null;
	signature: string | null;
	label: string | null;
	predominioRima: ValorCatalogado | null;
	organizacionPareados: ValorCatalogado | null;
};

type CompiledStructure = {
	signature: string;
	label: string;
};

function qualitativeRhymeTraits(
	restrictions: RhymeRestrictionRow[]
): Pick<CompiledRhymePattern, 'predominioRima' | 'organizacionPareados'> {
	const values = new Set(restrictions.map((restriction) => restriction.valor_texto));
	const predominioRima = values.has('predominio_versos_rimados')
		? { clave: 'rimados', etiqueta: 'Predominan los versos rimados' }
		: values.has('predominio_versos_sueltos')
			? { clave: 'sueltos', etiqueta: 'Predominan los versos sueltos' }
			: null;
	const organizacionPareados = values.has('pareados_sistematicos')
		? { clave: 'sistematica', etiqueta: 'Organización sistemática en pareados' }
		: values.has('pareados_no_sistematicos')
			? { clave: 'no_sistematica', etiqueta: 'Sin organización sistemática en pareados' }
			: null;

	return { predominioRima, organizacionPareados };
}

function throwIfError(context: string, error: { message: string } | null): void {
	if (error) throw new Error(`${context}: ${error.message}`);
}

function maxDate(values: Array<string | null | undefined>): string | null {
	const timestamps = values
		.filter((value): value is string => Boolean(value))
		.map((value) => new Date(value).getTime())
		.filter((value) => !Number.isNaN(value));
	if (timestamps.length === 0) return null;
	return new Date(Math.max(...timestamps)).toISOString();
}

function cataloguedValue(
	id: string | null,
	vocabularyById: Map<string, VocabularyRow>
): ValorCatalogado | null {
	if (!id) return null;
	const value = vocabularyById.get(id);
	if (!value) return { clave: id, etiqueta: id };
	return {
		clave: value.termino,
		etiqueta: value.etiqueta?.trim() || value.termino
	};
}

function cataloguedValueBySlug(
	slug: string | null,
	vocabularyById: Map<string, VocabularyRow>
): ValorCatalogado | null {
	if (!slug) return null;
	const row = [...vocabularyById.values()].find((item) => item.termino === slug);
	return row ? cataloguedValue(row.termino_id, vocabularyById) : null;
}

function derivedStructuralNature(
	form: FormRow,
	configuration: ConfigurationRow,
	size: number | null,
	vocabularyById: Map<string, VocabularyRow>
): ValorCatalogado | null {
	const slug =
		form.nivel_estructural === 'serie'
			? 'tirada_abierta'
			: form.nivel_estructural === 'compuesta'
				? 'forma_compuesta'
				: form.nivel_estructural === 'estrofa' && size !== null
					? 'estrofa_cerrada'
					: form.nivel_estructural === 'composicion' && size !== null
						? 'forma_fija'
						: null;
	return cataloguedValueBySlug(slug, vocabularyById);
}

function fixedSectionTotal(
	section: SectionRow,
	childrenByParent: Map<string, SectionRow[]>,
	visiting: Set<string>
): number | null {
	if (visiting.has(section.seccion_id)) return null;
	visiting.add(section.seccion_id);

	const children = childrenByParent.get(section.seccion_id) ?? [];
	let unitSize: number | null;
	if (children.length > 0) {
		const childSizes = children.map((child) => fixedSectionTotal(child, childrenByParent, visiting));
		unitSize = childSizes.every((value): value is number => value !== null)
			? childSizes.reduce((total, value) => total + value, 0)
			: null;
	} else {
		unitSize =
			section.versos_min !== null && section.versos_min === section.versos_max
				? section.versos_min
				: null;
	}

	visiting.delete(section.seccion_id);
	if (unitSize === null) return null;

	const repetitions =
		section.repeticiones_min === null && section.repeticiones_max === null
			? 1
			: section.repeticiones_min !== null &&
				  section.repeticiones_min === section.repeticiones_max
				? section.repeticiones_min
				: null;
	return repetitions === null ? null : unitSize * repetitions;
}

function configurationSize(
	form: FormRow,
	configuration: ConfigurationRow,
	sections: SectionRow[]
): number | null {
	if (form.nivel_estructural === 'verso') return 1;
	if (configuration.numero_versos !== null) return configuration.numero_versos;
	if (sections.length === 0) return null;

	const childrenByParent = new Map<string, SectionRow[]>();
	for (const section of sections) {
		if (!section.seccion_padre_id) continue;
		childrenByParent.set(section.seccion_padre_id, [
			...(childrenByParent.get(section.seccion_padre_id) ?? []),
			section
		]);
	}
	const roots = sections.filter((section) => section.seccion_padre_id === null);
	if (roots.length === 0) return null;
	const rootSizes = roots.map((section) => fixedSectionTotal(section, childrenByParent, new Set()));
	return rootSizes.every((value): value is number => value !== null)
		? rootSizes.reduce((total, value) => total + value, 0)
		: null;
}

function compileStructure(
	sections: SectionRow[],
	configurationById: Map<string, ConfigurationRow>
): CompiledStructure | null {
	if (
		sections.length < 2 &&
		!sections.some((section) => Boolean(section.configuracion_referenciada_id))
	) {
		return null;
	}

	const childrenByParent = new Map<string, SectionRow[]>();
	for (const section of sections) {
		if (!section.seccion_padre_id) continue;
		childrenByParent.set(section.seccion_padre_id, [
			...(childrenByParent.get(section.seccion_padre_id) ?? []),
			section
		]);
	}
	const sortSections = (items: SectionRow[]) =>
		[...items].sort(
			(a, b) =>
				a.orden - b.orden ||
				(a.nombre ?? a.tipo_seccion).localeCompare(
					b.nombre ?? b.tipo_seccion,
					'es'
				)
		);
	const node = (section: SectionRow): Record<string, unknown> => ({
		tipo: section.tipo_seccion,
		orden: section.orden,
		repeticiones: [section.repeticiones_min, section.repeticiones_max],
		versos: [section.versos_min, section.versos_max],
		configuracionReferenciada:
			configurationById.get(section.configuracion_referenciada_id ?? '')?.slug ??
			null,
		partes: sortSections(childrenByParent.get(section.seccion_id) ?? []).map(node)
	});
	const roots = sortSections(
		sections.filter((section) => section.seccion_padre_id === null)
	);
	if (roots.length === 0) return null;

	const visibleParts =
		roots.length === 1 && (childrenByParent.get(roots[0].seccion_id)?.length ?? 0) > 0
			? sortSections(childrenByParent.get(roots[0].seccion_id) ?? [])
			: roots;
	return {
		signature: JSON.stringify(roots.map(node)),
		label: visibleParts
			.map((section) => section.nombre?.trim() || section.tipo_seccion)
			.join(' + ')
	};
}

function compileRhymePattern(
	pattern: RhymePatternRow,
	positions: RhymePositionRow[],
	links: RhymeLinkRow[],
	restrictions: RhymeRestrictionRow[]
): { signature: string; label: string } | null {
	if (pattern.comportamiento === 'pendiente_revision') return null;
	if (pattern.comportamiento === 'libre') {
		return {
			signature: JSON.stringify({ comportamiento: 'libre' }),
			label: pattern.esquema?.trim() || 'Distribución libre'
		};
	}
	if (pattern.comportamiento === 'restricciones') {
		if (restrictions.length === 0) return null;
		const orderedRestrictions = [...restrictions]
			.sort(
				(a, b) =>
					a.tipo.localeCompare(b.tipo, 'es') ||
					String(a.valor_texto ?? '').localeCompare(String(b.valor_texto ?? ''), 'es') ||
					Number(a.valor_numero ?? 0) - Number(b.valor_numero ?? 0)
			)
			.map((restriction) => ({
				tipo: restriction.tipo,
				valorNumero: restriction.valor_numero,
				valorTexto: restriction.valor_texto,
				obligatoria: restriction.obligatoria
			}));
		return {
			signature: JSON.stringify({
				comportamiento: pattern.comportamiento,
				restricciones: orderedRestrictions
			}),
			label:
				pattern.esquema?.trim() ||
				pattern.nombre?.trim() ||
				restrictions
					.map((restriction) => restriction.descripcion?.trim())
					.filter((description): description is string => Boolean(description))
					.join(' · ') ||
				'Distribución definida mediante restricciones'
		};
	}
	if (positions.length === 0) return null;

	const orderedPositions = [...positions]
		.sort(
			(a, b) =>
				a.bloque - b.bloque ||
				a.posicion - b.posicion ||
				a.ubicacion.localeCompare(b.ubicacion)
		)
		.map((position) => ({
			bloque: position.bloque,
			posicion: position.posicion,
			ubicacion: position.ubicacion,
			clase: position.suelto ? null : position.clase_rima,
			suelto: position.suelto,
			opcional: position.opcional
		}));
	const compactScheme = orderedPositions
		.map((position) => (position.suelto ? '-' : position.clase ?? '?'))
		.join('');
	const generatedLabel =
		pattern.comportamiento === 'secuencia_repetible'
			? `${compactScheme}…`
			: compactScheme;
	const orderedLinks = [...links]
		.sort(
			(a, b) =>
				a.bloque_origen - b.bloque_origen ||
				a.posicion_origen - b.posicion_origen ||
				a.desplazamiento_bloque - b.desplazamiento_bloque ||
				(a.bloque_destino ?? 0) - (b.bloque_destino ?? 0) ||
				a.posicion_destino - b.posicion_destino
		)
		.map((link) => ({
			bloqueOrigen: link.bloque_origen,
			posicionOrigen: link.posicion_origen,
			ubicacionOrigen: link.ubicacion_origen,
			desplazamientoBloque: link.desplazamiento_bloque,
			bloqueDestino: link.bloque_destino,
			posicionDestino: link.posicion_destino,
			ubicacionDestino: link.ubicacion_destino,
			tipo: link.tipo_enlace,
			obligatorio: link.obligatorio
		}));

	return {
		signature: JSON.stringify({
			comportamiento: pattern.comportamiento,
			posiciones: orderedPositions,
			enlaces: orderedLinks
		}),
		label: pattern.esquema?.trim() || generatedLabel
	};
}

function candidateFromConfiguration(input: {
	form: FormRow;
	configuration: ConfigurationRow;
	isFamily: boolean;
	metres: ValorCatalogado[];
	rhymePattern: CompiledRhymePattern | null;
	structure: CompiledStructure | null;
	size: number | null;
	vocabularyById: Map<string, VocabularyRow>;
}): CandidatoDemarcadorNuevo {
	const {
		form,
		configuration,
		isFamily,
		metres,
		rhymePattern,
		structure,
		size,
		vocabularyById
	} = input;
	const rhyme =
		cataloguedValue(configuration.tipo_rima_id, vocabularyById) ??
		cataloguedValue(rhymePattern?.tipo_rima_id ?? null, vocabularyById);
	const traits: RasgosCandidatoDemarcador = {
		metros: metres,
		rima: rhyme,
		naturaleza: derivedStructuralNature(form, configuration, size, vocabularyById),
		tamanio: size,
		estructura: structure?.signature ?? null,
		estructuraEtiqueta: structure?.label ?? null,
		patron: rhymePattern?.signature ?? null,
		patronEtiqueta: rhymePattern?.label ?? null,
		predominioRima: rhymePattern?.predominioRima ?? null,
		organizacionPareados: rhymePattern?.organizacionPareados ?? null
	};

	return {
		id: isFamily ? form.forma_id : configuration.configuracion_id,
		slug: isFamily ? form.slug : `${form.slug}--${configuration.slug}`,
		etiqueta: isFamily ? form.nombre : `${form.nombre}: ${configuration.nombre}`,
		definicion: (isFamily ? form.definicion : configuration.descripcion)?.trim() || form.definicion,
		familiaId: form.forma_id,
		familiaSlug: form.slug,
		familiaEtiqueta: form.nombre,
		esFamilia: isFamily,
		esResidual: form.residual,
		rasgos: traits
	};
}

export async function generateDemarcatorFromMetricCatalog(
	supabase: App.Locals['supabase']
): Promise<{
	artifact: ArtefactoDemarcadorNuevo;
	sourceHash: string;
	catalogRevision: number;
	warnings: string[];
}> {
	const db = supabase as unknown as UntypedSupabaseClient;
	const [
		stateResponse,
		formsResponse,
		configurationsResponse,
		metricPatternsResponse,
		metricOptionsResponse,
		metricPositionsResponse,
		verseModelsResponse,
		rhymePatternsResponse,
		rhymePositionsResponse,
		rhymeLinksResponse,
		rhymeRestrictionsResponse,
		sectionsResponse,
		vocabularyResponse
	] = await Promise.all([
		db.from('catalogo_metrico_estado').select('revision,actualizado_en').eq('id', true).single(),
		db
			.from('formas_metricas')
			.select('forma_id,slug,nombre,definicion,nivel_estructural,residual,updated_at')
			.eq('activo', true)
			.eq('seleccionable', true),
		db
			.from('configuraciones_forma')
			.select(
				'configuracion_id,forma_id,slug,nombre,descripcion,principal,tipo_rima_id,numero_versos,updated_at'
			)
			.eq('activo', true)
			.eq('demarcable', true),
		db.from('patrones_metricos').select('patron_metrico_id,configuracion_id'),
		db.from('patron_metrico_opciones').select('patron_metrico_id,metro_id,orden'),
		db
			.from('patron_metrico_posiciones')
			.select('patron_metrico_id,metro_id,modelo_verso_id,posicion'),
		db
			.from('modelos_verso')
			.select('modelo_verso_id,metro_id,silabas_totales,nombre,slug,tipo')
			.eq('activo', true),
		db
			.from('patrones_rima')
			.select('patron_rima_id,configuracion_id,nombre,tipo_rima_id,esquema,comportamiento')
			.order('fijeza', { ascending: true }),
		db
			.from('patron_rima_posiciones')
			.select('patron_rima_id,bloque,posicion,ubicacion,clase_rima,suelto,opcional'),
		db
			.from('patron_rima_enlaces')
			.select(
				'patron_rima_id,bloque_origen,posicion_origen,ubicacion_origen,desplazamiento_bloque,bloque_destino,posicion_destino,ubicacion_destino,tipo_enlace,obligatorio'
			),
		db
			.from('patron_rima_restricciones')
			.select('patron_rima_id,tipo,valor_numero,valor_texto,descripcion,obligatoria'),
		db
			.from('estructuras_secciones')
			.select(
				'seccion_id,configuracion_id,seccion_padre_id,tipo_seccion,nombre,orden,repeticiones_min,repeticiones_max,versos_min,versos_max,configuracion_referenciada_id'
			),
		db
			.from('vocabularios')
			.select('termino_id,termino,etiqueta,numero_silabas')
			.in('categoria', ['tipo_rima', 'naturaleza_estrofica', 'metro'])
	]);

	throwIfError('No se pudo leer la revisión del catálogo', stateResponse.error);
	throwIfError('No se pudieron cargar las formas del catálogo', formsResponse.error);
	throwIfError(
		'No se pudieron cargar las configuraciones del catálogo',
		configurationsResponse.error
	);
	throwIfError('No se pudieron cargar los patrones métricos', metricPatternsResponse.error);
	throwIfError('No se pudieron cargar las opciones métricas', metricOptionsResponse.error);
	throwIfError('No se pudieron cargar las posiciones métricas', metricPositionsResponse.error);
	throwIfError('No se pudieron cargar los modelos de verso', verseModelsResponse.error);
	throwIfError('No se pudieron cargar los patrones de rima', rhymePatternsResponse.error);
	throwIfError('No se pudieron cargar las posiciones de rima', rhymePositionsResponse.error);
	throwIfError('No se pudieron cargar los enlaces de rima', rhymeLinksResponse.error);
	throwIfError(
		'No se pudieron cargar las restricciones de rima',
		rhymeRestrictionsResponse.error
	);
	throwIfError('No se pudieron cargar las secciones métricas', sectionsResponse.error);
	throwIfError('No se pudieron cargar los vocabularios auxiliares', vocabularyResponse.error);

	const forms = (formsResponse.data ?? []) as FormRow[];
	const configurations = (configurationsResponse.data ?? []) as ConfigurationRow[];
	const configurationById = new Map(
		configurations.map((configuration) => [
			configuration.configuracion_id,
			configuration
		])
	);
	const sections = (sectionsResponse.data ?? []) as SectionRow[];
	const metricPatterns = (metricPatternsResponse.data ?? []) as PatternRow[];
	const vocabularyById = new Map<string, VocabularyRow>(
		((vocabularyResponse.data ?? []) as VocabularyRow[]).map((row) => [row.termino_id, row])
	);
	const configurationByPattern = new Map(
		metricPatterns.map((pattern) => [pattern.patron_metrico_id, pattern.configuracion_id])
	);
	const verseModelsById = new Map<string, VerseModelRow>(
		((verseModelsResponse.data ?? []) as VerseModelRow[]).map((row) => [row.modelo_verso_id, row])
	);
	const metresByConfiguration = new Map<string, Map<string, ValorCatalogado>>();

	for (const relation of [
		...(metricOptionsResponse.data ?? []),
		...(metricPositionsResponse.data ?? [])
	]) {
		const metricPosition = relation as MetricPositionRow;
		const metreId =
			metricPosition.metro_id ??
			(metricPosition.modelo_verso_id
				? verseModelsById.get(metricPosition.modelo_verso_id)?.metro_id
				: null);
		if (!metreId) continue;
		const configurationId = configurationByPattern.get(relation.patron_metrico_id);
		const metre = vocabularyById.get(metreId);
		if (!configurationId || !metre) continue;
		const values = metresByConfiguration.get(configurationId) ?? new Map<string, ValorCatalogado>();
		const key =
			typeof metre.numero_silabas === 'number' ? String(metre.numero_silabas) : metre.termino;
		values.set(key, {
			clave: key,
			etiqueta:
				typeof metre.numero_silabas === 'number'
					? `${metre.numero_silabas} sílabas`
					: metre.etiqueta?.trim() || metre.termino
		});
		metresByConfiguration.set(configurationId, values);
	}

	const rhymePatternsByConfiguration = new Map<string, RhymePatternRow[]>();
	for (const pattern of (rhymePatternsResponse.data ?? []) as RhymePatternRow[]) {
		rhymePatternsByConfiguration.set(pattern.configuracion_id, [
			...(rhymePatternsByConfiguration.get(pattern.configuracion_id) ?? []),
			pattern
		]);
	}
	const rhymePositionsByPattern = new Map<string, RhymePositionRow[]>();
	for (const position of (rhymePositionsResponse.data ?? []) as RhymePositionRow[]) {
		rhymePositionsByPattern.set(position.patron_rima_id, [
			...(rhymePositionsByPattern.get(position.patron_rima_id) ?? []),
			position
		]);
	}
	const rhymeLinksByPattern = new Map<string, RhymeLinkRow[]>();
	for (const link of (rhymeLinksResponse.data ?? []) as RhymeLinkRow[]) {
		rhymeLinksByPattern.set(link.patron_rima_id, [
			...(rhymeLinksByPattern.get(link.patron_rima_id) ?? []),
			link
		]);
	}
	const rhymeRestrictionsByPattern = new Map<string, RhymeRestrictionRow[]>();
	for (const restriction of (rhymeRestrictionsResponse.data ?? []) as RhymeRestrictionRow[]) {
		rhymeRestrictionsByPattern.set(restriction.patron_rima_id, [
			...(rhymeRestrictionsByPattern.get(restriction.patron_rima_id) ?? []),
			restriction
		]);
	}
	const rhymePatternByConfiguration = new Map<string, CompiledRhymePattern>();
	for (const [configurationId, patterns] of rhymePatternsByConfiguration) {
		const compiled = patterns
			.map((pattern) => ({
				pattern,
				compiled: compileRhymePattern(
					pattern,
					rhymePositionsByPattern.get(pattern.patron_rima_id) ?? [],
					rhymeLinksByPattern.get(pattern.patron_rima_id) ?? [],
					rhymeRestrictionsByPattern.get(pattern.patron_rima_id) ?? []
				)
			}))
			.filter(
				(
					item
				): item is {
					pattern: RhymePatternRow;
					compiled: { signature: string; label: string };
				} => item.compiled !== null
			);
		const signatures = [...new Set(compiled.map((item) => item.compiled.signature))].sort();
		const labels = [...new Set(compiled.map((item) => item.compiled.label))];
		const qualitativeTraits = patterns
			.map((pattern) =>
				qualitativeRhymeTraits(
					rhymeRestrictionsByPattern.get(pattern.patron_rima_id) ?? []
				)
			)
			.reduce(
				(result, traits) => ({
					predominioRima: result.predominioRima ?? traits.predominioRima,
					organizacionPareados:
						result.organizacionPareados ?? traits.organizacionPareados
				}),
				{
					predominioRima: null,
					organizacionPareados: null
				} as Pick<CompiledRhymePattern, 'predominioRima' | 'organizacionPareados'>
			);
		rhymePatternByConfiguration.set(configurationId, {
			tipo_rima_id: patterns.find((pattern) => pattern.tipo_rima_id)?.tipo_rima_id ?? null,
			signature:
				signatures.length > 0
					? JSON.stringify({ alternativas: signatures })
					: null,
			label: labels.length > 0 ? labels.join(' / ') : null,
			...qualitativeTraits
		});
	}

	const configurationsByForm = new Map<string, ConfigurationRow[]>();
	for (const configuration of configurations) {
		configurationsByForm.set(configuration.forma_id, [
			...(configurationsByForm.get(configuration.forma_id) ?? []),
			configuration
		]);
	}

	const warnings: string[] = [];
	const compileFamilies = (selectedForms: FormRow[]) =>
		selectedForms
		.flatMap((form) => {
			const formConfigurations = configurationsByForm.get(form.forma_id) ?? [];
			if (formConfigurations.length === 0) {
				warnings.push(`«${form.nombre}» no tiene configuraciones demarcables.`);
				return [];
			}
			const hasMultipleConfigurations = formConfigurations.length > 1;

			return formConfigurations.map((configuration) => {
				const familyId = hasMultipleConfigurations ? configuration.configuracion_id : form.forma_id;
				const familySlug = hasMultipleConfigurations
					? `${form.slug}--${configuration.slug}`
					: form.slug;
				const familyLabel = hasMultipleConfigurations
					? `${form.nombre}: ${configuration.nombre}`
					: form.nombre;
				const candidate = candidateFromConfiguration({
					form,
					configuration,
					isFamily: !hasMultipleConfigurations,
					metres: [
						...(metresByConfiguration.get(configuration.configuracion_id)?.values() ?? [])
					].sort((a, b) => a.clave.localeCompare(b.clave, 'es', { numeric: true })),
					rhymePattern: rhymePatternByConfiguration.get(configuration.configuracion_id) ?? null,
					structure: compileStructure(
						sections.filter(
							(section) =>
								section.configuracion_id === configuration.configuracion_id
						),
						configurationById
					),
					size: configurationSize(
						form,
						configuration,
						sections.filter(
							(section) => section.configuracion_id === configuration.configuracion_id
						)
					),
					vocabularyById
				});

				return {
					id: familyId,
					slug: familySlug,
					etiqueta: familyLabel,
					politica: 'familia' as const,
					raiz: {
						...candidate,
						id: familyId,
						slug: familySlug,
						etiqueta: familyLabel,
						familiaId: familyId,
						familiaSlug: familySlug,
						familiaEtiqueta: familyLabel,
						esFamilia: true
					},
					variantes: []
				};
			});
		})
		.sort((a, b) => a.etiqueta.localeCompare(b.etiqueta, 'es'));
	const families = compileFamilies(forms.filter((form) => !form.residual));
	const residuals = compileFamilies(forms.filter((form) => form.residual)).map(
		(family) => family.raiz
	);

	const generatedAt = new Date().toISOString();
	const sourceUpdatedAt =
		stateResponse.data?.actualizado_en ??
		maxDate([
			...forms.map((form) => form.updated_at),
			...configurations.map((configuration) => configuration.updated_at)
		]);
	const artifact: ArtefactoDemarcadorNuevo = {
		esquema: 1,
		origen: 'catalogo_metrico',
		generadoEn: generatedAt,
		fuenteActualizadaEn: sourceUpdatedAt,
		familias: families,
		residuales: residuals,
		estadisticas: {
			familias: families.length,
			familiasConVariantes: families.filter((family) => family.variantes.length > 0).length,
			variantesDemarcables: families.reduce((total, family) => total + family.variantes.length, 0),
			residuales: residuals.length
		}
	};
	const catalogRevision = Number(stateResponse.data?.revision ?? 1);
	const sourceHash = createHash('sha256')
		.update(
			JSON.stringify({
				source: 'catalogo_metrico',
				catalogRevision,
				families: artifact.familias
			})
		)
		.digest('hex');

	return { artifact, sourceHash, catalogRevision, warnings };
}
