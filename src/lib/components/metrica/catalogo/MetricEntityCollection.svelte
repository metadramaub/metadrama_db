<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import type { Snippet } from 'svelte';
	import type {
		MetricCatalogDomainRow,
		MetricCatalogResource
	} from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';
	import MetricIntegerRangeField from './MetricIntegerRangeField.svelte';

	export type MetricEntityOption = {
		value: string;
		label: string;
		disabled?: boolean;
	};

	export type MetricEntityField = {
		key: string;
		label: string;
		type?: 'text' | 'textarea' | 'number' | 'checkbox' | 'select' | 'hidden' | 'integerRange';
		maxKey?: string;
		options?: MetricEntityOption[];
		required?: boolean;
		help?: string;
		placeholder?: string;
	};

	const props = $props<{
		resource: MetricCatalogResource;
		title: string;
		description?: string;
		rows: MetricCatalogDomainRow[];
		keyFields: string[];
		fields: MetricEntityField[];
		defaults?: MetricCatalogDomainRow;
		labelFields?: string[];
		emptyMessage?: string;
		compact?: boolean;
		rowContent?: Snippet<[MetricCatalogDomainRow]>;
	}>();

	let drafts = $state<Record<string, MetricCatalogDomainRow>>(
		untrack(() => createDrafts(props.rows))
	);
	let showCreate = $state(false);
	let createDraft = $state<MetricCatalogDomainRow>(
		untrack(() => ({ ...(props.defaults ?? {}) }))
	);
	let savingKey = $state<string | null>(null);
	let deletingKey = $state<string | null>(null);
	let errorMessage = $state('');

	$effect(() => {
		drafts = createDrafts(props.rows);
	});

	function rowKey(row: MetricCatalogDomainRow): string {
		return props.keyFields.map((field: string) => String(row[field] ?? '')).join('::');
	}

	function createDrafts(rows: MetricCatalogDomainRow[]) {
		return Object.fromEntries(rows.map((row) => [rowKey(row), { ...row }]));
	}

	function displayLabel(row: MetricCatalogDomainRow): string {
		for (const field of props.labelFields ?? [
			'nombre',
			'titulo',
			'slug',
			'notacion',
			'tipo',
			'posicion',
			'descripcion'
		]) {
			const value = row[field];
			if (typeof value === 'number') return `${field}: ${value}`;
			if (typeof value === 'string' && value.trim()) return value;
		}
		return `Registro ${rowKey(row).slice(0, 12)}`;
	}

	function fieldValue(draft: MetricCatalogDomainRow, field: MetricEntityField) {
		return draft[field.key] ?? (field.type === 'checkbox' ? false : '');
	}

	function setField(
		draft: MetricCatalogDomainRow,
		field: MetricEntityField,
		value: string | boolean
	) {
		if (field.type === 'number') {
			draft[field.key] = value === '' ? null : Number(value);
		} else {
			draft[field.key] = value;
		}
	}

	function keysFor(row: MetricCatalogDomainRow) {
		return Object.fromEntries(props.keyFields.map((field: string) => [field, row[field]]));
	}

	function editableValues(draft: MetricCatalogDomainRow) {
		return Object.fromEntries(
			props.fields.flatMap((field: MetricEntityField) => [
				[field.key, draft[field.key] ?? null],
				...(field.type === 'integerRange' && field.maxKey
					? [[field.maxKey, draft[field.maxKey] ?? null]]
					: [])
			])
		);
	}

	function valid(draft: MetricCatalogDomainRow) {
		return props.fields.every(
			(field: MetricEntityField) =>
				!field.required ||
				(typeof draft[field.key] === 'boolean'
					? true
					: String(draft[field.key] ?? '').trim().length > 0)
		);
	}

	async function mutate(
		method: 'POST' | 'PATCH' | 'DELETE',
		row: MetricCatalogDomainRow,
		key: string
	) {
		if ((method !== 'DELETE' && !valid(row)) || savingKey || deletingKey) return;
		if (
			method === 'DELETE' &&
			!window.confirm(
				`¿Eliminar «${displayLabel(row)}»? Las relaciones dependientes pueden eliminarse también.`
			)
		) {
			return;
		}
		if (method === 'DELETE') deletingKey = key;
		else savingKey = key;
		errorMessage = '';
		try {
			const response = await fetch('/api/metrica/entidades', {
				method,
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					resource: props.resource,
					keys: method === 'POST' ? undefined : keysFor(row),
					values: method === 'DELETE' ? undefined : editableValues(row)
				})
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) throw new Error(payload.message ?? 'No se pudo guardar el registro.');
			pushToast(
				'success',
				method === 'DELETE'
					? 'Registro eliminado.'
					: method === 'POST'
						? 'Registro creado.'
						: 'Registro guardado.'
			);
			showCreate = false;
			createDraft = { ...(props.defaults ?? {}) };
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo modificar el catálogo.';
		} finally {
			savingKey = null;
			deletingKey = null;
		}
	}
</script>

