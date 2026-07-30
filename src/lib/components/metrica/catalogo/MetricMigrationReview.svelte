<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import {
		METRIC_MIGRATION_CLASSIFICATIONS,
		METRIC_MIGRATION_CLASSIFICATION_LABELS,
		type MetricCatalogConfiguration,
		type MetricCatalogForm,
		type MetricCatalogMigrationRow,
		type MetricMigrationClassification
	} from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';

	type ReviewDraft = {
		clasificacion_decidida: MetricMigrationClassification;
		estado_revision: 'pendiente' | 'revisada';
		notas_ip: string;
	};

	const props = $props<{
		rows: MetricCatalogMigrationRow[];
		forms: MetricCatalogForm[];
		configurations: MetricCatalogConfiguration[];
	}>();

	function initialDraft(row: MetricCatalogMigrationRow): ReviewDraft {
		return {
			clasificacion_decidida:
				row.clasificacion_decidida ?? row.clasificacion_propuesta,
			estado_revision: row.estado_revision,
			notas_ip: row.notas_ip ?? ''
		};
	}

	let saved = $state<Record<string, ReviewDraft>>(
		untrack(() =>
			Object.fromEntries(
				props.rows.map((row: MetricCatalogMigrationRow) => [
					row.termino_id,
					initialDraft(row)
				])
			)
		)
	);
	let drafts = $state<Record<string, ReviewDraft>>(
		untrack(() =>
			Object.fromEntries(
				props.rows.map((row: MetricCatalogMigrationRow) => [
					row.termino_id,
					initialDraft(row)
				])
			)
		)
	);
	let search = $state('');
	let filter = $state<'all' | 'priority' | 'pending' | 'unresolved'>('priority');
	let saving = $state(false);
	let errorMessage = $state('');

	const formsById = $derived(
		new Map<string, MetricCatalogForm>(
			props.forms.map((form: MetricCatalogForm) => [form.forma_id, form])
		)
	);
	const configurationsById = $derived(
		new Map<string, MetricCatalogConfiguration>(
			props.configurations.map((configuration: MetricCatalogConfiguration) => [
				configuration.configuracion_id,
				configuration
			])
		)
	);

	const filteredRows = $derived.by(() => {
		const term = search.trim().toLocaleLowerCase('es');
		return props.rows.filter((row: MetricCatalogMigrationRow) => {
			const label = row.fuente.etiqueta?.trim() || row.fuente.termino;
			const matchesSearch =
				!term ||
				label.toLocaleLowerCase('es').includes(term) ||
				row.fuente.termino.toLocaleLowerCase('es').includes(term) ||
				row.propuesta.toLocaleLowerCase('es').includes(term);
			if (!matchesSearch) return false;
			if (filter === 'priority') {
				return row.requiere_revision && drafts[row.termino_id].estado_revision === 'pendiente';
			}
			if (filter === 'pending') {
				return drafts[row.termino_id].estado_revision === 'pendiente';
			}
			if (filter === 'unresolved') return row.destinos.length === 0;
			return true;
		});
	});

	const changedRows = $derived(
		props.rows.filter(
			(row: MetricCatalogMigrationRow) =>
				JSON.stringify(drafts[row.termino_id]) !== JSON.stringify(saved[row.termino_id])
		)
	);
	const summary = $derived.by(() => {
		const reviewed = props.rows.filter(
			(row: MetricCatalogMigrationRow) =>
				drafts[row.termino_id].estado_revision === 'revisada'
		).length;
		const priorityPending = props.rows.filter(
			(row: MetricCatalogMigrationRow) =>
				row.requiere_revision &&
				drafts[row.termino_id].estado_revision === 'pendiente'
		).length;
		return {
			reviewed,
			pending: props.rows.length - reviewed,
			priorityPending
		};
	});

	function updateDraft(termId: string, patch: Partial<ReviewDraft>) {
		drafts[termId] = { ...drafts[termId], ...patch };
	}

	function destinationLabel(
		destination: MetricCatalogMigrationRow['destinos'][number]
	): string {
		if (destination.forma_id) {
			return `Forma: ${formsById.get(destination.forma_id)?.nombre ?? destination.forma_id}`;
		}
		if (destination.configuracion_id) {
			return `Configuración: ${
				configurationsById.get(destination.configuracion_id)?.nombre ??
				destination.configuracion_id
			}`;
		}
		if (destination.familia_id) return 'Familia métrica';
		if (destination.combinacion_id) return 'Combinación de medida y rima';
		if (destination.patron_metrico_id) return 'Patrón métrico';
		if (destination.patron_rima_id) return 'Patrón de rima';
		if (destination.valor_rasgo_id) return 'Valor de rasgo';
		if (destination.rasgo_id) return 'Rasgo métrico';
		if (destination.alias_id) return 'Alias';
		return destination.tipo_operacion === 'retirar' ? 'Se retira o deriva' : 'Destino técnico';
	}

	function markVisibleAsReviewed() {
		for (const row of filteredRows) {
			updateDraft(row.termino_id, { estado_revision: 'revisada' });
		}
	}

	async function saveChanges() {
		if (saving || changedRows.length === 0) return;
		saving = true;
		errorMessage = '';
		const changes = changedRows.map((row: MetricCatalogMigrationRow) => ({
			termino_id: row.termino_id,
			clasificacion_decidida: drafts[row.termino_id].clasificacion_decidida,
			estado_revision: drafts[row.termino_id].estado_revision,
			notas_ip: drafts[row.termino_id].notas_ip.trim() || null
		}));
		try {
			const response = await fetch('/api/metrica/revision', {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ changes })
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(
					payload.message ?? payload.details?.[0]?.message ?? 'No se pudo guardar la revisión.'
				);
			}
			for (const change of changes) {
				saved[change.termino_id] = {
					clasificacion_decidida: change.clasificacion_decidida,
					estado_revision: change.estado_revision,
					notas_ip: change.notas_ip ?? ''
				};
			}
			pushToast(
				'success',
				changes.length === 1
					? 'Se ha guardado 1 decisión.'
					: `Se han guardado ${changes.length} decisiones.`
			);
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo guardar la revisión.';
		} finally {
			saving = false;
		}
	}
