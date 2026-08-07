<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricFormLabel,
		metricReviewStateLabel,
		type MetricCatalogConfiguration,
		type MetricCatalogDomainData,
		type MetricCatalogDomainRow,
		type MetricCatalogForm,
		type MetricCatalogOption
	} from '$lib/metrica/catalogo';

	const props = $props<{
		domain: MetricCatalogDomainData;
		forms: MetricCatalogForm[];
		configurations: MetricCatalogConfiguration[];
		metres: MetricCatalogOption[];
	}>();

	const reviewOptions: MetricEntityOption[] = METRIC_CATALOG_REVIEW_STATES.map((state) => ({
		value: state,
		label: metricReviewStateLabel(state)
	}));
	const metreOptions = $derived(
		props.metres.map((option: MetricCatalogOption) => ({ value: option.id, label: option.label }))
	);
	const verseModelOptions = $derived(
		props.domain.verseModels.map((row: MetricCatalogDomainRow) => ({
			value: String(row.metro_id),
			label: String(row.nombre)
		}))
	);
	const traitOptions = $derived(
		props.domain.traits.map((row: MetricCatalogDomainRow) => ({
			value: String(row.rasgo_id),
			label: String(row.nombre)
		}))
	);
	const sourceOptions = $derived(
		props.domain.sources.map((row: MetricCatalogDomainRow) => ({
			value: String(row.fuente_id),
			label: String(row.titulo)
		}))
	);
	const formOptions = $derived(
		props.forms.map((form: MetricCatalogForm) => ({ value: form.forma_id, label: metricFormLabel(form) }))
	);
	function formLabel(formId: string): string {
		const form = props.forms.find((candidate: MetricCatalogForm) => candidate.forma_id === formId);
		return form ? metricFormLabel(form) : 'Forma';
	}
	const traditionOptions = $derived(
		props.domain.traditions.map((row: MetricCatalogDomainRow) => ({
			value: String(row.tradicion_id),
			label: String(row.nombre)
		}))
	);
	const configurationOptions = $derived(
		props.configurations.map((row: MetricCatalogConfiguration) => ({
			value: row.arquitectura_id,
			label: `${formLabel(String(row.forma_id))}: ${row.nombre}`
		}))
	);
	const metricPatternOptions = $derived(
		props.domain.metricPatterns.map((row: MetricCatalogDomainRow) => ({
			value: String(row.notacion_metrico_id),
			label: String(row.nombre || `${row.tipo_secuencia} · ${row.ambito}`)
		}))
	);
	const rhymePatternOptions = $derived(
		props.domain.rhymePatterns.map((row: MetricCatalogDomainRow) => ({
			value: String(row.notacion_rima_id),
			label: String(row.nombre || row.notacion || 'Esquema sin nombre')
		}))
	);
	const claimTargetOptions = $derived([
		...formOptions.map((option: MetricEntityOption) => ({
			value: `forma_id:${option.value}`,
			label: `Forma: ${option.label}`
		})),
		...traditionOptions.map((option: MetricEntityOption) => ({
			value: `tradicion_id:${option.value}`,
			label: `Tradición: ${option.label}`
		})),
		...configurationOptions.map((option: MetricEntityOption) => ({
			value: `arquitectura_id:${option.value}`,
			label: `Arquitectura: ${option.label}`
		})),
		...metricPatternOptions.map((option: MetricEntityOption) => ({
			value: `esquema_metrico_id:${option.value}`,
			label: `Esquema métrico: ${option.label}`
		})),
		...rhymePatternOptions.map((option: MetricEntityOption) => ({
			value: `esquema_rima_id:${option.value}`,
			label: `Esquema de rima: ${option.label}`
		})),
		...traitOptions.map((option: MetricEntityOption) => ({
			value: `rasgo_id:${option.value}`,
			label: `Rasgo: ${option.label}`
		}))
	]);

	const verseModelFields = $derived<MetricEntityField[]>([
		{ key: 'nombre', label: 'Nombre', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{
			key: 'tipo',
			label: 'Tipo',
			type: 'select',
			required: true,
			options: [
				{ value: 'simple', label: 'Simple' },
				{ value: 'compuesto', label: 'Compuesto' }
			]
		},
		{ key: 'silabas', label: 'Sílabas', type: 'number', required: true },
		{ key: 'tipo_cesura', label: 'Tipo de cesura' },
		{ key: 'orden', label: 'Orden', type: 'number' },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	]);
	const segmentFields = $derived<MetricEntityField[]>([
		{ key: 'metro_id', label: 'Metro', type: 'select', options: verseModelOptions, required: true },
		{ key: 'alternativa', label: 'Alternativa', type: 'number', required: true },
		{ key: 'posicion', label: 'Posición', type: 'number', required: true },
		{ key: 'silabas', label: 'Sílabas', type: 'number', required: true },
		{ key: 'funcion', label: 'Función' },
		{ key: 'pausa_posterior', label: 'Pausa posterior' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const traitFields: MetricEntityField[] = [
		{ key: 'nombre', label: 'Nombre', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{
			key: 'tipo_valor',
			label: 'Tipo de valor',
			type: 'select',
			required: true,
			options: [
				{ value: 'booleano', label: 'Sí/no' },
				{ value: 'catalogo', label: 'Catálogo de valores' },
				{ value: 'texto_controlado', label: 'Texto controlado' },
				{ value: 'numero', label: 'Número' }
			]
		},
		{
			key: 'observabilidad',
			label: 'Observabilidad',
			type: 'select',
			required: true,
			options: [
				{ value: 'directa', label: 'Directa' },
				{ value: 'especializada', label: 'Especializada' },
				{ value: 'derivada', label: 'Derivada' }
			]
		},
		{ key: 'demarcable', label: 'Útil para el demarcador', type: 'checkbox' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	];
	const traitValueFields = $derived<MetricEntityField[]>([
		{ key: 'rasgo_id', label: 'Rasgo', type: 'select', options: traitOptions, required: true },
		{ key: 'nombre', label: 'Valor', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	]);
	const sourceFields: MetricEntityField[] = [
		{ key: 'titulo', label: 'Título', required: true },
		{ key: 'autoria', label: 'Autoría' },
		{ key: 'tipo', label: 'Tipo bibliográfico' },
		{ key: 'anio', label: 'Año', type: 'number' },
		{ key: 'publicacion', label: 'Publicación' },
		{ key: 'doi', label: 'DOI' },
		{ key: 'url', label: 'URL' },
		{ key: 'cita', label: 'Cita normalizada', type: 'textarea' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	];
	const claimFields = $derived<MetricEntityField[]>([
		{ key: 'fuente_id', label: 'Fuente', type: 'select', options: sourceOptions, required: true },
		{ key: 'destino', label: 'Dato documentado', type: 'select', options: claimTargetOptions, required: true },
		{ key: 'localizador', label: 'Página o localizador' },
		{ key: 'resumen', label: 'Resumen de la afirmación', type: 'textarea' },
		{
			key: 'confianza',
			label: 'Confianza',
			type: 'select',
			options: [
				{ value: 'alta', label: 'Alta' },
				{ value: 'media', label: 'Media' },
				{ value: 'baja', label: 'Baja' }
			]
		},
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true }
	]);
</script>

<div class="space-y-6">
	<MetricEntityCollection
		resource="verseModels"
		title="Metros"
		description="Tipos de verso: su medida y, cuando es compuesto, sus hemistiquios. El arte mayor o menor se deriva de las sílabas."
		rows={props.domain.verseModels}
		keyFields={['metro_id']}
		fields={verseModelFields}
		defaults={{ tipo: 'simple', estado_revision: 'borrador', activo: true }}
	/>
	<MetricEntityCollection
		resource="verseSegments"
		title="Segmentos y hemistiquios"
		rows={props.domain.verseSegments}
		keyFields={['segmento_id']}
		fields={segmentFields}
		defaults={{ alternativa: 1, posicion: 1 }}
	/>
	<MetricEntityCollection
		resource="traits"
		title="Rasgos transversales"
		description="Solo deben declararse aquí propiedades que no sean tamaño, medida, rima o estructura."
		rows={props.domain.traits}
		keyFields={['rasgo_id']}
		fields={traitFields}
		defaults={{
			tipo_valor: 'booleano',
			observabilidad: 'directa',
			demarcable: false,
			estado_revision: 'borrador',
			activo: true
		}}
	/>
	<MetricEntityCollection
		resource="traitValues"
		title="Valores controlados de rasgos"
		rows={props.domain.traitValues}
		keyFields={['valor_id']}
		fields={traitValueFields}
		defaults={{ activo: true }}
	/>
	<MetricEntityCollection
		resource="sources"
		title="Fuentes métricas"
		rows={props.domain.sources}
		keyFields={['fuente_id']}
		fields={sourceFields}
	/>
	<MetricEntityCollection
		resource="sourceClaims"
		title="Afirmaciones documentadas"
		description="Vincula una fuente con exactamente una forma, tradición, arquitectura, esquema o rasgo."
		rows={props.domain.sourceClaims}
		keyFields={['afirmacion_id']}
		fields={claimFields}
		defaults={{ estado_revision: 'borrador' }}
	/>
</div>
