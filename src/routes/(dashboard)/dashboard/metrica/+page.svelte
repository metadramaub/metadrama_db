<script lang="ts">
	import { browser } from '$app/environment';
	import { invalidateAll } from '$app/navigation';
	import { page } from '$app/stores';
	import { untrack } from 'svelte';
	import { get } from 'svelte/store';
	import MetricFormEditor from '$lib/components/metrica/catalogo/MetricFormEditor.svelte';
	import MetricMigrationReview from '$lib/components/metrica/catalogo/MetricMigrationReview.svelte';
	import MetricCatalogOrganizationEditor from '$lib/components/metrica/catalogo/MetricCatalogOrganizationEditor.svelte';
	import MetricCatalogReferenceEditor from '$lib/components/metrica/catalogo/MetricCatalogReferenceEditor.svelte';
	import MetricCatalogGuide from '$lib/components/metrica/catalogo/MetricCatalogGuide.svelte';
	import MetricEditorSandbox from '$lib/components/metrica/editor-v2/MetricEditorSandbox.svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		METRIC_STRUCTURAL_LEVELS,
		metricReviewStateLabel,
		metricStructuralLevelLabel,
		type MetricCatalogConfiguration,
		type MetricCatalogForm,
		type MetricCatalogIssue,
		type MetricCatalogPageData,
		type MetricCatalogPreviewVersion,
		type MetricCatalogReviewState,
		type MetricStructuralLevel
	} from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';

	type ActiveTab =
		| 'guide'
		| 'catalog'
		| 'organization'
		| 'reference'
		| 'editor'
		| 'validation'
		| 'traceability';
	const activeTabs = new Set<ActiveTab>([
		'guide',
		'catalog',
		'organization',
		'reference',
		'editor',
		'validation',
		'traceability'
	]);

	let { data } = $props<{ data: MetricCatalogPageData }>();
	let activeTab = $state<ActiveTab>(resolveTab(get(page).url.searchParams.get('tab')));
	let selectedFormId = $state<string | null>(null);
	let search = $state('');
	let formStateFilter = $state<'active' | 'draft' | 'approved' | 'all'>('active');
	let showCreateForm = $state(false);
	let creatingForm = $state(false);
	let createFormError = $state('');
	let generatingPreview = $state(false);
	let previewError = $state('');
	let previewWarnings = $state<string[]>([]);
	let latestPreview = $state<MetricCatalogPreviewVersion | null>(
		untrack(() => data.previewVersions[0] ?? null)
	);
	let newForm = $state({
		slug: '',
		nombre: '',
		definicion: '',
		nivel_estructural: 'estrofa' as MetricStructuralLevel,
		seleccionable: true,
		residual: false,
		estado_revision: 'borrador' as MetricCatalogReviewState,
		activo: true,
		orden: null as number | null
	});

	const tabs = [
		{ id: 'guide', label: 'Guía del modelo' },
		{ id: 'catalog', label: 'Formas y configuraciones' },
		{ id: 'organization', label: 'Organización' },
		{ id: 'reference', label: 'Modelos, rasgos y fuentes' },
		{ id: 'editor', label: 'Editor de prueba' },
		{ id: 'validation', label: 'Validación y demarcador' },
		{ id: 'traceability', label: 'Trazabilidad de importación' }
	];

	const filteredForms = $derived.by(() => {
		const term = search.trim().toLocaleLowerCase('es');
		return data.forms.filter((form: MetricCatalogForm) => {
			const matchesSearch =
				!term ||
				form.nombre.toLocaleLowerCase('es').includes(term) ||
				form.slug.toLocaleLowerCase('es').includes(term);
			if (!matchesSearch) return false;
			if (formStateFilter === 'active') return form.activo;
			if (formStateFilter === 'draft') return form.estado_revision === 'borrador';
			if (formStateFilter === 'approved') return form.estado_revision === 'aprobada';
			return true;
		});
	});

	const effectiveSelectedFormId = $derived(
		selectedFormId &&
			data.forms.some((form: MetricCatalogForm) => form.forma_id === selectedFormId)
			? selectedFormId
			: filteredForms[0]?.forma_id ?? data.forms[0]?.forma_id ?? null
	);
	const selectedForm = $derived(
		data.forms.find(
			(form: MetricCatalogForm) => form.forma_id === effectiveSelectedFormId
		) ?? null
	);
	const selectedConfigurations = $derived(
		selectedForm
			? data.configurations.filter(
					(configuration: MetricCatalogConfiguration) =>
						configuration.forma_id === selectedForm.forma_id
				)
			: []
	);
	const demarcableConfigurations = $derived(
		data.configurations.filter(
			(configuration: MetricCatalogConfiguration) =>
				configuration.activo &&
				configuration.demarcable
		).length
	);
	const demarcatorReady = $derived(
			data.issues.filter((issue: MetricCatalogIssue) => issue.level === 'error').length === 0 &&
			data.stats.approvedForms > 0
	);
	const previewIsCurrent = $derived(
		Boolean(
			latestPreview &&
				data.revision !== null &&
				latestPreview.catalogo_revision === data.revision
		)
	);

	function resolveTab(value: string | null | undefined): ActiveTab {
		if (!value) return 'catalog';
		return activeTabs.has(value as ActiveTab) ? (value as ActiveTab) : 'catalog';
	}

	function selectTab(id: string) {
		activeTab = id as ActiveTab;
		if (!browser) return;
		const url = new URL(window.location.href);
		url.searchParams.set('tab', activeTab);
		window.history.replaceState(window.history.state, '', url.toString());
	}

	function selectIssueEntity(entityId: string) {
		const directForm = data.forms.find(
			(form: MetricCatalogForm) => form.forma_id === entityId
		);
		const configuration = data.configurations.find(
			(item: MetricCatalogConfiguration) => item.configuracion_id === entityId
		);
		const formId = directForm?.forma_id ?? configuration?.forma_id ?? null;
		if (!formId) return;
		selectedFormId = formId;
		activeTab = 'catalog';
	}

	function resetNewForm() {
		newForm = {
			slug: '',
			nombre: '',
			definicion: '',
			nivel_estructural: 'estrofa',
			seleccionable: true,
			residual: false,
			estado_revision: 'borrador',
			activo: true,
			orden: null
		};
		createFormError = '';
	}

	function cancelCreateForm() {
		if (creatingForm) return;
		resetNewForm();
		showCreateForm = false;
	}

	function toggleCreateForm() {
		if (showCreateForm) {
			cancelCreateForm();
			return;
		}
		resetNewForm();
		showCreateForm = true;
	}

	async function createForm() {
		if (creatingForm) return;
		creatingForm = true;
		createFormError = '';
		try {
			const response = await fetch('/api/metrica/formas', {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					...newForm,
					definicion: newForm.definicion.trim() || null
				})
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(
					payload.message ?? payload.details?.[0]?.message ?? 'No se pudo crear la forma.'
				);
			}
			const created = payload.form as MetricCatalogForm;
			selectedFormId = created.forma_id;
			showCreateForm = false;
			resetNewForm();
			pushToast('success', `Forma «${created.nombre}» creada.`);
			await invalidateAll();
		} catch (error) {
			createFormError =
				error instanceof Error ? error.message : 'No se pudo crear la forma.';
		} finally {
			creatingForm = false;
		}
	}

	async function generatePreview() {
		if (generatingPreview) return;
		generatingPreview = true;
		previewError = '';
		previewWarnings = [];
		try {
			const response = await fetch('/api/metrica/demarcador', { method: 'POST' });
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(payload.message ?? 'No se pudo generar la prueba del demarcador.');
			}
			latestPreview = payload.version as MetricCatalogPreviewVersion;
			previewWarnings = Array.isArray(payload.warnings) ? payload.warnings : [];
			pushToast(
				'success',
				payload.reused
					? 'La prueba existente ya corresponde a esta revisión.'
					: 'Se ha generado una nueva prueba del demarcador.'
			);
			await invalidateAll();
		} catch (error) {
			previewError =
				error instanceof Error
					? error.message
					: 'No se pudo generar la prueba del demarcador.';
		} finally {
			generatingPreview = false;
		}
	}
