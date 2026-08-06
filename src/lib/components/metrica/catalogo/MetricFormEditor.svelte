<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import MetricArchitectureEditor from './MetricArchitectureEditor.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		METRIC_ARCHITECTURE_MODALITIES,
		METRIC_STRUCTURAL_LEVELS,
		metricReviewStateLabel,
		metricStructuralLevelLabel,
		type MetricCatalogConfiguration,
		type MetricCatalogDomainData,
		type MetricCatalogForm,
		type MetricCatalogOption
	} from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		form: MetricCatalogForm;
		configurations: MetricCatalogConfiguration[];
		domain: MetricCatalogDomainData;
		metres: MetricCatalogOption[];
		rhymeTypes: MetricCatalogOption[];
	}>();

	let draft = $state<MetricCatalogForm>(untrack(() => ({ ...props.form })));
	let saving = $state(false);
	let errorMessage = $state('');
	let showNewConfiguration = $state(false);
	let creatingConfiguration = $state(false);
	let newConfigurationError = $state('');
	let newConfiguration = $state({
		slug: 'nueva_arquitectura',
		nombre: 'Nueva arquitectura',
		descripcion: '',
		principal: false,
		demarcable: true,
		modalidad: 'admitida' as (typeof METRIC_ARCHITECTURE_MODALITIES)[number],
		tipo_rima_id: null as string | null,
		unidad_versos_min: null as number | null,
		unidad_versos_max: null as number | null,
		estado_revision: 'borrador' as (typeof METRIC_CATALOG_REVIEW_STATES)[number],
		activo: true,
		orden: null as number | null
	});

	const changed = $derived(JSON.stringify(draft) !== JSON.stringify(props.form));
	const configurations = $derived(
		[...props.configurations].sort(
			(a, b) =>
				Number(b.principal) - Number(a.principal) ||
				(a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.nombre.localeCompare(b.nombre, 'es')
		)
	);
	const newConfigurationDeclaresUnitExtent = $derived(
		draft.nivel_estructural === 'estrofa' || draft.nivel_estructural === 'composicion'
	);

	function nullablePositiveInteger(value: string): number | null {
		if (!value.trim()) return null;
		const number = Number(value);
		return Number.isInteger(number) && number > 0 ? number : null;
	}

	async function saveForm() {
		if (!changed || saving) return;
		saving = true;
		errorMessage = '';
		try {
			const response = await fetch('/api/metrica/formas', {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					forma_id: draft.forma_id,
					slug: draft.slug,
					nombre: draft.nombre,
					definicion: draft.definicion?.trim() || null,
					nivel_estructural: draft.nivel_estructural,
					tipo_registro: draft.tipo_registro,
					seleccionable: draft.seleccionable,
					estado_revision: draft.estado_revision,
					activo: draft.activo,
					orden: draft.orden
				})
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(
					payload.message ?? payload.details?.[0]?.message ?? 'No se pudo guardar la forma.'
				);
			}
			pushToast('success', `Forma «${draft.nombre}» guardada.`);
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo guardar la forma.';
		} finally {
			saving = false;
		}
	}

	async function createConfiguration() {
		if (creatingConfiguration) return;
		creatingConfiguration = true;
		newConfigurationError = '';
		try {
			const response = await fetch('/api/metrica/configuraciones', {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					...newConfiguration,
					forma_id: props.form.forma_id,
					unidad_versos_min: newConfigurationDeclaresUnitExtent
						? newConfiguration.unidad_versos_min
						: null,
					unidad_versos_max: newConfigurationDeclaresUnitExtent
						? (newConfiguration.unidad_versos_max ?? newConfiguration.unidad_versos_min)
						: null,
					descripcion: newConfiguration.descripcion.trim() || null
				})
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(
					payload.message ??
						payload.details?.[0]?.message ??
						'No se pudo crear la arquitectura.'
				);
			}
			pushToast('success', `Arquitectura «${newConfiguration.nombre}» creada.`);
			showNewConfiguration = false;
			await invalidateAll();
		} catch (error) {
			newConfigurationError =
				error instanceof Error ? error.message : 'No se pudo crear la arquitectura.';
		} finally {
			creatingConfiguration = false;
		}
	}
</script>

