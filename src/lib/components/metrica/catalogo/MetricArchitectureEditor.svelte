<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import {
		METRIC_CATALOG_REVIEW_STATES,
		METRIC_ARCHITECTURE_GRADES,
		metricReviewStateLabel,
		type MetricCatalogConfiguration,
		type MetricCatalogOption
	} from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';
	import MetricArchitectureNormEditor from './MetricArchitectureNormEditor.svelte';

	const props = $props<{
		configuration: MetricCatalogConfiguration;
		formLevel: import('$lib/metrica/catalogo').MetricStructuralLevel;
		domain: import('$lib/metrica/catalogo').MetricCatalogDomainData;
		metres: MetricCatalogOption[];
		rhymeTypes: MetricCatalogOption[];
	}>();

	let draft = $state<MetricCatalogConfiguration>(
		untrack(() => ({ ...props.configuration }))
	);
	let saving = $state(false);
	let errorMessage = $state('');

	const changed = $derived(JSON.stringify(draft) !== JSON.stringify(props.configuration));
	const metricPatternCount = $derived(
		props.domain.metricPatterns.filter(
			(row: import('$lib/metrica/catalogo').MetricCatalogDomainRow) =>
				row.arquitectura_id === draft.arquitectura_id
		).length
	);
	const rhymePatternCount = $derived(
		props.domain.rhymePatterns.filter(
			(row: import('$lib/metrica/catalogo').MetricCatalogDomainRow) =>
				row.arquitectura_id === draft.arquitectura_id
		).length
	);
	const declaresUnitExtent = $derived(
		props.formLevel === 'estrofa' || props.formLevel === 'composicion'
	);

	function nullableId(value: string): string | null {
		return value || null;
	}

	function nullablePositiveInteger(value: string): number | null {
		if (!value.trim()) return null;
		const number = Number(value);
		return Number.isInteger(number) && number > 0 ? number : null;
	}

	async function save() {
		if (saving || !changed) return;
		saving = true;
		errorMessage = '';
		try {
			const response = await fetch('/api/metrica/configuraciones', {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					arquitectura_id: draft.arquitectura_id,
					forma_id: draft.forma_id,
					slug: draft.slug,
					nombre: draft.nombre,
					descripcion: draft.descripcion?.trim() || null,
					principal: draft.principal,
					demarcable: draft.demarcable,
					grado: draft.grado,
					tipo_rima_id: draft.tipo_rima_id,
					unidad_versos_min: declaresUnitExtent ? draft.unidad_versos_min : null,
					unidad_versos_max: declaresUnitExtent
						? (draft.unidad_versos_max ?? draft.unidad_versos_min)
						: null,
					estado_revision: draft.estado_revision,
					activo: draft.activo,
					orden: draft.orden
				})
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(
					payload.message ??
						payload.details?.[0]?.message ??
						'No se pudo guardar la arquitectura.'
				);
			}
			pushToast('success', `Arquitectura «${draft.nombre}» guardada.`);
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo guardar la arquitectura.';
		} finally {
			saving = false;
		}
	}
</script>

