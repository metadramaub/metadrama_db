<script lang="ts">
	import MetricEntityCollection, {
		type MetricEntityField,
		type MetricEntityOption
	} from './MetricEntityCollection.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		metricReviewStateLabel,
		type MetricCatalogDomainData,
		type MetricCatalogDomainRow
	} from '$lib/metrica/catalogo';

	const props = $props<{
		configurationId: string;
		domain: MetricCatalogDomainData;
	}>();

	const groups = $derived(
		props.domain.choiceGroups
			.filter(
				(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	const sections = $derived(
		props.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === props.configurationId
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
		{ key: 'arquitectura_id', label: 'Arquitectura', type: 'hidden' },
		{ key: 'slug', label: 'Slug', required: true },
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
				{ value: 'combinacion', label: 'Combinación de medida y rima' },
				{ value: 'estructura', label: 'Estructura' },
				{ value: 'repeticion', label: 'Repetición' },
				{ value: 'rasgo', label: 'Rasgo' }
			]
		},
		{
			key: 'tipo_control',
			label: 'Tipo de respuesta',
			type: 'select',
			required: true,
			options: [
				{ value: 'opciones', label: 'Elegir entre respuestas catalogadas' },
				{ value: 'esquema_rima', label: 'Escribir un esquema de rima observado' }
			],
			help: 'El esquema abierto se valida y normaliza; no crea un esquema nuevo en el catálogo.'
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
		{
			key: 'define_norma',
			label: 'La respuesta declara la norma del pasaje',
			type: 'checkbox',
			help: 'La respuesta no elige entre alternativas: fija la norma que las demás realizaciones repiten. Todas deben coincidir, y la base lo comprueba al guardar.'
		},
		{ key: 'orden', label: 'Orden', type: 'number' },
		{ key: 'estado_revision', label: 'Estado', type: 'select', options: reviewOptions, required: true },
		{ key: 'activo', label: 'Activo', type: 'checkbox' }
	]);

	/** Las respuestas que el catálogo produce hoy para una pregunta. Se leen, no se editan. */
	function optionsOf(group: MetricCatalogDomainRow): MetricCatalogDomainRow[] {
		return props.domain.choiceOptions
			.filter(
				(row: MetricCatalogDomainRow) =>
					row.grupo_eleccion_id === group.grupo_eleccion_id
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			);
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
		<p class="mt-1 max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			Ni el enunciado ni las respuestas se escriben: salen del catálogo. El enunciado lo
			componen la dimensión y la sección a la que se refiere la pregunta, y en las de rasgo
			es la pregunta que declara el propio rasgo.
		</p>
	</div>

	<MetricEntityCollection
		resource="choiceGroups"
		title="Grupos de elección"
		rows={groups}
		keyFields={['grupo_eleccion_id']}
		fields={groupFields}
		defaults={{
			arquitectura_id: props.configurationId,
			dimension: 'rima',
			tipo_control: 'opciones',
			alcance: 'secuencia',
			selecciones_min: 1,
			selecciones_max: 1,
			permite_aplicar_global: false,
			define_norma: false,
			estado_revision: 'borrador',
			activo: true,
			orden: 1
		}}
		emptyMessage="Esta arquitectura no plantea ninguna elección explícita al editor."
		compact
	/>

	{#each groups as group (String(group.grupo_eleccion_id))}
		<div class="border-l-2 border-[color:var(--border)] pl-4">
			{#if group.tipo_control === 'esquema_rima'}
				<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
					Respuesta abierta controlada: el editor escribe una letra por verso y puede usar
					guiones para versos sueltos. No necesita opciones precargadas.
				</p>
			{:else}
				<h5 class="font-medium">Respuestas: {String(group.nombre)}</h5>
				<p class="mt-1 text-sm leading-6 text-[color:var(--muted-foreground)]">
					No se escriben: salen del catálogo. Para cambiarlas, cambia el esquema, el rasgo,
					la repetición o la variedad de los que se derivan.
				</p>
				{#if optionsOf(group).length}
					<ul class="mt-2 space-y-1 text-sm">
						{#each optionsOf(group) as option (String(option.opcion_eleccion_id))}
							<li>
								<span class="font-medium">{String(option.nombre)}</span>
								{#if option.descripcion}
									<span class="text-[color:var(--muted-foreground)]">
										— {String(option.descripcion)}
									</span>
								{/if}
							</li>
						{/each}
					</ul>
				{:else}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
						El catálogo no produce ninguna respuesta para esta pregunta.
					</p>
				{/if}
			{/if}
		</div>
	{/each}
</section>
