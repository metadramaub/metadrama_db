<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { formatRelative } from '$lib/utils/formatters';

	export interface ObraRow {
		obra_id: string;
		slug: string | null;
		titulo: string;
		estadoTerm: string;
		editorNombre: string;
		updated_at: string | null;
		visible_publico?: boolean | null;
		canRead?: boolean;
		canEditContent?: boolean;
		canComment?: boolean;
		canReview?: boolean;
		canChangeState?: boolean;
		canPreviewPublicFicha?: boolean;
	}

	const props = $props<{ obras: ObraRow[] }>();
	const dispatch = createEventDispatcher<{ open: string; preview: string }>();
	type SortField = 'titulo' | 'updated_at';
	type SortDirection = 'asc' | 'desc';
	let sortField = $state<SortField>('updated_at');
	let sortDirection = $state<SortDirection>('desc');

	const sortedObras = $derived.by(() => {
		const rows = [...props.obras];
		rows.sort((a, b) => {
			if (sortField === 'titulo') {
				const comparison = a.titulo.localeCompare(b.titulo, 'es', { sensitivity: 'base' });
				return sortDirection === 'asc' ? comparison : -comparison;
			}
			const aTs = a.updated_at ? Date.parse(a.updated_at) : 0;
			const bTs = b.updated_at ? Date.parse(b.updated_at) : 0;
			const comparison = aTs - bTs;
			return sortDirection === 'asc' ? comparison : -comparison;
		});
		return rows;
	});

	function toggleSort(field: SortField) {
		if (sortField === field) {
			sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
			return;
		}
		sortField = field;
		sortDirection = field === 'titulo' ? 'asc' : 'desc';
	}

	function sortIndicator(field: SortField): string {
		if (sortField !== field) return '';
		return sortDirection === 'asc' ? ' ↑' : ' ↓';
	}

	function actionLabel(obra: ObraRow) {
		if (obra.canEditContent) return 'Editar';
		if (obra.canReview || obra.canComment || obra.canChangeState) return 'Revisar';
		return 'Ver';
	}

	function actionHint(obra: ObraRow) {
		if (obra.canRead === false) return '';
		if (obra.canEditContent) return '';
		if (obra.canReview || obra.canComment || obra.canChangeState) return 'Solo revisión';
		return 'Solo lectura';
	}

	function canOpenPreview(obra: ObraRow) {
		return Boolean(obra.slug && obra.canPreviewPublicFicha);
	}

	// Obra ajena que no puedo abrir en el dashboard: si tiene ficha pública visible,
	// ofrezco su ficha; si no, no muestro ninguna acción.
	// visible_publico solo puede ser true cuando la obra está en estado publicado
	// (lo garantiza un trigger en BD), así que basta con comprobar ese flag.
	function canOpenPublicFicha(obra: ObraRow) {
		return obra.canRead === false && Boolean(obra.slug) && obra.visible_publico === true;
	}
</script>

<div class="card overflow-x-auto">
	<table class="min-w-full text-left text-sm">
		<thead class="bg-[color:var(--muted)]">
			<tr>
				<th class="px-3 py-2">
					<button class="underline-offset-2 hover:underline" onclick={() => toggleSort('titulo')}>
						Título{sortIndicator('titulo')}
					</button>
				</th>
				<th class="px-3 py-2">Estado</th>
				<th class="px-3 py-2">Editor</th>
				<th class="px-3 py-2">
					<button class="underline-offset-2 hover:underline" onclick={() => toggleSort('updated_at')}>
						Última modificación{sortIndicator('updated_at')}
					</button>
				</th>
				<th class="px-3 py-2">Acciones</th>
			</tr>
		</thead>
		<tbody>
			{#if sortedObras.length === 0}
				<tr>
					<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={5}>
						No hay obras para mostrar.
					</td>
				</tr>
			{:else}
				{#each sortedObras as obra}
					<tr class="border-t border-[color:var(--border)]">
						<td class="px-3 py-2">{obra.titulo}</td>
						<td class="px-3 py-2">
							<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">{obra.estadoTerm}</span>
						</td>
						<td class="px-3 py-2">{obra.editorNombre}</td>
						<td class="px-3 py-2">{formatRelative(obra.updated_at)}</td>
						<td class="px-3 py-2">
							<div class="flex items-center gap-2">
								{#if obra.canRead === false}
									{#if canOpenPublicFicha(obra)}
										<Button
											variant="secondary"
											onclick={() => obra.slug && dispatch('preview', obra.slug)}
										>
											Ver ficha
										</Button>
									{/if}
								{:else}
									<Button variant="ghost" onclick={() => dispatch('open', obra.obra_id)}>
										{actionLabel(obra)}
									</Button>
									{#if actionHint(obra)}
										<span class="text-xs text-[color:var(--muted-foreground)]">{actionHint(obra)}</span>
									{/if}
									{#if canOpenPreview(obra)}
										<Button
											variant="secondary"
											onclick={() => obra.slug && dispatch('preview', obra.slug)}
										>
											Vista previa
										</Button>
									{/if}
								{/if}
							</div>
						</td>
					</tr>
				{/each}
			{/if}
		</tbody>
	</table>
</div>
