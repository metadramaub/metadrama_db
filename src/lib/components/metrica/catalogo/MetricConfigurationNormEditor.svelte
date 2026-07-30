<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import MetricChoiceGroupsEditor from './MetricChoiceGroupsEditor.svelte';
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
			(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
		)
	);
	const metricPatternIds = $derived(
		new Set(metricPatterns.map((row: MetricCatalogDomainRow) => String(row.patron_metrico_id)))
	);
	const metricPatternOptions = $derived(
		metricPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.patron_metrico_id),
			label: String(row.nombre || `Patrón métrico ${index + 1}`)
		}))
	);
	const soleMetricPatternId = $derived(
		metricPatterns.length === 1 ? String(metricPatterns[0].patron_metrico_id) : null
	);
	const rhymePatterns = $derived(
		props.domain.rhymePatterns.filter(
			(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
		)
	);
	const rhymePatternOptions = $derived(
		rhymePatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.patron_rima_id),
			label: String(row.nombre || row.esquema || `Patrón de rima ${index + 1}`)
		}))
	);
	const patternCombinations = $derived(
		props.domain.patternCombinations
			.filter(
				(row: MetricCatalogDomainRow) =>
					row.configuracion_id === props.configurationId
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	const repetitionPatterns = $derived(
		props.domain.repetitionPatterns.filter(
			(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
		)
	);
	const repetitionPatternIds = $derived(
		new Set(
			repetitionPatterns.map((row: MetricCatalogDomainRow) =>
				String(row.patron_repeticion_id)
			)
		)
	);
	const repetitionPatternOptions = $derived(
		repetitionPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: String(row.patron_repeticion_id),
			label: String(row.regla || `Repetición ${index + 1}`)
		}))
	);
	const soleRepetitionPatternId = $derived(
		repetitionPatterns.length === 1
			? String(repetitionPatterns[0].patron_repeticion_id)
			: null
	);
	const sections = $derived(
		props.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
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
					String(row.configuracion_id) !== props.configurationId && row.activo
			)
			.map((row: MetricCatalogDomainRow) => {
				const form = props.domain.forms.find(
					(candidate: MetricCatalogDomainRow) =>
						candidate.forma_id === row.forma_id
				);
				return {
					value: String(row.configuracion_id),
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
	const verseModelOptions = $derived(
		props.domain.verseModels.map((row: MetricCatalogDomainRow) => ({
			value: String(row.modelo_verso_id),
			label: String(row.nombre)
		}))
	);
	const measureOptions = $derived([
		...metreOptions.map((option: MetricEntityOption) => ({
			value: `metro:${option.value}`,
			label: option.label
		})),
		...verseModelOptions.map((option: MetricEntityOption) => ({
			value: `modelo:${option.value}`,
			label: `Modelo: ${option.label}`
		}))
	]);
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
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
		{
			key: 'nombre',
			label: 'Nombre breve',
			help: 'Sirve para distinguir este patrón cuando una configuración tiene más de uno.',
			placeholder: 'Octosílabo repetido'
		},
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{
			key: 'ambito',
			label: 'Ámbito de aplicación',
			type: 'select',
			options: scopeOptions,
			required: true,
			help: 'Dónde se completa o reinicia el patrón. «Unidad genérica» es un valor provisional que debe sustituirse.'
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
			key: 'patron_metrico_id',
			label: 'Patrón',
			type: soleMetricPatternId ? 'hidden' : 'select',
			options: metricPatternOptions,
			required: true,
			help: 'Solo se elige cuando esta configuración contiene varios patrones métricos.'
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
			key: 'patron_metrico_id',
			label: 'Patrón',
			type: soleMetricPatternId ? 'hidden' : 'select',
			options: metricPatternOptions,
			required: true
		},
		{ key: 'metro_id', label: 'Metro permitido', type: 'select', options: metreOptions, required: true },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const rhymePatternFields = $derived<MetricEntityField[]>([
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
		{ key: 'nombre', label: 'Nombre interno' },
		{ key: 'esquema', label: 'Esquema', placeholder: 'ABBAACCDDC' },
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
			key: 'comportamiento',
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
			help: 'Describe la lógica computable del patrón. La fijeza indica después cuánto obliga esa lógica.'
		},
		{
			key: 'fijeza',
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
			help: 'Indica cuánto obliga este patrón dentro de la configuración.'
		},
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	]);
	const rhymePositionFields = $derived<MetricEntityField[]>([
		{
			key: 'patron_rima_id',
			label: 'Patrón',
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
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'nombre', label: 'Nombre visible', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{
			key: 'patron_metrico_id',
			label: 'Patrón métrico',
			type: 'select',
			options: metricPatternOptions,
			required: true
		},
		{
			key: 'patron_rima_id',
			label: 'Patrón de rima',
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
			key: 'patron_rima_id',
			label: 'Patrón',
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
			key: 'patron_rima_id',
			label: 'Patrón',
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
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
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
			key: 'configuracion_referenciada_id',
			label: 'Configuración reutilizada',
			type: 'select',
			options: reusableConfigurationOptions,
			help: 'Úsala cuando la sección sea una realización de otra forma ya formalizada, como una redondilla dentro de una novena.'
		},
		{ key: 'patron_metrico_id', label: 'Patrón métrico', type: 'select', options: metricPatternOptions },
		{ key: 'patron_rima_id', label: 'Patrón de rima', type: 'select', options: rhymePatternOptions },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const repetitionFields: MetricEntityField[] = [
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
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
			key: 'fijeza',
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
			key: 'patron_repeticion_id',
			label: 'Patrón',
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
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
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

	function hideRhymePatternField(fields: MetricEntityField[]): MetricEntityField[] {
		return fields.map((field) =>
			field.key === 'patron_rima_id' ? { ...field, type: 'hidden' } : field
		);
	}

	function rhymePatternLabel(pattern: MetricCatalogDomainRow, index: number): string {
		return String(pattern.nombre || pattern.esquema || `Patrón de rima ${index + 1}`);
	}

	function rowsForRhymePattern(
		rows: MetricCatalogDomainRow[],
		patternId: string
	): MetricCatalogDomainRow[] {
		return rows.filter((row) => String(row.patron_rima_id) === patternId);
	}
</script>

<div class="space-y-5 border-t border-[color:var(--border)] pt-5">
	<details>
		<summary class="cursor-pointer text-sm font-semibold">Medida de los versos</summary>
		<div class="mt-4 space-y-4">
			<MetricEntityCollection resource="metricPatterns" title="Patrones métricos" rows={metricPatterns}
				keyFields={['patron_metrico_id']} fields={metricPatternFields}
				defaults={{ configuracion_id: props.configurationId, ambito: defaultScope, tipo: 'secuencia_fija', estado_revision: 'borrador' }} compact />
			<MetricEntityCollection resource="metricPositions" title="Posiciones ordenadas"
				rows={props.domain.metricPositions.filter((row: MetricCatalogDomainRow) => metricPatternIds.has(String(row.patron_metrico_id)))}
				keyFields={['posicion_id']} fields={metricPositionFields}
				defaults={{ patron_metrico_id: soleMetricPatternId, alternativa: 1, posicion: 1, opcional: false }} compact />
			<MetricEntityCollection resource="metricOptions" title="Conjunto de medidas permitidas"
				rows={props.domain.metricOptions.filter((row: MetricCatalogDomainRow) => metricPatternIds.has(String(row.patron_metrico_id)))}
				keyFields={['patron_metrico_id', 'metro_id']} fields={metricOptionFields}
				defaults={{ patron_metrico_id: soleMetricPatternId }} compact />
		</div>
	</details>

	<details>
		<summary class="cursor-pointer text-sm font-semibold">Rima</summary>
		<div class="mt-4 space-y-4">
			<MetricEntityCollection
				resource="rhymePatterns"
				title="Alternativas de rima"
				description="Cada registro es una distribución posible dentro de esta configuración. Cambiar el esquema no crea por sí solo otra configuración."
				rows={rhymePatterns}
				keyFields={['patron_rima_id']}
				fields={rhymePatternFields}
				labelFields={['nombre', 'esquema']}
				emptyMessage="Esta configuración todavía no tiene alternativas de rima."
				defaults={{ configuracion_id: props.configurationId, ambito: defaultScope, comportamiento: 'secuencia_fija', fijeza: 'admitido', estado_revision: 'borrador' }}
				compact
			/>

			<details class="border-l-2 border-[color:var(--border)] pl-4">
				<summary class="cursor-pointer text-sm font-medium">Estructura computable de los patrones</summary>
				<div class="mt-3 space-y-3">
					<p class="max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
						Las letras del esquema se guardan también como posiciones para que el sistema pueda
						compararlas. En una estrofa de cinco versos, cada patrón tiene cinco posiciones.
						Normalmente basta con editar el esquema; abre un patrón solo para revisar su detalle.
					</p>

					{#each rhymePatterns as pattern, index (String(pattern.patron_rima_id))}
						{@const patternId = String(pattern.patron_rima_id)}
						<details class="border border-[color:var(--border)] bg-[color:var(--background)]">
							<summary class="flex cursor-pointer items-center justify-between gap-3 px-4 py-3 text-sm">
								<span class="font-medium">{rhymePatternLabel(pattern, index)}</span>
								{#if pattern.esquema}
									<code class="shrink-0 text-xs">{String(pattern.esquema)}</code>
								{/if}
							</summary>
							<div class="space-y-5 border-t border-[color:var(--border)] p-4">
								<MetricEntityCollection
									resource="rhymePositions"
									title="Posiciones del esquema"
									description="Una posición por verso; la clase de rima corresponde a la letra del esquema."
									rows={rowsForRhymePattern(props.domain.rhymePositions, patternId)}
									keyFields={['posicion_id']}
									fields={groupedRhymePositionFields}
									defaults={{ patron_rima_id: patternId, bloque: 1, posicion: 1, ubicacion: 'final', suelto: false, opcional: false }}
									compact
								/>

								<details>
									<summary class="cursor-pointer text-sm font-medium">Reglas avanzadas</summary>
									<div class="mt-4 space-y-5 border-l-2 border-[color:var(--border)] pl-4">
										<MetricEntityCollection
											resource="rhymeLinks"
											title="Enlaces"
											rows={rowsForRhymePattern(props.domain.rhymeLinks, patternId)}
											keyFields={['enlace_id']}
											fields={groupedRhymeLinkFields}
											defaults={{ patron_rima_id: patternId, bloque_origen: 1, ubicacion_origen: 'final', desplazamiento_bloque: 0, ubicacion_destino: 'final', tipo_enlace: 'misma_rima', obligatorio: true }}
											emptyMessage="Este patrón no necesita enlaces adicionales."
											compact
										/>
										<MetricEntityCollection
											resource="rhymeRestrictions"
											title="Restricciones"
											rows={rowsForRhymePattern(props.domain.rhymeRestrictions, patternId)}
											keyFields={['restriccion_id']}
											fields={groupedRhymeRestrictionFields}
											defaults={{ patron_rima_id: patternId, tipo: 'otra', obligatoria: true }}
											emptyMessage="Este patrón no necesita restricciones adicionales."
											compact
										/>
									</div>
								</details>
							</div>
						</details>
					{:else}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							Añade primero una alternativa de rima.
						</p>
					{/each}
				</div>
			</details>
		</div>
	</details>

	<details>
		<summary class="cursor-pointer text-sm font-semibold">Combinaciones admitidas</summary>
		<div class="mt-4">
			<MetricEntityCollection
				resource="patternCombinations"
				title="Tipologías que acoplan medida y rima"
				description="Úsalas cuando no todas las combinaciones entre los patrones métricos y de rima sean válidas. Cada fila enlaza una pareja admitida sin crear otra configuración."
				rows={patternCombinations}
				keyFields={['combinacion_id']}
				fields={patternCombinationFields}
				defaults={{
					configuracion_id: props.configurationId,
					preferente: false,
					estado_revision: 'borrador',
					activo: true,
					orden: 1
				}}
				emptyMessage="Los patrones métricos y de rima son independientes o todavía no se han declarado combinaciones."
				compact
			/>
		</div>
	</details>

	<details>
		<summary class="cursor-pointer text-sm font-semibold">Secciones y repeticiones</summary>
		<div class="mt-4 space-y-4">
			<MetricEntityCollection resource="sections" title="Estructura interna" rows={sections}
				keyFields={['seccion_id']} fields={sectionFields}
				defaults={{ configuracion_id: props.configurationId, orden: 1 }} compact />
			<MetricEntityCollection resource="repetitionPatterns" title="Patrones de repetición" rows={repetitionPatterns}
				keyFields={['patron_repeticion_id']} fields={repetitionFields}
				defaults={{ configuracion_id: props.configurationId, tipo: 'otro', ambito: defaultScope, fijeza: 'admitida', estado_revision: 'borrador' }} compact />
			<MetricEntityCollection resource="repetitionPositions" title="Posiciones de repetición"
				rows={props.domain.repetitionPositions.filter((row: MetricCatalogDomainRow) => repetitionPatternIds.has(String(row.patron_repeticion_id)))}
				keyFields={['posicion_id']} fields={repetitionPositionFields}
				defaults={{ patron_repeticion_id: soleRepetitionPatternId, bloque: 1, posicion: 1 }} compact />
		</div>
	</details>

	<details>
		<summary class="cursor-pointer text-sm font-semibold">Rasgos transversales</summary>
		<div class="mt-4">
			<MetricEntityCollection resource="configurationTraits" title="Rasgos de esta configuración"
				rows={props.domain.configurationTraits.filter((row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId)}
				keyFields={['configuracion_id', 'rasgo_id', 'modalidad']} fields={configurationTraitFields}
				defaults={{ configuracion_id: props.configurationId, modalidad: 'definitoria' }} compact />
		</div>
	</details>

	<MetricChoiceGroupsEditor
		configurationId={props.configurationId}
		domain={props.domain}
		metres={props.metres}
	/>
</div>