<section class={`space-y-4 ${props.compact ? '' : 'border border-[color:var(--border)] p-5'}`}>
	<header class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
		<div>
			<h3 class="font-semibold">{props.title}</h3>
			{#if props.description}
				<p class="mt-1 max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
					{props.description}
				</p>
			{/if}
		</div>
		<button
			type="button"
			class="shrink-0 border border-[color:var(--border)] px-3 py-2 text-sm font-medium hover:bg-[color:var(--muted)]"
			onclick={() => (showCreate = !showCreate)}
		>
			{showCreate ? 'Cancelar' : 'Añadir'}
		</button>
	</header>

	{#if showCreate}
		<div class="space-y-4 border border-dashed border-[color:var(--border)] bg-[color:var(--muted)] p-4">
			<p class="text-sm font-medium">Nuevo registro</p>
			<div class="grid gap-4 md:grid-cols-2">
				{#each props.fields as field}
					{#if field.type !== 'hidden'}
					{#if field.type === 'integerRange' && field.maxKey}
						<MetricIntegerRangeField
							draft={createDraft}
							minKey={field.key}
							maxKey={field.maxKey}
							label={field.label}
							help={field.help}
						/>
					{:else}
					<label class={field.type === 'textarea' ? 'space-y-1 md:col-span-2' : 'space-y-1'}>
						<span class="text-sm font-medium">{field.label}</span>
						{#if field.type === 'textarea'}
							<textarea
								rows="3"
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={String(fieldValue(createDraft, field))}
								placeholder={field.placeholder}
								oninput={(event) => setField(createDraft, field, event.currentTarget.value)}
							></textarea>
						{:else if field.type === 'select'}
							<select
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={String(fieldValue(createDraft, field))}
								onchange={(event) => setField(createDraft, field, event.currentTarget.value)}
							>
								<option value="">No declarado o no aplicable</option>
								{#each field.options ?? [] as option}
									<option value={option.value} disabled={option.disabled}>{option.label}</option>
								{/each}
							</select>
						{:else if field.type === 'checkbox'}
							<input
								type="checkbox"
								checked={Boolean(fieldValue(createDraft, field))}
								onchange={(event) => setField(createDraft, field, event.currentTarget.checked)}
							/>
						{:else}
							<input
								type={field.type === 'number' ? 'number' : 'text'}
								class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
								value={String(fieldValue(createDraft, field))}
								placeholder={field.placeholder}
								oninput={(event) => setField(createDraft, field, event.currentTarget.value)}
							/>
						{/if}
						{#if field.help}
							<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
								{field.help}
							</span>
						{/if}
					</label>
					{/if}
					{/if}
				{/each}
			</div>
			<div class="flex justify-end">
				<button
					type="button"
					class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
					disabled={!valid(createDraft) || Boolean(savingKey)}
					onclick={() => mutate('POST', createDraft, 'new')}
				>
					{savingKey === 'new' ? 'Creando…' : 'Crear'}
				</button>
			</div>
		</div>
	{/if}

	{#if errorMessage}
		<p class="text-sm text-red-700">{errorMessage}</p>
	{/if}

	<div class="space-y-2">
		{#each props.rows as row (rowKey(row))}
			{@const key = rowKey(row)}
			{@const draft = drafts[key] ?? row}
			<details class="border border-[color:var(--border)] bg-[color:var(--background)]">
				<summary class="cursor-pointer px-4 py-3 text-sm font-medium">
					{displayLabel(draft)}
				</summary>
				<div class="space-y-4 border-t border-[color:var(--border)] p-4">
					<div class="grid gap-4 md:grid-cols-2">
						{#each props.fields as field}
							{#if field.type !== 'hidden'}
							{#if field.type === 'integerRange' && field.maxKey}
								<MetricIntegerRangeField
									{draft}
									minKey={field.key}
									maxKey={field.maxKey}
									label={field.label}
									help={field.help}
								/>
							{:else}
							<label class={field.type === 'textarea' ? 'space-y-1 md:col-span-2' : 'space-y-1'}>
								<span class="text-sm font-medium">{field.label}</span>
								{#if field.type === 'textarea'}
									<textarea
										rows="3"
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										value={String(fieldValue(draft, field))}
										oninput={(event) => setField(draft, field, event.currentTarget.value)}
									></textarea>
								{:else if field.type === 'select'}
									<select
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										value={String(fieldValue(draft, field))}
										onchange={(event) => setField(draft, field, event.currentTarget.value)}
									>
										<option value="">No declarado o no aplicable</option>
										{#each field.options ?? [] as option}
											<option value={option.value} disabled={option.disabled}>{option.label}</option>
										{/each}
									</select>
								{:else if field.type === 'checkbox'}
									<input
										type="checkbox"
										checked={Boolean(fieldValue(draft, field))}
										onchange={(event) => setField(draft, field, event.currentTarget.checked)}
									/>
								{:else}
									<input
										type={field.type === 'number' ? 'number' : 'text'}
										class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
										value={String(fieldValue(draft, field))}
										oninput={(event) => setField(draft, field, event.currentTarget.value)}
									/>
								{/if}
								{#if field.help}
									<span class="block text-xs leading-5 text-[color:var(--muted-foreground)]">
										{field.help}
									</span>
								{/if}
							</label>
							{/if}
							{/if}
						{/each}
					</div>
					{#if props.rowContent}
						<div class="border-t border-[color:var(--border)] pt-4">
							{@render props.rowContent(draft)}
						</div>
					{/if}
					<div class="flex flex-wrap justify-end gap-2">
						<button
							type="button"
							class="border border-red-300 px-3 py-2 text-sm text-red-700 disabled:opacity-40"
							disabled={Boolean(savingKey || deletingKey)}
							onclick={() => mutate('DELETE', row, key)}
						>
							{deletingKey === key ? 'Eliminando…' : 'Eliminar'}
						</button>
						<button
							type="button"
							class="bg-[color:var(--foreground)] px-4 py-2 text-sm font-medium text-[color:var(--background)] disabled:opacity-40"
							disabled={!valid(draft) || Boolean(savingKey || deletingKey)}
							onclick={() => mutate('PATCH', draft, key)}
						>
							{savingKey === key ? 'Guardando…' : 'Guardar'}
						</button>
					</div>
				</div>
			</details>
		{:else}
			<p class="text-sm text-[color:var(--muted-foreground)]">
				{props.emptyMessage ?? 'Todavía no hay registros.'}
			</p>
		{/each}
	</div>
</section>
