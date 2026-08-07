<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricFormLabel,
		metricReviewStateLabel,
		type MetricCatalogDomainRow,
		type MetricCatalogDomainData,
		type MetricCatalogForm,
		type MetricCatalogConfiguration
	} from '$lib/metrica/catalogo';

	const props = $props<{
		domain: MetricCatalogDomainData;
		forms: MetricCatalogForm[];
		configurations: MetricCatalogConfiguration[];
	}>();

	const reviewOptions: MetricEntityOption[] = METRIC_CATALOG_REVIEW_STATES.map((state) => ({
		value: state,
		label: metricReviewStateLabel(state)
	}));
	const formOptions = $derived(
		props.forms.map((form: MetricCatalogForm) => ({ value: form.forma_id, label: metricFormLabel(form) }))
	);
	const traditionOptions = $derived(
		props.domain.traditions.map((row: MetricCatalogDomainRow) => ({
			value: String(row.tradicion_id),
			label: String(row.nombre)
		}))
	);
	const sourceOptions = $derived(
		props.domain.sources.map((row: MetricCatalogDomainRow) => ({
			value: String(row.fuente_id),
			label: String(row.cita || row.titulo)
		}))
	);
	const denominationTargetOptions = $derived<MetricEntityOption[]>([
		...props.forms.map((form: MetricCatalogForm) => ({
			value: `forma_id:${form.forma_id}`,
			label: `Forma · ${metricFormLabel(form)}`
		})),
		...props.configurations.map((configuration: MetricCatalogConfiguration) => ({
			value: `arquitectura_id:${configuration.arquitectura_id}`,
			label: `Arquitectura · ${configuration.nombre}`
		})),
		...props.domain.metricPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: `esquema_metrico_id:${row.esquema_metrico_id}`,
			label: `Esquema métrico · ${String(row.nombre || `Esquema ${index + 1}`)}`
		})),
		...props.domain.rhymePatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: `esquema_rima_id:${row.esquema_rima_id}`,
			label: `Esquema de rima · ${String(row.nombre || row.notacion || `Esquema ${index + 1}`)}`
		})),
		...props.domain.sections.map((row: MetricCatalogDomainRow) => ({
			value: `seccion_id:${row.seccion_id}`,
			label: `Sección · ${String(row.nombre || row.tipo_seccion)}`
		})),
		...props.domain.repetitionPatterns.map((row: MetricCatalogDomainRow, index: number) => ({
			value: `repeticion_id:${row.repeticion_id}`,
			label: `Repetición · ${String(row.descripcion || row.regla || `Esquema ${index + 1}`)}`
		})),
		...props.domain.patternCombinations.map((row: MetricCatalogDomainRow, index: number) => ({
			value: `variedad_id:${row.variedad_id}`,
			label: `Variedad · ${String(row.nombre || `Variedad ${index + 1}`)}`
		}))
	]);

	const traditionFields = $derived<MetricEntityField[]>([
		{ key: 'nombre', label: 'Nombre', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activa', type: 'checkbox' }
	]);
	const formTraditionFields = $derived<MetricEntityField[]>([
		{ key: 'forma_id', label: 'Forma', type: 'select', options: formOptions, required: true },
		{ key: 'tradicion_id', label: 'Tradición', type: 'select', options: traditionOptions, required: true },
		{ key: 'cronologia', label: 'Cronología' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const aliasFields = $derived<MetricEntityField[]>([
		{
			key: 'destino',
			label: 'Entidad denominada',
			type: 'select',
			options: denominationTargetOptions,
			required: true,
			help: 'El nombre debe apuntar al nivel exacto que nombra: forma, arquitectura, esquema, variedad, sección o repetición.'
		},
		{ key: 'nombre', label: 'Nombre alternativo', required: true },
		{ key: 'slug_normalizado', label: 'Slug normalizado', required: true },
		{ key: 'idioma', label: 'Idioma' },
		{ key: 'fuente_id', label: 'Fuente', type: 'select', options: sourceOptions },
		{ key: 'preferente', label: 'Preferente', type: 'checkbox' }
	]);
	const relationFields = $derived<MetricEntityField[]>([
		{ key: 'forma_origen_id', label: 'Forma de origen', type: 'select', options: formOptions, required: true },
		{ key: 'forma_destino_id', label: 'Forma relacionada', type: 'select', options: formOptions, required: true },
		{
			key: 'tipo_relacion',
			label: 'Relación',
			type: 'select',
			required: true,
			options: [
				{ value: 'subtipo_de', label: 'Subtipo de' },
				{ value: 'variante_historica_de', label: 'Variante histórica de' },
				{ value: 'derivada_de', label: 'Derivada de' },
				{ value: 'compuesta_por', label: 'Compuesta por' },
				{ value: 'sucede_historicamente_a', label: 'Sucede históricamente a' },
				{ value: 'relacionada_con', label: 'Relacionada con' },
				{ value: 'contrasta_con', label: 'Contrasta con' },
				{ value: 'equivalente_de', label: 'Equivalente de' }
			]
		},
		{ key: 'cantidad_min', label: 'Cantidad mínima', type: 'number' },
		{ key: 'cantidad_max', label: 'Cantidad máxima', type: 'number' },
		{ key: 'orden_composicion', label: 'Orden', type: 'number' },
		{ key: 'nota', label: 'Nota', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	]);
</script>

<div class="space-y-6">
	<MetricEntityCollection
		resource="traditions"
		title="Tradiciones métricas"
		description="El ámbito histórico del que procede una forma. Es una pertenencia, no una herencia: no organiza el selector ni transmite rasgos."
		rows={props.domain.traditions}
		keyFields={['tradicion_id']}
		fields={traditionFields}
		defaults={{ estado_revision: 'borrador', activo: true }}
	/>
	<MetricEntityCollection
		resource="formTraditions"
		title="Relaciones entre formas y tradiciones"
		rows={props.domain.formTraditions}
		keyFields={['forma_id', 'tradicion_id']}
		fields={formTraditionFields}
	/>
	<MetricEntityCollection
		resource="aliases"
		title="Denominaciones alternativas"
		description="Nombres equivalentes, históricos o abreviados asociados a la entidad exacta. Por ejemplo, «Cuarteta» denomina el esquema cruzado abab de redondilla, no toda la forma."
		rows={props.domain.aliases}
		keyFields={['alias_id']}
		fields={aliasFields}
		defaults={{ preferente: false }}
	/>
	<MetricEntityCollection
		resource="formRelations"
		title="Relaciones entre formas"
		rows={props.domain.formRelations}
		keyFields={['relacion_id']}
		fields={relationFields}
		defaults={{ tipo_relacion: 'relacionada_con', estado_revision: 'borrador' }}
	/>
</div>
