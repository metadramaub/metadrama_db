<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
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
			value: String(row.modelo_verso_id),
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
		props.forms.map((form: MetricCatalogForm) => ({ value: form.forma_id, label: form.nombre }))
	);
	const familyOptions = $derived(
		props.domain.families.map((row: MetricCatalogDomainRow) => ({
			value: String(row.familia_id),
			label: String(row.nombre)
		}))
	);
	const traditionOptions = $derived(
		props.domain.traditions.map((row: MetricCatalogDomainRow) => ({
			value: String(row.tradicion_id),
			label: String(row.nombre)
		}))
	);
	const configurationOptions = $derived(
		props.configurations.map((row: MetricCatalogConfiguration) => ({
			value: row.configuracion_id,
			label: `${props.forms.find((form: MetricCatalogForm) => form.forma_id === row.forma_id)?.nombre ?? 'Forma'}: ${row.nombre}`
		}))
	);
	const metricPatternOptions = $derived(
		props.domain.metricPatterns.map((row: MetricCatalogDomainRow) => ({
			value: String(row.patron_metrico_id),
			label: String(row.nombre || `${row.tipo} · ${row.ambito}`)
		}))
	);
	const rhymePatternOptions = $derived(
		props.domain.rhymePatterns.map((row: MetricCatalogDomainRow) => ({
			value: String(row.patron_rima_id),
			label: String(row.nombre || row.esquema || 'Patrón sin nombre')
		}))
	);
	const claimTargetOptions = $derived([
		...formOptions.map((option: MetricEntityOption) => ({
			value: `forma_id:${option.value}`,
			label: `Forma: ${option.label}`
		})),
		...familyOptions.map((option: MetricEntityOption) => ({
			value: `familia_id:${option.value}`,
			label: `Familia: ${option.label}`
		})),
		...traditionOptions.map((option: MetricEntityOption) => ({
			value: `tradicion_id:${option.value}`,
			label: `Tradición: ${option.label}`
		})),
		...configurationOptions.map((option: MetricEntityOption) => ({
			value: `configuracion_id:${option.value}`,
			label: `Configuración: ${option.label}`
		})),
		...metricPatternOptions.map((option: MetricEntityOption) => ({
			value: `patron_metrico_id:${option.value}`,
			label: `Patrón métrico: ${option.label}`
		})),
		...rhymePatternOptions.map((option: MetricEntityOption) => ({
			value: `patron_rima_id:${option.value}`,
			label: `Patrón de rima: ${option.label}`
		})),
		...traitOptions.map((option: MetricEntityOption) => ({
			value: `rasgo_id:${option.value}`,
			label: `Rasgo: ${option.label}`
		}))
	]);

	const verseModelFields = $derived<MetricEntityField[]>([
		{ key: 'nombre', label: 'Nombre', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'metro_id', label: 'Metro total', type: 'select', options: metreOptions },
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
		{ key: 'silabas_totales', label: 'Sílabas totales', type: 'number' },
		{ key: 'tipo_cesura', label: 'Tipo de cesura' },
		{ key: 'patron_acentual', label: 'Patrón acentual' },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	]);
	const segmentFields = $derived<MetricEntityField[]>([
		{ key: 'modelo_verso_id', label: 'Modelo', type: 'select', options: verseModelOptions, required: true },
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
		title="Modelos de verso"
		description="Permiten distinguir, por ejemplo, un dodecasílabo simple de uno compuesto por hemistiquios."
		rows={props.domain.verseModels}
		keyFields={['modelo_verso_id']}
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
		description="Vincula una fuente con exactamente una forma, familia, tradición, configuración, patrón o rasgo."
		rows={props.domain.sourceClaims}
		keyFields={['afirmacion_id']}
		fields={claimFields}
		defaults={{ estado_revision: 'borrador' }}
	/>
</div>