<div class="space-y-6">
	<header class="flex flex-col gap-3 border-b border-[color:var(--border)] pb-5 lg:flex-row lg:items-start lg:justify-between">
		<div>
			<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
				<h2 class="text-2xl font-semibold">{props.form.nombre}</h2>
				<span class="font-mono text-xs text-[color:var(--muted-foreground)]">{props.form.slug}</span>
			</div>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				{props.form.origen_termino_id
					? 'Forma importada del vocabulario anterior.'
					: 'Forma creada directamente en el nuevo catálogo.'}
			</p>
		</div>
		{#if props.form.origen_termino_id}
			<a
				class="text-sm underline decoration-dotted underline-offset-4"
				href={`/dashboard/vocabularios/estrofa_tipo?termino=${props.form.origen_termino_id}`}
			>
				Consultar dato de origen
			</a>
		{/if}
	</header>

	<section class="space-y-5">
		<div class="grid gap-4 md:grid-cols-2">
			<label class="space-y-1">
				<span class="text-sm font-medium">Nombre preferido</span>
				<input
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					bind:value={draft.nombre}
				/>
			</label>
			<div class="space-y-1">
				<span class="block text-sm font-medium">Slug estable</span>
				<p
					class="w-full border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 font-mono text-sm text-[color:var(--muted-foreground)]"
				>
					{draft.slug}
				</p>
				<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
					Clave técnica: hay código y migraciones que dependen de ella, así que solo cambia
					por migración. Para renombrar la forma, edita el nombre.
				</span>
			</div>
		</div>

		<label class="block space-y-1">
			<span class="text-sm font-medium">Definición</span>
			<textarea
				rows="6"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm leading-6"
				bind:value={draft.definicion}
			></textarea>
		</label>

		<div class="grid gap-4 md:grid-cols-3">
			<label class="space-y-1">
				<span class="text-sm font-medium">Nivel estructural</span>
				<select
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					bind:value={draft.nivel_estructural}
				>
					{#each METRIC_STRUCTURAL_LEVELS as level}
						<option value={level}>{metricStructuralLevelLabel(level)}</option>
					{/each}
				</select>
			</label>
			<label class="space-y-1">
				<span class="text-sm font-medium">Tipo de entrada</span>
				<select
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					value={draft.tipo_registro}
					onchange={(event) => {
						draft.tipo_registro = event.currentTarget
							.value as MetricCatalogForm['tipo_registro'];
						if (draft.tipo_registro === 'sin_forma') draft.seleccionable = true;
					}}
				>
					<option value="forma">Forma métrica</option>
					<option value="sin_forma">Tramo sin forma</option>
				</select>
			</label>
			<label class="space-y-1">
				<span class="text-sm font-medium">Estado del catálogo</span>
				<select
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					bind:value={draft.estado_revision}
				>
					{#each METRIC_CATALOG_REVIEW_STATES as state}
						<option value={state}>{metricReviewStateLabel(state)}</option>
					{/each}
				</select>
			</label>
		</div>

		<div class="flex flex-wrap gap-x-6 gap-y-3 border-y border-[color:var(--border)] py-4 text-sm">
			<label class="inline-flex items-center gap-2">
				<input
					type="checkbox"
					bind:checked={draft.seleccionable}
					disabled={draft.tipo_registro === 'sin_forma'}
				/>
				Seleccionable por el editor
			</label>
			<label class="inline-flex items-center gap-2">
				<input type="checkbox" bind:checked={draft.activo} />
				Activa
			</label>
			<p class="basis-full text-xs leading-5 text-[color:var(--muted-foreground)]">
				Una forma general se define por rasgos amplios y no se ha especializado: el demarcador
				ofrece siempre la más específica que encaje y recurre a ella cuando ninguna corresponde.
			</p>
		</div>

		{#if errorMessage}
			<p class="text-sm text-red-700">{errorMessage}</p>
		{/if}

		<div class="flex justify-end">
			<button
				type="button"
				class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
				disabled={!changed || saving}
				onclick={saveForm}
			>
				{saving ? 'Guardando…' : 'Guardar forma'}
			</button>
		</div>
	</section>

	{#if draft.tipo_registro === 'forma'}
		<section class="space-y-4 border-t border-[color:var(--border)] pt-6">
		<div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
			<div>
				<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
					Norma formal
				</p>
				<h3 class="mt-1 text-xl font-semibold">Arquitecturas</h3>
				<p class="mt-1 max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
					Las alternativas se describen aquí sin convertir cada cambio de metro o rima en una
					forma nueva.
				</p>
			</div>
			<button
				type="button"
				class="border border-[color:var(--border)] px-4 py-2 text-sm font-medium hover:bg-[color:var(--muted)]"
				onclick={() => (showNewConfiguration = !showNewConfiguration)}
			>
				{showNewConfiguration ? 'Cancelar' : 'Añadir arquitectura'}
			</button>
		</div>

		{#if showNewConfiguration}
			<div class="space-y-4 border border-[color:var(--border)] bg-[color:var(--muted)] p-4">
				<h4 class="font-medium">Nueva arquitectura</h4>
				<div class="grid gap-4 md:grid-cols-2">
					<label class="space-y-1">
						<span class="text-sm font-medium">Nombre</span>
						<input
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
							bind:value={newConfiguration.nombre}
						/>
					</label>
					<label class="space-y-1">
						<span class="text-sm font-medium">Slug</span>
						<input
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 font-mono text-sm"
							bind:value={newConfiguration.slug}
						/>
					</label>
				</div>
				<label class="block space-y-1">
					<span class="text-sm font-medium">Descripción</span>
					<textarea
						rows="3"
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
						bind:value={newConfiguration.descripcion}
					></textarea>
				</label>
				<div class="space-y-4 border-y border-[color:var(--border)] py-4">
					<h5 class="text-sm font-medium">Norma básica</h5>
					<div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
						{#if newConfigurationDeclaresUnitExtent}
							<label class="space-y-1">
								<span class="text-sm font-medium">Versos de la unidad (mínimo)</span>
								<input
									type="number"
									min="1"
									class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
									value={newConfiguration.unidad_versos_min ?? ''}
									oninput={(event) =>
										(newConfiguration.unidad_versos_min = nullablePositiveInteger(
											event.currentTarget.value
										))}
								/>
							</label>
							<label class="space-y-1">
								<span class="text-sm font-medium">Versos de la unidad (máximo)</span>
								<input
									type="number"
									min="1"
									class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
									value={newConfiguration.unidad_versos_max ?? ''}
									oninput={(event) =>
										(newConfiguration.unidad_versos_max = nullablePositiveInteger(
											event.currentTarget.value
										))}
								/>
							</label>
						{:else}
							<p class="text-sm leading-6 text-[color:var(--muted-foreground)] md:col-span-2">
								La unidad es la serie entera y su extensión no se declara.
							</p>
						{/if}
						<label class="space-y-1">
							<span class="text-sm font-medium">Tipo de rima</span>
							<select
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={newConfiguration.tipo_rima_id ?? ''}
								onchange={(event) =>
									(newConfiguration.tipo_rima_id = event.currentTarget.value || null)}
							>
								<option value="">No declarado o no aplicable</option>
								{#each props.rhymeTypes as option}
									<option value={option.id}>{option.label}</option>
								{/each}
							</select>
						</label>
					</div>
				</div>
				<div class="grid gap-4 md:grid-cols-2">
					<label class="space-y-1">
						<span class="text-sm font-medium">Grado</span>
						<select
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
							bind:value={newConfiguration.modalidad}
						>
							{#each METRIC_ARCHITECTURE_MODALITIES as grade}
								<option value={grade}>{grade.replaceAll('_', ' ')}</option>
							{/each}
						</select>
					</label>
					<label class="space-y-1">
						<span class="text-sm font-medium">Estado</span>
						<select
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
							bind:value={newConfiguration.estado_revision}
						>
							{#each METRIC_CATALOG_REVIEW_STATES as state}
								<option value={state}>{metricReviewStateLabel(state)}</option>
							{/each}
						</select>
					</label>
				</div>
				<div class="flex flex-wrap gap-x-6 gap-y-3 text-sm">
					<label class="inline-flex items-center gap-2">
						<input type="checkbox" bind:checked={newConfiguration.principal} />
						Prototípica (opcional)
					</label>
					<label class="inline-flex items-center gap-2">
						<input type="checkbox" bind:checked={newConfiguration.demarcable} />
						Demarcable
					</label>
				</div>
				{#if newConfigurationError}
					<p class="text-sm text-red-700">{newConfigurationError}</p>
				{/if}
				<div class="flex justify-end">
					<button
						type="button"
						class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
						disabled={creatingConfiguration}
						onclick={createConfiguration}
					>
						{creatingConfiguration ? 'Creando…' : 'Crear arquitectura'}
					</button>
				</div>
			</div>
		{/if}

		<div class="space-y-3">
			{#each configurations as configuration (configuration.arquitectura_id)}
				<MetricArchitectureEditor
					{configuration}
					formLevel={draft.nivel_estructural}
					domain={props.domain}
					metres={props.metres}
					rhymeTypes={props.rhymeTypes}
				/>
			{:else}
				<p class="border border-dashed border-[color:var(--border)] p-4 text-sm text-[color:var(--muted-foreground)]">
					Esta forma todavía no tiene arquitecturas.
				</p>
			{/each}
		</div>
		</section>
	{:else}
		<section class="border-t border-[color:var(--border)] pt-6">
			<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
				Las salidas editoriales no tienen arquitecturas, esquemas ni desviaciones respecto de
				una norma. Solo permiten delimitar el rango y añadir una observación opcional.
			</p>
		</section>
	{/if}
</div>
