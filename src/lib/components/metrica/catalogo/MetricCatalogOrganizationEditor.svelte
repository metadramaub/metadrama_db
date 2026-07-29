<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricReviewStateLabel,
		type MetricCatalogDomainRow,
		type MetricCatalogDomainData,
		type MetricCatalogForm
	} from '$lib/metrica/catalogo';

	const props = $props<{
		domain: MetricCatalogDomainData;
		forms: MetricCatalogForm[];
	}>();

	const reviewOptions: MetricEntityOption[] = METRIC_CATALOG_REVIEW_STATES.map((state) => ({
		value: state,
		label: metricReviewStateLabel(state)
	}));
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

	const familyFields = $derived<MetricEntityField[]>([
		{ key: 'nombre', label: 'Nombre', required: true },
		{ key: 'slug', label: 'Slug', required: true },
		{ key: 'descripcion', label: 'Descripción', type: 'textarea' },
		{ key: 'familia_padre_id', label: 'Familia superior', type: 'select', options: familyOptions },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activa', type: 'checkbox' }
	]);
	const familyFormFields = $derived<MetricEntityField[]>([
		{ key: 'familia_id', label: 'Familia', type: 'select', options: familyOptions, required: true },
		{ key: 'forma_id', label: 'Forma', type: 'select', options: formOptions, required: true },
		{ key: 'es_principal', label: 'Familia principal de la forma', type: 'checkbox' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
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
		{
			key: 'tipo_relacion',
			label: 'Relación',
			type: 'select',
			required: true,
			options: [
				{ value: 'origen', label: 'Origen' },
				{ value: 'adaptacion', label: 'Adaptación' },
				{ value: 'difusion', label: 'Difusión' },
				{ value: 'uso', label: 'Uso' }
			]
		},
		{ key: 'es_principal', label: 'Relación principal', type: 'checkbox' },
		{ key: 'cronologia', label: 'Cronología' },
		{ key: 'nota', label: 'Nota', type: 'textarea' }
	]);
	const aliasFields = $derived<MetricEntityField[]>([
		{ key: 'forma_id', label: 'Forma', type: 'select', options: formOptions, required: true },
		{ key: 'nombre', label: 'Nombre alternativo', required: true },
		{ key: 'slug_normalizado', label: 'Slug normalizado', required: true },
		{
			key: 'tipo_alias',
			label: 'Tipo',
			type: 'select',
			required: true,
			options: [
				{ value: 'equivalente', label: 'Equivalente' },
				{ value: 'variante_grafica', label: 'Variante gráfica' },
				{ value: 'historico', label: 'Histórico' },
				{ value: 'abreviatura', label: 'Abreviatura' }
			]
		},
		{ key: 'idioma', label: 'Idioma' },
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
		resource="families"
		title="Familias estructurales"
		description="Agrupan formas emparentadas sin convertir la familia en una forma seleccionable."
		rows={props.domain.families}
		keyFields={['familia_id']}
		fields={familyFields}
		defaults={{ estado_revision: 'borrador', activo: true }}
	/>
	<MetricEntityCollection
		resource="familyForms"
		title="Pertenencia de formas a familias"
		rows={props.domain.familyForms}
		keyFields={['familia_id', 'forma_id']}
		fields={familyFormFields}
		defaults={{ es_principal: false }}
	/>
	<MetricEntityCollection
		resource="traditions"
		title="Tradiciones métricas"
		description="Un marco histórico se registra aquí, separado de las familias, solo cuando está documentado. La cronología concreta pertenece a la relación con cada forma."
		rows={props.domain.traditions}
		keyFields={['tradicion_id']}
		fields={traditionFields}
		defaults={{ estado_revision: 'borrador', activo: true }}
	/>
	<MetricEntityCollection
		resource="formTraditions"
		title="Relaciones entre formas y tradiciones"
		rows={props.domain.formTraditions}
		keyFields={['forma_id', 'tradicion_id', 'tipo_relacion']}
		fields={formTraditionFields}
		defaults={{ tipo_relacion: 'uso', es_principal: false }}
	/>
	<MetricEntityCollection
		resource="aliases"
		title="Nombres alternativos"
		description="Sinónimos, grafías históricas y abreviaturas que no crean una forma nueva."
		rows={props.domain.aliases}
		keyFields={['alias_id']}
		fields={aliasFields}
		defaults={{ tipo_alias: 'equivalente', preferente: false }}
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
