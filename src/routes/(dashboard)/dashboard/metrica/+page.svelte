<script lang="ts">
	import { browser } from '$app/environment';
	import { page } from '$app/stores';
	import { get } from 'svelte/store';
	import MetricCatalogGuide from '$lib/components/metrica/catalogo/MetricCatalogGuide.svelte';
	import MetricEditorSandbox from '$lib/components/metrica/editor-v2/MetricEditorSandbox.svelte';
	import MetricShadowAnnotation from '$lib/components/metrica/editor-v2/MetricShadowAnnotation.svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import {
		type MetricCatalogConfiguration,
		type MetricCatalogForm,
		type MetricCatalogIssue,
		type MetricCatalogPageData
	} from '$lib/metrica/catalogo';

	type ActiveTab =
		| 'guide'
		| 'editor'
		| 'shadow'
		| 'validation';
	const activeTabs = new Set<ActiveTab>([
		'guide',
		'editor',
		'shadow',
		'validation'
	]);

	let { data } = $props<{ data: MetricCatalogPageData }>();
	let activeTab = $state<ActiveTab>(resolveTab(get(page).url.searchParams.get('tab')));

	const tabs = [
		{ id: 'guide', label: 'Guía del modelo' },
		{ id: 'editor', label: 'Editor de prueba' },
		{ id: 'shadow', label: 'Anotación en sombra' },
		{ id: 'validation', label: 'Validación y demarcador' }
	];

	const demarcableConfigurations = $derived(
		data.configurations.filter(
			(configuration: MetricCatalogConfiguration) =>
				configuration.activo && configuration.demarcable
		).length
	);
	const demarcatorReady = $derived(
			data.issues.filter((issue: MetricCatalogIssue) => issue.level === 'error').length === 0 &&
			// Antes se exigía además que hubiera formas «aprobadas». Ese estado se retiró el 20 de
			// agosto de 2026: no lo escribía nadie desde que el gestor mutable desapareció, y lo
			// que decía era el rastro de la última pantalla que tocó cada fila. La condición real
			// es la que queda — que el catálogo tenga formas y ningún error.
			data.stats.forms > 0
	);

	function resolveTab(value: string | null | undefined): ActiveTab {
		if (!value) return 'editor';
		return activeTabs.has(value as ActiveTab) ? (value as ActiveTab) : 'editor';
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
			(item: MetricCatalogConfiguration) => item.arquitectura_id === entityId
		);
		const form =
			directForm ??
			data.forms.find(
				(item: MetricCatalogForm) => item.forma_id === configuration?.forma_id
			);
		if (!form || !browser) return;
		window.open(`/formas/${form.slug}`, '_blank', 'noopener,noreferrer');
	}

</script>

<svelte:head>
	<title>Dominio métrico | METADRAMA</title>
</svelte:head>

<section class="mx-auto w-full max-w-[95rem] space-y-6 px-4 py-6 sm:px-6 lg:px-8">
	<header class="space-y-2">
		<p class="text-xs font-semibold uppercase tracking-[0.16em] text-[color:var(--muted-foreground)]">
			Dominio métrico
		</p>
		<div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
			<div>
				<h1 class="text-2xl font-semibold tracking-tight text-[color:var(--foreground)] sm:text-3xl">
					Dominio métrico
				</h1>
				<p class="mt-2 max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
					Prueba el Editor V2 y revisa el estado del modelo y del demarcador. Los cambios
					estructurales del catálogo se aplican mediante migraciones.
				</p>
				<a
					class="mt-2 inline-flex text-sm font-medium underline underline-offset-4"
					href="/formas"
					target="_blank"
					rel="noreferrer"
				>
					Abrir catálogo público ↗
				</a>
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
				Última requerida: 20260730107000_salidas_editoriales_irregular_verso_aislado.sql
			</p>
		</div>
	{:else}
		<div class="grid max-w-xl gap-3 sm:grid-cols-2">
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Formas métricas</p>
				<p class="mt-1 text-2xl font-semibold">{data.stats.forms}</p>
			</div>
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs text-[color:var(--muted-foreground)]">Arquitecturas</p>
				<p class="mt-1 text-2xl font-semibold">{data.stats.configurations}</p>
			</div>
		</div>

		<Tabs {tabs} active={activeTab} onChange={selectTab} />

		{#if activeTab === 'guide'}
			<MetricCatalogGuide />
		{:else if activeTab === 'editor'}
			<MetricEditorSandbox {data} />
		{:else if activeTab === 'shadow'}
			<MetricShadowAnnotation {data} />
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
							arquitecturas activas y demarcables
						</p>
						<p class={`mt-4 text-sm font-medium ${demarcatorReady ? 'text-green-700' : 'text-amber-800'}`}>
							{demarcatorReady
								? 'El demarcador puede consultar directamente el catálogo actual.'
								: 'Resuelve primero las incidencias estructurales y aprueba al menos una forma.'}
						</p>
						<a
							class="mt-5 inline-flex bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)]"
							href="/demarcador"
							target="_blank"
							rel="noreferrer"
						>
							Abrir demarcador
						</a>
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
							El ámbito histórico del que procede una forma. Es una pertenencia, no una herencia:
							no organiza el selector ni transmite rasgos estructurales.
						</p>
					</section>
				</aside>
			</div>
		{/if}
	{/if}
</section>