<details class="border border-[color:var(--border)] bg-[color:var(--background)]" open={draft.principal}>
	<summary class="cursor-pointer px-4 py-3">
		<span class="font-medium">{draft.nombre}</span>
		<span class="ml-2 font-mono text-xs text-[color:var(--muted-foreground)]">{draft.slug}</span>
		{#if draft.principal}
			<span class="ml-2 text-xs font-medium uppercase tracking-wide text-[color:var(--primary)]">
				Prototípica
			</span>
		{/if}
		{#if !draft.activo}
			<span class="ml-2 text-xs text-[color:var(--muted-foreground)]">Inactiva</span>
		{/if}
	</summary>

	<div class="space-y-5 border-t border-[color:var(--border)] p-4">
		<div class="grid gap-4 md:grid-cols-2">
			<label class="space-y-1">
				<span class="text-sm font-medium">Nombre</span>
				<input
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					bind:value={draft.nombre}
				/>
			</label>
			<label class="space-y-1">
				<span class="text-sm font-medium">Slug</span>
				<input
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 font-mono text-sm"
					bind:value={draft.slug}
				/>
				<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
					Identifica esta arquitectura dentro de la forma. No indica si es prototípica.
				</span>
			</label>
		</div>

		<label class="block space-y-1">
			<span class="text-sm font-medium">Descripción</span>
			<textarea
				rows="4"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm leading-6"
				bind:value={draft.descripcion}
			></textarea>
		</label>

		<div class="space-y-4 border-y border-[color:var(--border)] py-4">
			<div>
				<h4 class="font-medium">Norma básica</h4>
				<p class="mt-1 text-xs leading-5 text-[color:var(--muted-foreground)]">
					Primero define la arquitectura general; después concreta sus esquemas.
				</p>
			</div>
			<div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
				{#if declaresUnitExtent}
					<label class="space-y-1">
						<span class="text-sm font-medium">Versos de la unidad (mínimo)</span>
						<input
							type="number"
							min="1"
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
							value={draft.unidad_versos_min ?? ''}
							oninput={(event) =>
								(draft.unidad_versos_min = nullablePositiveInteger(event.currentTarget.value))}
						/>
						<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
							Cuántos versos tiene la unidad que define la forma. Cuántas contiene el pasaje no
							se declara: se deriva del rango.
						</span>
					</label>
					<label class="space-y-1">
						<span class="text-sm font-medium">Versos de la unidad (máximo)</span>
						<input
							type="number"
							min="1"
							class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
							value={draft.unidad_versos_max ?? ''}
							oninput={(event) =>
								(draft.unidad_versos_max = nullablePositiveInteger(event.currentTarget.value))}
						/>
						<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
							Repite el mínimo cuando la unidad es fija. Déjalos vacíos si esta arquitectura no
							fija su extensión.
						</span>
					</label>
				{:else}
					<p class="text-sm leading-6 text-[color:var(--muted-foreground)] md:col-span-2">
						{props.formLevel === 'verso'
							? 'La extensión es un verso y se deriva del nivel estructural.'
							: 'La unidad es la serie entera y su extensión no se declara.'}
					</p>
				{/if}
				<label class="space-y-1">
					<span class="text-sm font-medium">Tipo de rima</span>
					<select
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
						value={draft.tipo_rima_id ?? ''}
						onchange={(event) =>
							(draft.tipo_rima_id = nullableId(event.currentTarget.value))}
					>
						<option value="">No declarado o no aplicable</option>
						{#each props.rhymeTypes as option}
							<option value={option.id}>{option.label}</option>
						{/each}
					</select>
				</label>
			</div>
		</div>

		<div class="grid gap-3 border-y border-[color:var(--border)] py-3 text-sm sm:grid-cols-2">
			<p>
				<span class="text-[color:var(--muted-foreground)]">Esquemas métricos:</span>
				{metricPatternCount}
			</p>
			<p>
				<span class="text-[color:var(--muted-foreground)]">Esquemas de rima:</span>
				{rhymePatternCount}
			</p>
		</div>

		<MetricArchitectureNormEditor
			configurationId={draft.arquitectura_id}
			formLevel={props.formLevel}
			domain={props.domain}
			metres={props.metres}
			rhymeTypes={props.rhymeTypes}
		/>

		<div class="space-y-4 border-t border-[color:var(--border)] pt-4">
			<h4 class="font-medium">Gestión editorial</h4>
			<div class="grid gap-4 md:grid-cols-2">
				<label class="space-y-1">
					<span class="text-sm font-medium">Grado</span>
					<select
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
						bind:value={draft.grado}
					>
						{#each METRIC_ARCHITECTURE_GRADES as grade}
							<option value={grade}>{grade.replaceAll('_', ' ')}</option>
						{/each}
					</select>
				</label>
				<label class="space-y-1">
					<span class="text-sm font-medium">Estado</span>
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
			<div class="flex flex-wrap gap-x-6 gap-y-3 text-sm">
				<label class="inline-flex items-center gap-2">
					<input type="checkbox" bind:checked={draft.principal} />
					Arquitectura prototípica (opcional)
				</label>
				<label class="inline-flex items-center gap-2">
					<input type="checkbox" bind:checked={draft.demarcable} />
					Interviene en el demarcador
				</label>
				<label class="inline-flex items-center gap-2">
					<input type="checkbox" bind:checked={draft.activo} />
					Activa
				</label>
			</div>
		</div>

		{#if errorMessage}
			<p class="text-sm text-red-700">{errorMessage}</p>
		{/if}

		<div class="flex justify-end">
			<button
				type="button"
				class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
				disabled={!changed || saving}
				onclick={save}
			>
				{saving ? 'Guardando…' : 'Guardar arquitectura'}
			</button>
		</div>
	</div>
</details>
