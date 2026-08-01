<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import MetricChoiceGroupsEditor from './MetricChoiceGroupsEditor.svelte';
	import MetricPositionSequence, {
		type MetricPositionSequenceItem
	} from './MetricPositionSequence.svelte';
	import MetricRepetitionPreview from './MetricRepetitionPreview.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricReviewStateLabel,
		type MetricCatalogDomainData,
		type MetricCatalogDomainRow,
		type MetricCatalogOption
	} from '$lib/metrica/catalogo';

	const props = $props<{
		configurationId: string;
		formLevel: import('$lib/metrica/catalogo').MetricStructuralLevel;
		domain: MetricCatalogDomainData;
		metres: MetricCatalogOption[];
		rhymeTypes: MetricCatalogOption[];
	}>();

	const reviewOptions: MetricEntityOption[] = METRIC_CATALOG_REVIEW_STATES.map((state) => ({
		value: state,
		label: metricReviewStateLabel(state)
	}));
	const scopeOptions: MetricEntityOption[] = [
		{ value: 'estrofa', label: 'Estrofa' },
		{ value: 'serie', label: 'Serie' },
		{ value: 'seccion', label: 'Sección' },
		{ value: 'composicion', label: 'Composición' },
		{
			value: 'unidad',
			label: 'Unidad genérica — valor importado que debe revisarse',
			disabled: true
		}
	];
	const defaultScope = $derived(
		props.formLevel === 'estrofa'
			? 'estrofa'
			: props.formLevel === 'serie'
				? 'serie'
				: 'composicion'
	);
	const metricPatterns = $derived(
		props.domain.metricPatterns.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
		)
	);
	const metricPatternOptions = $derived(
		metricPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.notacion_metrico_id),
			label: String(row.nombre || `Esquema métrico ${index + 1}`)
		}))
	);
	const rhymePatterns = $derived(
		props.domain.rhymePatterns.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
		)
	);
	const rhymePatternOptions = $derived(
		rhymePatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.notacion_rima_id),
			label: String(row.nombre || row.notacion || `Esquema de rima ${index + 1}`)
		}))
	);
	const patternCombinations = $derived(
		props.domain.patternCombinations
			.filter(
				(row: MetricCatalogDomainRow) =>
					row.arquitectura_id === props.configurationId
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	const configurationTraits = $derived(
		props.domain.configurationTraits
			.filter(
				(row: MetricCatalogDomainRow) =>
					row.arquitectura_id === props.configurationId
			)
			.map((row: MetricCatalogDomainRow) => {
				const trait = props.domain.traits.find(
					(candidate: MetricCatalogDomainRow) =>
						candidate.rasgo_id === row.rasgo_id
				);
				const value = props.domain.traitValues.find(
					(candidate: MetricCatalogDomainRow) =>
						candidate.valor_id === row.valor_id
				);
				return {
					...row,
					nombre: value
						? `${String(trait?.nombre ?? 'Rasgo')} · ${String(value.nombre)}`
						: String(trait?.nombre ?? row.modalidad ?? 'Rasgo')
				};
			})
	);
	const repetitionPatterns = $derived(
		props.domain.repetitionPatterns.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
		)
	);
	const repetitionPatternOptions = $derived(
		repetitionPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.repeticion_id),
			label: String(row.regla || `Repetición ${index + 1}`)
		}))
	);
	const soleRepetitionPatternId = $derived(
		repetitionPatterns.length === 1
			? String(repetitionPatterns[0].repeticion_id)
			: null
	);
	const sections = $derived(
		props.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
		)
	);
	const sectionOptions = $derived(
		sections.map((row: MetricCatalogDomainRow) => ({
			value: String(row.seccion_id),
			label: String(row.nombre || row.tipo_seccion)
		}))
	);
	const reusableConfigurationOptions = $derived(
		props.domain.configurations
			.filter(
				(row: MetricCatalogDomainRow) =>
					String(row.arquitectura_id) !== props.configurationId && row.activo
			)
			.map((row: MetricCatalogDomainRow) => {
				const form = props.domain.forms.find(
					(candidate: MetricCatalogDomainRow) =>
						candidate.forma_id === row.forma_id
				);
				return {
					value: String(row.arquitectura_id),
					label: `${String(form?.nombre ?? 'Forma')} · ${String(row.nombre)}`
				};
			})
			.sort((a: MetricEntityOption, b: MetricEntityOption) =>
				a.label.localeCompare(b.label, 'es')
			)
	);
	const metreOptions = $derived(
		props.metres.map((option: MetricCatalogOption) => ({
			value: option.id,
			label: option.label
		}))
	);
	const rhymeTypeOptions = $derived(
		props.rhymeTypes.map((option: MetricCatalogOption) => ({
			value: option.id,
			label: option.label
		}))
	);
	const measureOptions = $derived(
		metreOptions.map((option: MetricEntityOption) => ({
			value: `metro:${option.value}`,
			label: option.label
		}))
	);
	const traitOptions = $derived(
		props.domain.traits.map((row: MetricCatalogDomainRow) => ({
			value: String(row.rasgo_id),
			label: String(row.nombre)
		}))
	);
	const traitValueOptions = $derived(
		props.domain.traitValues.map((row: MetricCatalogDomainRow) => ({
			value: String(row.valor_id),
			label: String(row.nombre)
		}))
	);

	const metricPatternFields: MetricEntityField[] = [
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{
			key: 'slug',
			label: 'Slug estable',
			required: true,
			help: 'La secuencia literal de medidas: 8-8-8-8-8, 7-11-7-7-11, 11-repetido, conjunto-7-11.',
			placeholder: '8-8-8-8-8'
		},
		{
			key: 'nombre',
			label: 'Nombre breve',
			help: 'Sirve para distinguir este esquema cuando una arquitectura tiene más de uno.',
			placeholder: 'Octosílabo repetido'
		},
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{
			key: 'ambito',
			label: 'Ámbito de aplicación',
			type: 'select',
			options: scopeOptions,
			required: true,
			help: 'Dónde se completa o reinicia el esquema. «Unidad genérica» es un valor provisional que debe sustituirse.'
		},
		{
			key: 'tipo',
			label: 'Comportamiento',
			type: 'select',
			required: true,
			options: [
				{ value: 'secuencia_fija', label: 'Secuencia fija' },
				{ value: 'conjunto_permitido', label: 'Conjunto de medidas permitidas' },
				{ value: 'secuencia_repetible', label: 'Secuencia repetible' },
				{ value: 'abierta', label: 'Abierta' }
			]
		},
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	];
	const metricPositionFields = $derived<MetricEntityField[]>([
		{
			key: 'esquema_metrico_id',
			label: 'Esquema',
			type: 'select',
			options: metricPatternOptions,
			required: true,
			help: 'Solo se elige cuando esta arquitectura contiene varios esquemas métricos.'
		},
		{ key: 'alternativa', label: 'Alternativa', type: 'number', required: true },
		{ key: 'posicion', label: 'Posición', type: 'number', required: true },
		{ key: 'medida', label: 'Medida o modelo de verso', type: 'select', options: measureOptions, required: true },
		{ key: 'opcional', label: 'Posición opcional', type: 'checkbox' },
		{ key: 'grupo_repeticion', label: 'Grupo de repetición' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const metricOptionFields = $derived<MetricEntityField[]>([
		{
			key: 'esquema_metrico_id',
			label: 'Esquema',
			type: 'select',
			options: metricPatternOptions,
			required: true
		},
		{ key: 'metro_id', label: 'Metro permitido', type: 'select', options: metreOptions, required: true },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const rhymePatternFields = $derived<MetricEntityField[]>([
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{
			key: 'slug',
			label: 'Slug estable',
			required: true,
			help: 'La notación en minúsculas, o una etiqueta descriptiva cuando no hay notación computable.',
			placeholder: 'abbab'
		},
		{
			key: 'nombre',
			label: 'Nombre tradicional o analítico',
			help: 'Déjalo vacío si la notación ya lo dice todo: la interfaz cae en ella.'
		},
		{ key: 'notacion', label: 'Notación', placeholder: 'ABBAACCDDC' },
		{ key: 'tipo_rima_id', label: 'Tipo de rima', type: 'select', options: rhymeTypeOptions },
		{
			key: 'ambito',
			label: 'Ámbito de aplicación',
			type: 'select',
			options: scopeOptions,
			required: true,
			help: 'Dónde se completa o reinicia la distribución de rimas.'
		},
		{
			key: 'tipo_secuencia',
			label: 'Comportamiento',
			type: 'select',
			required: true,
			options: [
				{ value: 'secuencia_fija', label: 'Secuencia fija' },
				{ value: 'secuencia_repetible', label: 'Secuencia repetible' },
				{ value: 'restricciones', label: 'Reglas combinatorias' },
				{ value: 'libre', label: 'Distribución libre' },
				{
					value: 'pendiente_revision',
					label: 'Pendiente de formalizar — valor importado',
					disabled: true
				}
			],
			help: 'Describe la forma de la secuencia. La modalidad indica después cuánto la ha fijado la tradición.'
		},
		{
			key: 'modalidad',
			label: 'Fijeza',
			type: 'select',
			required: true,
			options: [
				{ value: 'fijo', label: 'Fijo' },
				{ value: 'preferente', label: 'Preferente' },
				{ value: 'admitido', label: 'Admitido' },
				{ value: 'libre', label: 'Libre' },
				{ value: 'no_aplica', label: 'No aplicable' }
			],
			help: 'Indica cuánto obliga este esquema dentro de la arquitectura.'
		},
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	]);
	const rhymePositionFields = $derived<MetricEntityField[]>([
		{
			key: 'esquema_rima_id',
			label: 'Esquema',
			type: 'select',
			options: rhymePatternOptions,
			required: true
		},
		{ key: 'bloque', label: 'Bloque', type: 'number', required: true },
		{ key: 'seccion', label: 'Sección funcional' },
		{ key: 'posicion', label: 'Posición', type: 'number', required: true },
		{
			key: 'ubicacion',
			label: 'Ubicación',
			type: 'select',
			required: true,
			options: [
				{ value: 'final', label: 'Final del verso' },
				{ value: 'interior', label: 'Interior del verso' }
			]
		},
		{ key: 'clase_rima', label: 'Clase de rima' },
		{ key: 'suelto', label: 'Verso suelto', type: 'checkbox' },
		{ key: 'opcional', label: 'Opcional', type: 'checkbox' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const patternCombinationFields = $derived<MetricEntityField[]>([
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'nombre', label: 'Nombre visible', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{
			key: 'esquema_metrico_id',
			label: 'Esquema métrico',
			type: 'select',
			options: metricPatternOptions,
			required: true
		},
		{
			key: 'esquema_rima_id',
			label: 'Esquema de rima',
			type: 'select',
			options: rhymePatternOptions,
			required: true
		},
		{ key: 'preferente', label: 'Tipología preferente', type: 'checkbox' },
		{ key: 'orden', label: 'Orden', type: 'number' },
		{
			key: 'estado_revision',
			label: 'Estado',
			type: 'select',
			options: reviewOptions,
			required: true
		},
		{ key: 'activo', label: 'Activa', type: 'checkbox' }
	]);
	const rhymeLinkFields = $derived<MetricEntityField[]>([
		{
			key: 'esquema_rima_id',
			label: 'Esquema',
			type: 'select',
			options: rhymePatternOptions,
			required: true
		},
		{ key: 'bloque_origen', label: 'Bloque de origen', type: 'number', required: true },
		{ key: 'posicion_origen', label: 'Posición de origen', type: 'number', required: true },
		{
			key: 'ubicacion_origen',
			label: 'Ubicación de origen',
			type: 'select',
			options: [{ value: 'final', label: 'Final' }, { value: 'interior', label: 'Interior' }],
			required: true
		},
		{ key: 'desplazamiento_bloque', label: 'Desplazamiento de bloque', type: 'number' },
		{ key: 'bloque_destino', label: 'Bloque de destino', type: 'number' },
		{ key: 'posicion_destino', label: 'Posición de destino', type: 'number', required: true },
		{
			key: 'ubicacion_destino',
			label: 'Ubicación de destino',
			type: 'select',
			options: [{ value: 'final', label: 'Final' }, { value: 'interior', label: 'Interior' }],
			required: true
		},
		{ key: 'tipo_enlace', label: 'Tipo de enlace', required: true },
		{ key: 'obligatorio', label: 'Obligatorio', type: 'checkbox' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const rhymeRestrictionFields = $derived<MetricEntityField[]>([
		{
			key: 'esquema_rima_id',
			label: 'Esquema',
			type: 'select',
			options: rhymePatternOptions,
			required: true
		},
		{
			key: 'tipo',
			label: 'Restricción',
			type: 'select',
			required: true,
			options: [
				{ value: 'numero_clases', label: 'Número de clases de rima' },
				{ value: 'max_consecutivos', label: 'Máximo de versos consecutivos' },
				{ value: 'prohibe_pareado_final', label: 'Prohíbe pareado final' },
				{ value: 'versos_sueltos', label: 'Regla de versos sueltos' },
				{ value: 'otra', label: 'Otra' }
			]
		},
		{ key: 'valor_numero', label: 'Valor numérico', type: 'number' },
		{ key: 'valor_texto', label: 'Valor textual' },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'obligatoria', label: 'Obligatoria', type: 'checkbox' }
	]);
	const sectionFields = $derived<MetricEntityField[]>([
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{ key: 'seccion_padre_id', label: 'Sección superior', type: 'select', options: sectionOptions },
		{ key: 'tipo_seccion', label: 'Tipo de sección', required: true },
		{ key: 'nombre', label: 'Nombre' },
		{ key: 'orden', label: 'Orden', type: 'number', required: true },
		{
			key: 'repeticiones_min',
			maxKey: 'repeticiones_max',
			label: 'Número de repeticiones',
			type: 'integerRange',
			help: 'Introduce un solo número si es fijo. Usa un intervalo únicamente cuando exista variación real.'
		},
		{
			key: 'versos_min',
			maxKey: 'versos_max',
			label: 'Número de versos de la sección',
			type: 'integerRange',
			help: 'En una sección fija se guarda el mismo valor como mínimo y máximo.'
		},
		{
			key: 'arquitectura_referenciada_id',
			label: 'Arquitectura reutilizada',
			type: 'select',
			options: reusableConfigurationOptions,
			help: 'Úsala cuando la sección sea una realización de otra forma ya formalizada, como una redondilla dentro de una novena.'
		},
		{ key: 'esquema_metrico_id', label: 'Esquema métrico', type: 'select', options: metricPatternOptions },
		{ key: 'esquema_rima_id', label: 'Esquema de rima', type: 'select', options: rhymePatternOptions },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const repetitionFields: MetricEntityField[] = [
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{
			key: 'tipo',
			label: 'Tipo',
			type: 'select',
			required: true,
			options: [
				{ value: 'palabra_final', label: 'Palabra final' },
				{ value: 'verso', label: 'Verso' },
				{ value: 'estribillo', label: 'Estribillo' },
				{ value: 'seccion', label: 'Sección' },
				{ value: 'otro', label: 'Otro' }
			]
		},
		{
			key: 'ambito',
			label: 'Ámbito de aplicación',
			type: 'select',
			options: scopeOptions,
			required: true,
			help: 'Dónde opera la regla de repetición.'
		},
		{ key: 'regla', label: 'Regla', type: 'textarea', required: true },
		{
			key: 'modalidad',
			label: 'Fijeza',
			type: 'select',
			required: true,
			options: [
				{ value: 'fija', label: 'Fija' },
				{ value: 'canonica', label: 'Canónica' },
				{ value: 'habitual', label: 'Habitual' },
				{ value: 'admitida', label: 'Admitida' }
			]
		},
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	];
	const repetitionPositionFields = $derived<MetricEntityField[]>([
		{
			key: 'repeticion_id',
			label: 'Esquema',
			type: soleRepetitionPatternId ? 'hidden' : 'select',
			options: repetitionPatternOptions,
			required: true
		},
		{ key: 'bloque', label: 'Bloque', type: 'number', required: true },
		{ key: 'posicion', label: 'Posición', type: 'number', required: true },
		{ key: 'bloque_origen', label: 'Bloque de origen', type: 'number' },
		{ key: 'posicion_origen', label: 'Posición de origen', type: 'number' },
		{ key: 'etiqueta_funcional', label: 'Etiqueta funcional' },
		{ key: 'condicion', label: 'Condición', type: 'textarea' }
	]);
	const configurationTraitFields = $derived<MetricEntityField[]>([
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{ key: 'rasgo_id', label: 'Rasgo', type: 'select', options: traitOptions, required: true },
		{
			key: 'modalidad',
			label: 'Modalidad',
			type: 'select',
			required: true,
			options: [
				{ value: 'definitoria', label: 'Definitoria' },
				{ value: 'habitual', label: 'Habitual' },
				{ value: 'admitida', label: 'Admitida' },
				{ value: 'destacable', label: 'Destacable' }
			]
		},
		{ key: 'valor_id', label: 'Valor controlado', type: 'select', options: traitValueOptions },
		{ key: 'valor_numero', label: 'Valor numérico', type: 'number' },
		{ key: 'valor_texto', label: 'Valor textual' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);

	const groupedRhymePositionFields = $derived(hideRhymePatternField(rhymePositionFields));
	const groupedRhymeLinkFields = $derived(hideRhymePatternField(rhymeLinkFields));
	const groupedRhymeRestrictionFields = $derived(hideRhymePatternField(rhymeRestrictionFields));
	const groupedMetricPositionFields = $derived(hideMetricPatternField(metricPositionFields));
	const groupedMetricOptionFields = $derived(hideMetricPatternField(metricOptionFields));
	const groupedRepetitionPositionFields = $derived(
		hideRepetitionPatternField(repetitionPositionFields)
	);

	function hideMetricPatternField(fields: MetricEntityField[]): MetricEntityField[] {
		return fields.map((field) =>
			field.key === 'esquema_metrico_id' ? { ...field, type: 'hidden' } : field
		);
	}

	function hideRhymePatternField(fields: MetricEntityField[]): MetricEntityField[] {
		return fields.map((field) =>
			field.key === 'esquema_rima_id' ? { ...field, type: 'hidden' } : field
		);
	}

	function hideRepetitionPatternField(fields: MetricEntityField[]): MetricEntityField[] {
		return fields.map((field) =>
			field.key === 'repeticion_id' ? { ...field, type: 'hidden' } : field
		);
	}

	function rowsForMetricPattern(
		rows: MetricCatalogDomainRow[],
		patternId: string
	): MetricCatalogDomainRow[] {
		return rows
			.filter((row) => String(row.notacion_metrico_id) === patternId)
			.sort(
				(a, b) =>
					Number(a.alternativa ?? 1) - Number(b.alternativa ?? 1) ||
					Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
			);
	}

	function rowsForRhymePattern(
		rows: MetricCatalogDomainRow[],
		patternId: string
	): MetricCatalogDomainRow[] {
		return rows
			.filter((row) => String(row.notacion_rima_id) === patternId)
			.sort(
				(a, b) =>
					Number(a.bloque ?? 0) - Number(b.bloque ?? 0) ||
					Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
			);
	}

	function rowsForRepetitionPattern(
		rows: MetricCatalogDomainRow[],
		patternId: string
	): MetricCatalogDomainRow[] {
		return rows
			.filter((row) => String(row.repeticion_id) === patternId)
			.sort(
				(a, b) =>
					Number(a.bloque ?? 0) - Number(b.bloque ?? 0) ||
					Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
			);
	}

	function metricMeasureLabel(row: MetricCatalogDomainRow): string {
		if (row.metro_id) {
			return (
				props.metres.find(
					(option: MetricCatalogOption) => option.id === row.metro_id
				)?.label ?? 'Metro'
			);
		}
		return 'Sin medida';
	}

	function metricPreviewItems(patternId: string): MetricPositionSequenceItem[] {
		const rows = rowsForMetricPattern(props.domain.metricPositions, patternId);
		const alternatives = new Set(rows.map((row) => Number(row.alternativa ?? 1)));
		return rows.map((row) => ({
			key: String(row.posicion_id),
			position: Number(row.posicion),
			label: metricMeasureLabel(row),
			context:
				alternatives.size > 1 ? `Alternativa ${Number(row.alternativa ?? 1)}` : null,
			optional: Boolean(row.opcional)
		}));
	}

	function rhymePreviewItems(patternId: string): MetricPositionSequenceItem[] {
		return rowsForRhymePattern(props.domain.rhymePositions, patternId).map((row) => ({
			key: String(row.posicion_id),
			position: Number(row.posicion),
			label: row.suelto ? '—' : String(row.clase_rima ?? '?'),
			context: [row.seccion ? String(row.seccion) : null, row.bloque ? `bloque ${row.bloque}` : null]
				.filter(Boolean)
				.join(' · '),
			optional: Boolean(row.opcional)
		}));
	}
</script>

<div class="space-y-5 border-t border-[color:var(--border)] pt-5">
	<details open={patternCombinations.length > 0}>
		<summary class="flex cursor-pointer items-center justify-between gap-3 text-sm font-semibold">
			<span>Medida de los versos</span>
			<span class="font-normal text-[color:var(--muted-foreground)]">
				{metricPatterns.length} {metricPatterns.length === 1 ? 'patrón' : 'patrones'}
			</span>
		</summary>
		<div class="mt-4 space-y-5">
			<MetricEntityCollection
				resource="metricPatterns"
				title="Esquemas métricos"
				description="Abre un esquema para editar sus datos y la secuencia de versos que lo descompone."
				rows={metricPatterns}
				keyFields={['esquema_metrico_id']}
				fields={metricPatternFields}
				defaults={{ arquitectura_id: props.configurationId, ambito: defaultScope, tipo_secuencia: 'secuencia', estado_revision: 'borrador' }}
				compact
			>
				{#snippet rowContent(pattern)}
					{@const patternId = String(pattern.esquema_metrico_id)}
					{@const positions = rowsForMetricPattern(props.domain.metricPositions, patternId)}
					{@const options = rowsForMetricPattern(props.domain.metricOptions, patternId)}
					<div class="space-y-4">
						<div>
							<p class="mb-2 text-xs font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Secuencia de versos
							</p>
							<MetricPositionSequence
								items={metricPreviewItems(patternId)}
								emptyMessage={options.length > 0
									? 'Este esquema se define mediante un conjunto de medidas, no por posiciones.'
									: 'Todavía no se han declarado posiciones para este esquema.'}
							/>
						</div>

						<details>
							<summary class="cursor-pointer text-sm font-medium">
								Editar {positions.length} {positions.length === 1 ? 'posición' : 'posiciones'}
							</summary>
							<div class="mt-4">
								<MetricEntityCollection
									resource="metricPositions"
									title="Posiciones de este esquema"
									rows={positions}
									keyFields={['posicion_id']}
									fields={groupedMetricPositionFields}
									defaults={{ esquema_metrico_id: patternId, alternativa: 1, posicion: positions.length + 1, opcional: false }}
									emptyMessage="Este esquema no tiene posiciones ordenadas."
									compact
								/>
							</div>
						</details>

						{#if pattern.tipo === 'conjunto_permitido' || options.length > 0}
							<details>
								<summary class="cursor-pointer text-sm font-medium">
									Editar {options.length} {options.length === 1 ? 'medida permitida' : 'medidas permitidas'}
								</summary>
								<div class="mt-4">
									<MetricEntityCollection
										resource="metricOptions"
										title="Conjunto de este esquema"
										rows={options}
										keyFields={['esquema_metrico_id', 'metro_id']}
										fields={groupedMetricOptionFields}
										defaults={{ esquema_metrico_id: patternId }}
										emptyMessage="Todavía no se han declarado medidas permitidas."
										compact
									/>
								</div>
							</details>
						{/if}
					</div>
				{/snippet}
			</MetricEntityCollection>
		</div>
	</details>

	<details open={patternCombinations.length > 0}>
		<summary class="flex cursor-pointer items-center justify-between gap-3 text-sm font-semibold">
			<span>Rima</span>
			<span class="font-normal text-[color:var(--muted-foreground)]">
				{rhymePatterns.length} {rhymePatterns.length === 1 ? 'patrón' : 'patrones'}
			</span>
		</summary>
		<div class="mt-4 space-y-4">
			<MetricEntityCollection
				resource="rhymePatterns"
				title="Esquemas de rima"
				description="Abre un esquema para editar sus datos, leer el esquema por versos y gestionar sus reglas."
				rows={rhymePatterns}
				keyFields={['esquema_rima_id']}
				fields={rhymePatternFields}
				labelFields={['nombre', 'notacion']}
				emptyMessage="Esta arquitectura todavía no tiene alternativas de rima."
				defaults={{ arquitectura_id: props.configurationId, ambito: defaultScope, tipo_secuencia: 'secuencia', modalidad: 'admitida', estado_revision: 'borrador' }}
				compact
			>
				{#snippet rowContent(pattern)}
					{@const patternId = String(pattern.esquema_rima_id)}
					{@const positions = rowsForRhymePattern(props.domain.rhymePositions, patternId)}
					{@const links = rowsForRhymePattern(props.domain.rhymeLinks, patternId)}
					{@const restrictions = rowsForRhymePattern(props.domain.rhymeRestrictions, patternId)}
					<div class="space-y-4">
						<div>
							<div class="mb-2 flex flex-wrap items-baseline justify-between gap-2">
								<p class="text-xs font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
									Secuencia de rimas
								</p>
								{#if pattern.notacion}
									<code class="text-xs">{String(pattern.notacion)}</code>
								{/if}
							</div>
							<MetricPositionSequence
								items={rhymePreviewItems(patternId)}
								emptyMessage="Todavía no se han declarado posiciones para este esquema."
							/>
						</div>

						<details>
							<summary class="cursor-pointer text-sm font-medium">
								Editar {positions.length} {positions.length === 1 ? 'posición' : 'posiciones'}
							</summary>
							<div class="mt-4">
								<MetricEntityCollection
									resource="rhymePositions"
									title="Posiciones de este esquema"
									description="Una posición por verso; la clase corresponde a la letra del esquema."
									rows={positions}
									keyFields={['posicion_id']}
									fields={groupedRhymePositionFields}
									defaults={{ esquema_rima_id: patternId, bloque: 1, posicion: positions.length + 1, ubicacion: 'final', suelto: false, opcional: false }}
									compact
								/>
							</div>
						</details>

						<details>
							<summary class="cursor-pointer text-sm font-medium">
								Enlaces y restricciones
								<span class="font-normal text-[color:var(--muted-foreground)]">
									({links.length + restrictions.length})
								</span>
							</summary>
							<div class="mt-4 space-y-5 border-l-2 border-[color:var(--border)] pl-4">
								<MetricEntityCollection
									resource="rhymeLinks"
									title="Enlaces"
									rows={links}
									keyFields={['enlace_id']}
									fields={groupedRhymeLinkFields}
									defaults={{ esquema_rima_id: patternId, bloque_origen: 1, ubicacion_origen: 'final', desplazamiento_bloque: 0, ubicacion_destino: 'final', tipo_enlace: 'misma_rima', obligatorio: true }}
									emptyMessage="Este esquema no necesita enlaces adicionales."
									compact
								/>
								<MetricEntityCollection
									resource="rhymeRestrictions"
									title="Restricciones"
									rows={restrictions}
									keyFields={['restriccion_id']}
									fields={groupedRhymeRestrictionFields}
									defaults={{ esquema_rima_id: patternId, tipo: 'otra', obligatoria: true }}
									emptyMessage="Este esquema no necesita restricciones adicionales."
									compact
								/>
							</div>
						</details>
					</div>
				{/snippet}
			</MetricEntityCollection>
		</div>
	</details>

	<details open={patternCombinations.length > 0}>
		<summary class="flex cursor-pointer items-center justify-between gap-3 text-sm font-semibold">
			<span>Combinaciones admitidas</span>
			<span class="font-normal text-[color:var(--muted-foreground)]">
				{patternCombinations.length}
			</span>
		</summary>
		<div class="mt-4">
			<MetricEntityCollection
				resource="patternCombinations"
				title="Tipologías que acoplan medida y rima"
				description="Úsalas cuando no todas las combinaciones entre los esquemas métricos y de rima sean válidas. Cada fila enlaza una pareja admitida sin crear otra arquitectura."
				rows={patternCombinations}
				keyFields={['variedad_id']}
				fields={patternCombinationFields}
				defaults={{
					arquitectura_id: props.configurationId,
					preferente: false,
					estado_revision: 'borrador',
					activo: true,
					orden: 1
				}}
				emptyMessage="Los esquemas métricos y de rima son independientes o todavía no se han declarado variedades."
				compact
			/>
		</div>
	</details>

	<details>
		<summary class="cursor-pointer text-sm font-semibold">Secciones y repeticiones</summary>
		<div class="mt-4 space-y-4">
			<MetricEntityCollection resource="sections" title="Estructura interna" rows={sections}
				keyFields={['seccion_id']} fields={sectionFields}
				defaults={{ arquitectura_id: props.configurationId, orden: 1 }} compact />
			<MetricEntityCollection resource="repetitionPatterns" title="Repeticiones" rows={repetitionPatterns}
				keyFields={['repeticion_id']} fields={repetitionFields}
				defaults={{ arquitectura_id: props.configurationId, tipo: 'otro', ambito: defaultScope, modalidad: 'admitida', estado_revision: 'borrador' }} compact>
				{#snippet rowContent(pattern)}
					{@const patternId = String(pattern.repeticion_id)}
					{@const positions = rowsForRepetitionPattern(props.domain.repetitionPositions, patternId)}
					<div class="space-y-4">
						<div>
							<p class="mb-2 text-xs font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Orden de repetición
							</p>
							<MetricRepetitionPreview
								{positions}
								blockLabel={pattern.tipo === 'palabra_final' ? 'Estrofa' : 'Bloque'}
							/>
						</div>
						<details>
							<summary class="cursor-pointer text-sm font-medium">
								Editar {positions.length} {positions.length === 1 ? 'posición' : 'posiciones'}
							</summary>
							<div class="mt-4">
								<MetricEntityCollection
									resource="repetitionPositions"
									title="Posiciones de este esquema"
									rows={positions}
									keyFields={['posicion_id']}
									fields={groupedRepetitionPositionFields}
									defaults={{ repeticion_id: patternId, bloque: 1, posicion: positions.length + 1 }}
									compact
								/>
							</div>
						</details>
					</div>
				{/snippet}
			</MetricEntityCollection>
		</div>
	</details>

	<details open={configurationTraits.length > 0}>
		<summary class="flex cursor-pointer items-center justify-between gap-3 text-sm font-semibold">
			<span>Rasgos transversales</span>
			<span class="font-normal text-[color:var(--muted-foreground)]">
				{configurationTraits.length}
			</span>
		</summary>
		<div class="mt-4">
			<MetricEntityCollection resource="configurationTraits" title="Rasgos de esta arquitectura"
				rows={configurationTraits}
				keyFields={['arquitectura_id', 'rasgo_id', 'modalidad']} fields={configurationTraitFields}
				defaults={{ arquitectura_id: props.configurationId, modalidad: 'definitoria' }} compact />
		</div>
	</details>

	<MetricChoiceGroupsEditor
		configurationId={props.configurationId}
		domain={props.domain}
		metres={props.metres}
	/>
</div>