</script>

<div class="space-y-5">
	<div class="grid gap-3 sm:grid-cols-3">
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Decisiones revisadas</p>
			<p class="mt-1 text-2xl font-semibold">{summary.reviewed}</p>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Pendientes reales</p>
			<p class="mt-1 text-2xl font-semibold">{summary.pending}</p>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Prioritarias pendientes</p>
			<p class="mt-1 text-2xl font-semibold">{summary.priorityPending}</p>
		</div>
	</div>

	<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
		«Revisada» significa que el IP ha confirmado la reclasificación inicial. No es un estado que
		vaya a pedirse a los editores cuando registren secuencias. Si una decisión cambia el tipo de
		destino inferido, se conserva el destino original como trazabilidad hasta que se cree o ajuste
		la entidad correcta en el catálogo.
	</p>

	<div class="flex flex-col gap-3 lg:flex-row">
		<label class="flex-1">
			<span class="sr-only">Buscar término de origen</span>
			<input
				type="search"
				class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
				placeholder="Buscar término, slug o propuesta"
				bind:value={search}
			/>
		</label>
		<label>
			<span class="sr-only">Filtrar revisión</span>
			<select
				class="h-10 min-w-56 border border-[color:var(--border)] bg-white px-3 text-sm"
				bind:value={filter}
			>
				<option value="priority">Prioritarias pendientes</option>
				<option value="pending">Todas las pendientes</option>
				<option value="unresolved">Sin destino automático</option>
				<option value="all">Todos los términos</option>
			</select>
		</label>
		<button
			type="button"
			class="h-10 border border-[color:var(--border)] px-4 text-sm font-medium hover:bg-[color:var(--muted)]"
			onclick={markVisibleAsReviewed}
		>
			Marcar visibles como revisadas
		</button>
	</div>

	<div class="sticky bottom-4 z-10 flex flex-col gap-3 border border-[color:var(--border)] bg-[color:var(--background)] p-3 shadow-lg sm:flex-row sm:items-center sm:justify-between">
		<div>
			<p class="text-sm font-medium">
				{changedRows.length === 0
					? 'No hay cambios sin guardar'
					: `${changedRows.length} ${
							changedRows.length === 1 ? 'decisión modificada' : 'decisiones modificadas'
						}`}
			</p>
			{#if errorMessage}
				<p class="mt-1 text-sm text-red-700">{errorMessage}</p>
			{:else if changedRows.length > 0}
				<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
					Se guardarán juntas, incluidas las ocultas por el filtro.
				</p>
			{/if}
		</div>
		<button
			type="button"
			class="bg-[color:var(--foreground)] px-5 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
			disabled={changedRows.length === 0 || saving}
			onclick={saveChanges}
		>
			{saving ? 'Guardando…' : `Guardar cambios${changedRows.length ? ` (${changedRows.length})` : ''}`}
		</button>
	</div>

	<div class="space-y-3">
		{#each filteredRows as row (row.termino_id)}
			{@const draft = drafts[row.termino_id]}
			<article class="border border-[color:var(--border)] bg-[color:var(--card)]">
				<div class="grid gap-5 p-4 xl:grid-cols-[minmax(0,1fr)_18rem]">
					<div class="min-w-0 space-y-3">
						<div>
							<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
								<h3 class="font-semibold">{row.fuente.etiqueta?.trim() || row.fuente.termino}</h3>
								<span class="font-mono text-xs text-[color:var(--muted-foreground)]">
									{row.fuente.termino}
								</span>
								{#if row.requiere_revision}
									<span class="text-xs font-medium uppercase tracking-wide text-amber-800">
										Prioritaria
									</span>
								{/if}
							</div>
							<p class="mt-2 text-sm leading-6">{row.propuesta}</p>
						</div>

						{#if row.destinos.length > 0}
							<div class="flex flex-wrap gap-x-4 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
								{#each row.destinos as destination}
									<span>{destinationLabel(destination)}</span>
								{/each}
							</div>
						{:else}
							<p class="text-xs font-medium text-amber-800">Sin destino automático</p>
						{/if}

						<details>
							<summary class="cursor-pointer text-xs font-medium">Ver dato de origen</summary>
							<div class="mt-2 border-l-2 border-[color:var(--border)] pl-3 text-sm leading-6 text-[color:var(--muted-foreground)]">
								<p>{row.fuente.definicion || 'Sin definición.'}</p>
								<a
									class="mt-2 inline-block underline decoration-dotted underline-offset-4"
									href={`/dashboard/vocabularios/estrofa_tipo?termino=${row.termino_id}`}
								>
									Abrir término antiguo
								</a>
							</div>
						</details>
					</div>

					<div class="space-y-3 border-t border-[color:var(--border)] pt-4 xl:border-l xl:border-t-0 xl:pl-5 xl:pt-0">
						<label class="block space-y-1">
							<span class="text-xs font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Decisión
							</span>
							<select
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={draft.clasificacion_decidida}
								onchange={(event) =>
									updateDraft(row.termino_id, {
										clasificacion_decidida: event.currentTarget
											.value as MetricMigrationClassification
									})}
							>
								{#each METRIC_MIGRATION_CLASSIFICATIONS as classification}
									<option value={classification}>
										{classification} · {METRIC_MIGRATION_CLASSIFICATION_LABELS[classification]}
									</option>
								{/each}
							</select>
						</label>

						<label class="block space-y-1">
							<span class="text-xs font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Nota del IP
							</span>
							<textarea
								rows="3"
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={draft.notas_ip}
								oninput={(event) =>
									updateDraft(row.termino_id, { notas_ip: event.currentTarget.value })}
							></textarea>
						</label>

						<label class="flex items-center gap-2 text-sm">
							<input
								type="checkbox"
								checked={draft.estado_revision === 'revisada'}
								onchange={(event) =>
									updateDraft(row.termino_id, {
										estado_revision: event.currentTarget.checked ? 'revisada' : 'pendiente'
									})}
							/>
							Reclasificación revisada
						</label>
						<p class="text-xs text-[color:var(--muted-foreground)]">
							Certeza de la inferencia: {row.certeza}
						</p>
					</div>
				</div>
			</article>
		{:else}
			<p class="border border-dashed border-[color:var(--border)] p-5 text-sm text-[color:var(--muted-foreground)]">
				No hay términos que coincidan con este filtro.
			</p>
		{/each}
	</div>
</div>
