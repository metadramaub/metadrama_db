<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import NullableBooleanChoice from '$lib/components/ui/nullable-boolean-choice.svelte';

	/**
	 * Réplica del resto del panel lateral de producción: todo lo que el editor rellena en
	 * una secuencia además de la forma métrica. No guarda nada ni sale de la pantalla; está
	 * aquí para que la parte nueva se pruebe con el espacio y el desplazamiento reales.
	 */
	const props = $props<{
		/** Qué parte del panel se pinta. El contenedor las agrupa como en producción. */
		block: 'caracterizaciones' | 'sinopsis' | 'comentarios';
	}>();

	type IntervencionValue = 'sin_intervencion' | 'exclusiva' | 'compartida';

	const intervencionItems = [
		{ id: 'sin_intervencion', label: 'Sin intervención' },
		{ id: 'exclusiva', label: 'Intervención exclusiva' },
		{ id: 'compartida', label: 'Intervención compartida' }
	];
	const INTERVENCION_HELP =
		'Indica si en esta secuencia métrica interviene verbalmente un personaje de este tipo. El dato se refiere al habla dentro de la secuencia, no a la presencia escénica.';

	let intervencionFemeninos = $state<IntervencionValue | null>(null);
	let intervencionDonaire = $state<IntervencionValue | null>(null);
	let intervencionSobrenaturales = $state<IntervencionValue | null>(null);
	let versosPartidos = $state<boolean | null>(null);
	let inauguraEspacio = $state<boolean | null>(null);
	let evocacionMetrica = $state<boolean | null>(null);
	let evocacionMetricaTexto = $state('');
	let sinopsis = $state('');
</script>

{#snippet replicaTag()}
	<span
		class="border border-[color:var(--border)] px-1.5 py-0.5 text-[0.6rem] font-semibold uppercase tracking-wide text-[color:var(--muted-foreground)]"
	>
		Réplica
	</span>
{/snippet}

{#if props.block === 'caracterizaciones'}
<section>
	<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-subsection-title mb-0">Caracterizaciones por rango</h4>
		<div class="flex items-center gap-2">
			{@render replicaTag()}
			<Button variant="secondary" disabled>Añadir caracterización</Button>
		</div>
	</div>
	<p class="form-help">Sin caracterizaciones por rango registradas en esta secuencia.</p>
</section>

<section>
	<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-subsection-title mb-0">
			<span class="form-label-with-help">
				Intervención de personajes
				<FieldHelpTooltip text={INTERVENCION_HELP} label="Ayuda sobre la intervención de personajes" />
			</span>
		</h4>
		{@render replicaTag()}
	</div>
	<div class="grid gap-3 sm:grid-cols-2">
		<label class="form-field">
			<span class="form-label">Personajes femeninos</span>
			<CheckDropdown
				multiple={false}
				search={false}
				allowSingleClear
				placeholder="Pendiente — seleccionar"
				items={intervencionItems}
				selectedIds={intervencionFemeninos ? [intervencionFemeninos] : []}
				onChange={(ids) => (intervencionFemeninos = (ids[0] as IntervencionValue) ?? null)}
			/>
		</label>
		<label class="form-field">
			<span class="form-label">Figuras de donaire</span>
			<CheckDropdown
				multiple={false}
				search={false}
				allowSingleClear
				placeholder="Pendiente — seleccionar"
				items={intervencionItems}
				selectedIds={intervencionDonaire ? [intervencionDonaire] : []}
				onChange={(ids) => (intervencionDonaire = (ids[0] as IntervencionValue) ?? null)}
			/>
		</label>
		<label class="form-field">
			<span class="form-label">Personajes sobrenaturales</span>
			<CheckDropdown
				multiple={false}
				search={false}
				allowSingleClear
				placeholder="Pendiente — seleccionar"
				items={intervencionItems}
				selectedIds={intervencionSobrenaturales ? [intervencionSobrenaturales] : []}
				onChange={(ids) => (intervencionSobrenaturales = (ids[0] as IntervencionValue) ?? null)}
			/>
		</label>
	</div>
</section>

<section>
	<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-subsection-title mb-0">Otras caracterizaciones</h4>
		{@render replicaTag()}
	</div>
	<div class="grid gap-3 sm:grid-cols-2">
		<div class="grid grid-cols-2 gap-3 sm:col-span-2">
			<div class="form-field min-w-0">
				<span class="form-label">
					<span class="form-label-with-help">
						Versos partidos
						<FieldHelpTooltip
							text="Selecciona 'Sí' si en esta secuencia hay versos repartidos entre intervenciones de distintos personajes."
							label="Ayuda sobre el campo Versos partidos"
						/>
					</span>
				</span>
				<NullableBooleanChoice
					value={versosPartidos}
					ariaLabel="Versos partidos"
					onChange={(value) => (versosPartidos = value)}
				/>
			</div>
			<div class="form-field min-w-0">
				<span class="form-label">
					<span class="form-label-with-help">
						Inaugura espacio
						<FieldHelpTooltip
							text="Selecciona 'Sí' si coincide (de forma evidente) el inicio de esta secuencia con el cambio de espacio escénico."
							label="Ayuda sobre el campo Inaugura espacio"
						/>
					</span>
				</span>
				<NullableBooleanChoice
					value={inauguraEspacio}
					ariaLabel="Inaugura espacio"
					onChange={(value) => (inauguraEspacio = value)}
				/>
			</div>
		</div>
		<div class="form-field sm:col-span-2">
			<span class="form-label">
				<span class="form-label-with-help">
					Evocación métrica
					<FieldHelpTooltip
						text="Selecciona 'Sí' cuando el cambio de metro se deba a que un personaje adopta, imita o reproduce la voz de otro personaje."
						label="Ayuda sobre el campo Evocación métrica"
					/>
				</span>
			</span>
			<NullableBooleanChoice
				value={evocacionMetrica}
				ariaLabel="Evocación métrica"
				onChange={(value) => {
					evocacionMetrica = value;
					if (value !== true) evocacionMetricaTexto = '';
				}}
			/>
		</div>
		{#if evocacionMetrica}
			<label class="form-field sm:col-span-2">
				<span class="form-label">Explicación de la evocación métrica</span>
				<MarkdownEditorLite
					rows={3}
					class="mt-1"
					minHeightClass="min-h-24"
					value={evocacionMetricaTexto}
					onChange={(nextValue) => (evocacionMetricaTexto = nextValue)}
				/>
			</label>
		{/if}
	</div>
</section>

{/if}

{#if props.block === 'sinopsis'}
<section>
	<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-subsection-title mb-0">Sinopsis argumental</h4>
		{@render replicaTag()}
	</div>
	<label class="form-field">
		<span class="sr-only">Sinopsis argumental</span>
		<MarkdownEditorLite
			rows={3}
			class="mt-1"
			minHeightClass="min-h-28"
			value={sinopsis}
			onChange={(nextValue) => (sinopsis = nextValue)}
		/>
	</label>
</section>

{/if}

{#if props.block === 'comentarios'}
<section>
	<div class="flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-subsection-title mb-0">Comentarios internos de secuencia</h4>
		<div class="flex items-center gap-2">
			{@render replicaTag()}
			<Button variant="secondary" disabled>Ver</Button>
		</div>
	</div>
</section>
{/if}
