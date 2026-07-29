<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricReviewStateLabel,
		type MetricCatalogDomainData,
		type MetricCatalogDomainRow,
		type MetricCatalogOption
	} from '$lib/metrica/catalogo';

	const props = $props<{
		configurationId: string;
		domain: MetricCatalogDomainData;
		metres: MetricCatalogOption[];
	}>();

	const groups = $derived(
		props.domain.choiceGroups
			.filter(
				(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	const sections = $derived(
		props.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
		)
	);
	const sectionOptions = $derived<MetricEntityOption[]>(
		sections.map((row: MetricCatalogDomainRow) => ({
			value: String(row.seccion_id),
			label: String(row.nombre || row.tipo_seccion)
		}))
	);
	const reviewOptions: MetricEntityOption[] = METRIC_CATALOG_REVIEW_STATES.map((state) => ({
		value: state,
		label: metricReviewStateLabel(state)
	}));

	const groupFields = $derived<MetricEntityField[]>([
		{ key: 'configuracion_id', label: 'Configuración', type: 'hidden' },
		{ key: 'slug', label: 'Slug', required: true },
		{
			key: 'nombre',
			label: 'Pregunta que verá el editor',
			required: true,
			placeholder: '¿Qué patrón tiene la mudanza?'
		},
		{
			key: 'ayuda_editor',
			label: 'Ayuda breve',
			type: 'textarea',
			help: 'Explica qué debe observar el editor, no la teoría completa de la forma.'
		},
		{
			key: 'dimension',
			label: 'Dimensión',
			type: 'select',
			required: true,
			options: [
				{ value: 'metro', label: 'Medida' },
				{ value: 'rima', label: 'Rima' },
				{ value: 'estructura', label: 'Estructura' },
				{ value: 'repeticion', label: 'Repetición' },
				{ value: 'rasgo', label: 'Rasgo' }
			]
		},
		{
			key: 'alcance',
			label: 'Dónde se responde',
			type: 'select',
			required: true,
			options: [
				{ value: 'secuencia', label: 'Una vez para toda la secuencia' },
				{ value: 'unidad', label: 'En cada unidad interna aplicable' }
			]
		},
		{
			key: 'seccion_id',
			label: 'Clase de unidad',
			type: 'select',
			options: sectionOptions,
			help: 'Solo se utiliza con alcance por unidad. Limita la pregunta, por ejemplo, a cada copla.'
		},
		{
			key: 'selecciones_min',
			maxKey: 'selecciones_max',
			label: 'Número de respuestas',
			type: 'integerRange',
			help: '0–1 crea una pregunta opcional; 1–1 exige una respuesta; 1–2 permite combinar dos opciones.'
		},
		{
			key: 'permite_aplicar_global',
			label: 'Permitir aplicar la respuesta a todas las unidades',
			type: 'checkbox'
		},
		{ key: 'orden', label: 'Orden', type: 'number' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	]);

	function targetOptions(group: MetricCatalogDomainRow): MetricEntityOption[] {
		const dimension = String(group.dimension);
		if (dimension === 'metro') {
			const metricPatterns = props.domain.metricPatterns.filter(
				(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
			);
			return [
				...props.metres.map((option: MetricCatalogOption) => ({
					value: `metro_id:${option.id}`,
					label: option.label
				})),
				...metricPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
					value: `patron_metrico_id:${row.patron_metrico_id}`,
					label: `Patrón: ${String(row.nombre || `métrico ${index + 1}`)}`
				}))
			];
		}
		if (dimension === 'rima') {
			return props.domain.rhymePatterns
				.filter(
					(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
				)
				.map((row: MetricCatalogDomainRow, index: number) => ({
					value: `patron_rima_id:${row.patron_rima_id}`,
					label: String(row.nombre || row.esquema || `Patrón de rima ${index + 1}`)
				}));
		}
		if (dimension === 'estructura') {
			return sections.map((row: MetricCatalogDomainRow) => ({
				value: `seccion_id:${row.seccion_id}`,
				label: String(row.nombre || row.tipo_seccion)
			}));
		}
		if (dimension === 'repeticion') {
			return props.domain.repetitionPatterns
				.filter(
					(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
				)
				.map((row: MetricCatalogDomainRow, index: number) => ({
					value: `patron_repeticion_id:${row.patron_repeticion_id}`,
					label: String(row.descripcion || row.regla || `Repetición ${index + 1}`)
				}));
		}

		const admittedTraitIds = new Set(
			props.domain.configurationTraits
				.filter(
					(row: MetricCatalogDomainRow) => row.configuracion_id === props.configurationId
				)
				.map((row: MetricCatalogDomainRow) => String(row.rasgo_id))
		);
		const traits = props.domain.traits.filter((row: MetricCatalogDomainRow) =>
			admittedTraitIds.has(String(row.rasgo_id))
		);
		const values = props.domain.traitValues.filter((row: MetricCatalogDomainRow) =>
			admittedTraitIds.has(String(row.rasgo_id))
		);
		return [
			...traits
				.filter((row: MetricCatalogDomainRow) => row.tipo_valor === 'booleano')
				.map((row: MetricCatalogDomainRow) => ({
					value: `rasgo_id:${row.rasgo_id}`,
					label: String(row.nombre)
				})),
			...values.map((row: MetricCatalogDomainRow) => {
				const trait = traits.find(
					(item: MetricCatalogDomainRow) => item.rasgo_id === row.rasgo_id
				);
				return {
					value: `valor_rasgo_id:${row.valor_id}`,
					label: `${String(trait?.nombre ?? 'Rasgo')}: ${String(row.nombre)}`
				};
			})
		];
	}

	function optionFields(group: MetricCatalogDomainRow): MetricEntityField[] {
		return [
			{ key: 'grupo_eleccion_id', label: 'Grupo', type: 'hidden' },
			{ key: 'slug', label: 'Slug', required: true },
			{ key: 'nombre', label: 'Respuesta visible', required: true },
			{ key: 'descripcion', label: 'Explicación', type: 'textarea' },
			{
				key: 'objetivo',
				label: 'Dato normalizado que representa',
				type: 'select',
				options: targetOptions(group),
				required: true
			},
			{
				key: 'materializa_seccion_id',
				label: 'Si se elige, pedir el rango de',
				type: 'select',
				options: sectionOptions,
				help: 'Déjalo vacío salvo que esta respuesta haga aparecer materialmente una sección.'
			},
			{
				key: 'extension_desde_seccion_id',
				label: 'Calcular su extensión desde',
				type: 'select',
				options: sectionOptions,
				help: 'Opcional. Evita volver a pedir una longitud que coincide con otra sección, como la repetición total de una cabeza.'
			},
			{ key: 'orden', label: 'Orden', type: 'number' },
			{ key: 'activo', label: 'Activa', type: 'checkbox' }
		];
	}
</script>

<section class="space-y-4 border-t border-[color:var(--border)] pt-5">
	<div>
		<h4 class="font-medium">Preguntas derivadas para el editor</h4>
		<p class="mt-1 max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			Aquí se declaran únicamente las alternativas admitidas que interesa registrar en el
			corpus. Una norma con un único resultado no genera pregunta; una diferencia respecto de
			estas opciones se registra después como desviación.
		</p>
	</div>

	<MetricEntityCollection
		resource="choiceGroups"
		title="Grupos de elección"
		rows={groups}
		keyFields={['grupo_eleccion_id']}
		fields={groupFields}
		defaults={{
			configuracion_id: props.configurationId,
			dimension: 'rima',
			alcance: 'secuencia',
			selecciones_min: 1,
			selecciones_max: 1,
			permite_aplicar_global: false,
			estado_revision: 'borrador',
			activo: true,
			orden: 1
		}}
		emptyMessage="Esta configuración no plantea ninguna elección explícita al editor."
		compact
	/>

	{#each groups as group (String(group.grupo_eleccion_id))}
		<div class="border-l-2 border-[color:var(--border)] pl-4">
			<MetricEntityCollection
				resource="choiceOptions"
				title={`Respuestas: ${String(group.nombre)}`}
				description="Cada respuesta apunta a un metro, patrón, sección, repetición o valor de rasgo ya formalizado."
				rows={props.domain.choiceOptions.filter(
					(row: MetricCatalogDomainRow) =>
						row.grupo_eleccion_id === group.grupo_eleccion_id
				)}
				keyFields={['opcion_eleccion_id']}
				fields={optionFields(group)}
				defaults={{
					grupo_eleccion_id: group.grupo_eleccion_id,
					activo: true,
					orden: 1
				}}
				emptyMessage="Añade al menos una respuesta posible."
				compact
			/>
		</div>
	{/each}
</section>