</script>

<svelte:head>
	<title>Catálogo métrico | METADRAMA</title>
</svelte:head>

<section class="mx-auto w-full max-w-[95rem] space-y-6 px-4 py-6 sm:px-6 lg:px-8">
	<header class="space-y-2">
		<p class="text-xs font-semibold uppercase tracking-[0.16em] text-[color:var(--muted-foreground)]">
			Dominio métrico
		</p>
		<div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
			<div>
				<h1 class="text-2xl font-semibold tracking-tight text-[color:var(--foreground)] sm:text-3xl">
					Catálogo métrico
				</h1>
				<p class="mt-2 max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
					Gestiona las formas, sus configuraciones y las relaciones del nuevo dominio. Esta
					sección es independiente de las formas que los editores están declarando actualmente
					en las secuencias.
				</p>
			</div>
			{#if data.revision !== null}
				<p class="text-xs text-[color:var(--muted-foreground)]">
					Revisión interna del catálogo: {data.revision}
				</p>
			{/if}
		</div>
	</header>

	{#if data.migrationPending}
		<div class="border-l-4 border-amber-500 bg-amber-50 p-5">
			<h2 class="font-semibold">Falta aplicar las migraciones</h2>
			<p class="mt-2 text-sm leading-6 text-amber-950">{data.migrationMessage}</p>
			<p class="mt-2 font-mono text-xs text-amber-950">
				Última requerida: 20260730102000_formalizacion_seguidilla.sql
			</p>
		</div>
	{:else}
		<div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Formas activas</p>
				<p class="mt-1 text-2xl font-semibold">{data.stats.forms}</p>
			</div>
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Formas aprobadas</p>
				<p class="mt-1 text-2xl font-semibold">{data.stats.approvedForms}</p>
			</div>
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Configuraciones activas</p>
				<p class="mt-1 text-2xl font-semibold">{data.stats.configurations}</p>
			</div>
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Familias estructurales</p>
				<p class="mt-1 text-2xl font-semibold">{data.domain.families.length}</p>
			</div>
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Rasgos transversales</p>
				<p class="mt-1 text-2xl font-semibold">{data.domain.traits.length}</p>
			</div>
		</div>

		<Tabs {tabs} active={activeTab} onChange={selectTab} />

		{#if activeTab === 'guide'}
			<MetricCatalogGuide />
		{:else if activeTab === 'catalog'}
			<div class="grid min-h-[42rem] border border-[color:var(--border)] bg-[color:var(--card)] lg:grid-cols-[19rem_minmax(0,1fr)]">
				<aside class="border-b border-[color:var(--border)] p-4 lg:border-b-0 lg:border-r">
					<div class="space-y-3">
						<input
							type="search"
							class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
							placeholder="Buscar forma"
							bind:value={search}
						/>
						<select
							class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
							bind:value={formStateFilter}
						>
							<option value="active">Formas activas</option>
							<option value="draft">En borrador</option>
							<option value="approved">Aprobadas</option>
							<option value="all">Todas</option>
						</select>
						<button
							type="button"
							class="h-10 w-full border border-[color:var(--foreground)] px-3 text-sm font-medium hover:bg-[color:var(--muted)]"
							onclick={toggleCreateForm}
						>
							{showCreateForm ? 'Cancelar nueva forma' : 'Crear forma'}
						</button>
					</div>

					<nav class="mt-4 max-h-[55rem] space-y-1 overflow-y-auto pr-1" aria-label="Formas métricas">
						{#each filteredForms as form (form.forma_id)}
							<button
								type="button"
								class={`w-full border-l-2 px-3 py-2 text-left transition-colors ${
									effectiveSelectedFormId === form.forma_id
										? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
										: 'border-transparent hover:bg-[color:var(--muted)]'
								}`}
								onclick={() => (selectedFormId = form.forma_id)}
							>
								<span class="block text-sm font-medium">{form.nombre}</span>
								<span class="mt-0.5 block text-xs text-[color:var(--muted-foreground)]">
									{metricReviewStateLabel(form.estado_revision)}
									{form.residual ? ' · residual' : ''}
								</span>
							</button>
						{:else}
							<p class="p-3 text-sm text-[color:var(--muted-foreground)]">
								No hay formas que coincidan.
							</p>
						{/each}
					</nav>
				</aside>

				<div class="min-w-0 p-4 sm:p-6">
					{#if showCreateForm}
						<section class="space-y-4">
							<div>
								<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
									Nueva entrada
								</p>
								<h2 class="mt-1 text-xl font-semibold">Crear forma métrica</h2>
							</div>
							<div class="grid gap-4 md:grid-cols-2">
								<label class="space-y-1">
									<span class="text-sm font-medium">Nombre</span>
									<input
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										bind:value={newForm.nombre}
									/>
								</label>
								<label class="space-y-1">
									<span class="text-sm font-medium">Slug</span>
									<input
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 font-mono text-sm"
										bind:value={newForm.slug}
									/>
								</label>
							</div>
							<label class="block space-y-1">
								<span class="text-sm font-medium">Definición</span>
								<textarea
									rows="6"
									class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm leading-6"
									bind:value={newForm.definicion}
								></textarea>
							</label>
							<div class="grid gap-4 md:grid-cols-2">
								<label class="space-y-1">
									<span class="text-sm font-medium">Nivel</span>
									<select
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										bind:value={newForm.nivel_estructural}
									>
										{#each METRIC_STRUCTURAL_LEVELS as level}
											<option value={level}>{metricStructuralLevelLabel(level)}</option>
										{/each}
									</select>
								</label>
								<label class="space-y-1">
									<span class="text-sm font-medium">Estado</span>
									<select
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										bind:value={newForm.estado_revision}
									>
										{#each METRIC_CATALOG_REVIEW_STATES as state}
											<option value={state}>{metricReviewStateLabel(state)}</option>
										{/each}
									</select>
								</label>
							</div>
							<div class="flex flex-wrap gap-x-6 gap-y-3 text-sm">
								<label class="inline-flex items-center gap-2">
									<input type="checkbox" bind:checked={newForm.seleccionable} />
									Seleccionable
								</label>
								<label class="inline-flex items-center gap-2">
									<input
										type="checkbox"
										checked={newForm.residual}
										onchange={(event) => {
											newForm.residual = event.currentTarget.checked;
											if (newForm.residual) newForm.seleccionable = true;
										}}
									/>
									Categoría residual
								</label>
							</div>
							{#if createFormError}
								<p class="text-sm text-red-700">{createFormError}</p>
							{/if}
							<div class="flex justify-end gap-2">
								<button
									type="button"
									class="border border-[color:var(--border)] px-4 py-2 text-sm font-medium hover:bg-[color:var(--muted)] disabled:opacity-40"
									disabled={creatingForm}
									onclick={cancelCreateForm}
								>
									Cancelar
								</button>
								<button
									type="button"
									class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
									disabled={creatingForm || !newForm.nombre.trim() || !newForm.slug.trim()}
									onclick={createForm}
								>
									{creatingForm ? 'Creando…' : 'Crear forma'}
								</button>
							</div>
						</section>
					{:else if selectedForm}
						{#key selectedForm.forma_id}
							<MetricFormEditor
								form={selectedForm}
								configurations={selectedConfigurations}
								domain={data.domain}
								metres={data.options.metres}
								rhymeTypes={data.options.rhymeTypes}
							/>
						{/key}
					{:else}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							Selecciona o crea una forma métrica.
						</p>
					{/if}
				</div>
			</div>
		{:else if activeTab === 'organization'}
			{#key data.revision}
				<MetricCatalogOrganizationEditor
					domain={data.domain}
					forms={data.forms}
					configurations={data.configurations}
				/>
			{/key}
		{:else if activeTab === 'reference'}
			{#key data.revision}
				<MetricCatalogReferenceEditor
					domain={data.domain}
					forms={data.forms}
					configurations={data.configurations}
					metres={data.options.metres}
				/>
			{/key}
		{:else if activeTab === 'editor'}
			<MetricEditorSandbox {data} />
		{:else if activeTab === 'traceability'}
			<div class="mb-5 border-l-4 border-sky-500 bg-sky-50 p-4 text-sm leading-6 text-sky-950">
				Esta sección conserva cómo se transformó el vocabulario anterior. Es un informe de
				trazabilidad: sus pendientes no bloquean la edición, la validación ni el demarcador.
			</div>
			<MetricMigrationReview
				rows={data.migrationRows}
				forms={data.forms}
				configurations={data.configurations}
			/>
		{:else}
			<div class="grid gap-6 xl:grid-cols-[minmax(0,1.5fr)_minmax(20rem,1fr)]">
				<section class="space-y-4">
					<div>
						<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
							Control del modelo
						</p>
						<h2 class="mt-1 text-xl font-semibold">Incidencias calculadas</h2>
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							Los avisos señalan información que conviene revisar. Un campo vacío no se considera
							por sí solo un error: puede expresar variabilidad o que el rasgo no es aplicable.
						</p>
					</div>

					<div class="space-y-2">
						{#each data.issues as issue}
							<button
								type="button"
								class={`w-full border-l-4 p-4 text-left ${
									issue.level === 'error'
										? 'border-red-500 bg-red-50'
										: issue.level === 'warning'
											? 'border-amber-500 bg-amber-50'
											: 'border-sky-500 bg-sky-50'
								}`}
								onclick={() => selectIssueEntity(issue.entityId)}
							>
								<span class="block text-sm font-medium">{issue.label}</span>
								<span class="mt-1 block text-sm leading-6">{issue.message}</span>
							</button>
						{:else}
							<p class="border border-[color:var(--border)] p-5 text-sm">
								No hay incidencias calculadas.
							</p>
						{/each}
					</div>
				</section>

				<aside class="space-y-5">
					<section class="border border-[color:var(--border)] bg-[color:var(--card)] p-5">
						<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
							Preparación del demarcador
						</p>
						<p class="mt-2 text-3xl font-semibold">{demarcableConfigurations}</p>
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							configuraciones activas y demarcables
						</p>
						<p class={`mt-4 text-sm font-medium ${demarcatorReady ? 'text-green-700' : 'text-amber-800'}`}>
							{demarcatorReady
								? 'El catálogo cumple las condiciones básicas para compilar una prueba.'
								: 'Resuelve primero las incidencias estructurales y aprueba al menos una forma.'}
						</p>
						<div class="mt-5 flex flex-wrap gap-2">
							<button
								type="button"
								class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
								disabled={generatingPreview}
								onclick={generatePreview}
							>
								{generatingPreview
									? 'Generando…'
									: latestPreview && !previewIsCurrent
										? 'Actualizar prueba'
										: 'Generar prueba'}
							</button>
							{#if latestPreview}
								<a
									class="border border-[color:var(--border)] px-4 py-2 text-sm font-medium hover:bg-[color:var(--muted)]"
									href={`/demarcador?version=${latestPreview.version_id}`}
									target="_blank"
									rel="noreferrer"
								>
									Abrir prueba
								</a>
							{/if}
						</div>
						{#if latestPreview}
							<p class="mt-3 text-xs leading-5 text-[color:var(--muted-foreground)]">
								Versión {latestPreview.numero}, compilada desde la revisión
								{latestPreview.catalogo_revision ?? 'sin identificar'} del catálogo:
								{latestPreview.total_familias} formas o configuraciones candidatas.
							</p>
							{#if !previewIsCurrent}
								<p class="mt-2 text-sm leading-6 text-amber-800">
									El catálogo está ahora en la revisión {data.revision}. Actualiza la prueba para
									que el demarcador incorpore los últimos cambios.
								</p>
							{/if}
						{/if}
						{#if previewError}
							<p class="mt-3 text-sm text-red-700">{previewError}</p>
						{/if}
						{#if previewWarnings.length > 0}
							<div class="mt-3 border-l-2 border-amber-500 pl-3">
								<p class="text-xs font-medium uppercase tracking-wide text-amber-800">
									Formas omitidas de la prueba
								</p>
								<ul class="mt-1 space-y-1 text-xs leading-5 text-amber-950">
									{#each previewWarnings as warning}
										<li>{warning}</li>
									{/each}
								</ul>
							</div>
						{/if}
					</section>

					<section class="border border-[color:var(--border)] bg-[color:var(--card)] p-5">
						<h3 class="font-semibold">Familias estructurales</h3>
						<div class="mt-3 space-y-2">
							{#each data.families as family}
								<div class="flex items-baseline justify-between gap-4 text-sm">
									<span>{family.nombre}</span>
									<span class="text-[color:var(--muted-foreground)]">{family.formas} formas</span>
								</div>
							{:else}
								<p class="text-sm text-[color:var(--muted-foreground)]">Sin familias.</p>
							{/each}
						</div>
					</section>

					<section class="border border-[color:var(--border)] bg-[color:var(--card)] p-5">
						<h3 class="font-semibold">Tradiciones</h3>
						<div class="mt-3 space-y-2">
							{#each data.traditions as tradition}
								<div class="flex items-baseline justify-between gap-4 text-sm">
									<span>{tradition.nombre}</span>
									<span class="text-[color:var(--muted-foreground)]">{tradition.formas} formas</span>
								</div>
							{/each}
						</div>
						<p class="mt-4 text-xs leading-5 text-[color:var(--muted-foreground)]">
							Las tradiciones se mantienen separadas de las familias y todavía no se han inferido
							pertenencias automáticas.
						</p>
					</section>
				</aside>
			</div>
		{/if}
	{/if}
</section>
