<script lang="ts">
	import { datacionDeObra, limitesDatacion, mediaDatacion, formatoDatacion } from '$lib/dataciones';
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
		canStartComplete?: boolean;
		canComment?: boolean;
		canReview?: boolean;
		canChangeState?: boolean;
		canPreviewPublicFicha?: boolean;
		tipo_ficha?: string;
		autores?: string[];
		corpus?: string[];
		dataciones?: unknown;
		fecha_inicio_trad?: number|null;
		fecha_fin_trad?: number|null;
		inicio_elaboracion?: string|null;
		procedencia_registro?: string|null;
	}

	const props = $props<{
		obras: ObraRow[];
		selectedIds?: string[];
		onSelectionChange?: (ids: string[]) => void;
		embedded?: boolean;
		control?: boolean;
		onStart?: (id:string)=>void;
	}>();
	const selected = $derived(props.selectedIds ?? []);
	const allSelected = $derived(props.obras.length > 0 && props.obras.every((obra: ObraRow) => selected.includes(obra.obra_id)));
	function toggleSelection(id: string) {
		props.onSelectionChange?.(selected.includes(id) ? selected.filter((value: string) => value !== id) : [...selected, id]);
	}
	function toggleAll() {
		const visible = new Set(props.obras.map((obra: ObraRow) => obra.obra_id));
		props.onSelectionChange?.(allSelected ? selected.filter((id: string) => !visible.has(id)) : [...new Set([...selected, ...visible])]);
	}
	const dispatch = createEventDispatcher<{ open: string; preview: string }>();
	type SortField = 'titulo' | 'updated_at' | 'autor' | 'editor' | 'inicio' | 'fin' | 'media' | 'corpus';
	type SortDirection = 'asc' | 'desc';
	let sortField = $state<SortField>('updated_at');
	let sortDirection = $state<SortDirection>('desc');

	const sortedObras = $derived.by(() => {
		const rows = [...props.obras];
		rows.sort((a, b) => {
			if (['inicio','fin','media'].includes(sortField)) {
				const valor=(o:ObraRow)=>{ const d=datacionDeObra(o); const l=limitesDatacion(d); return sortField==='inicio'?l.inicio:sortField==='fin'?l.fin:mediaDatacion(d); };
				const x=valor(a),y=valor(b);
				if(x==null)return y==null?0:1;if(y==null)return -1;
				return (x-y)*(sortDirection==='asc'?1:-1);
			}
			if(['autor','editor','corpus'].includes(sortField)){
				const valor=(o:ObraRow)=>sortField==='autor'?(o.autores??[]).join(', '):sortField==='corpus'?(o.corpus??[]).join(', '):o.editorNombre;
				return valor(a).localeCompare(valor(b),'es',{sensitivity:'base'})*(sortDirection==='asc'?1:-1);
			}
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
		sortDirection = field === 'updated_at' ? 'desc' : 'asc';
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

<div class={props.embedded ? 'overflow-x-auto' : 'card overflow-x-auto'}>
	<table class="min-w-full text-left text-sm">
		<thead class="bg-[color:var(--muted)]">
			<tr>
				{#if props.onSelectionChange}<th class="px-3 py-2"><input type="checkbox" aria-label="Seleccionar todas las obras filtradas" checked={allSelected} onchange={toggleAll} /></th>{/if}
				<th class="px-3 py-2">
					<button class="underline-offset-2 hover:underline" onclick={() => toggleSort('titulo')}>
						Título{sortIndicator('titulo')}
					</button>
				</th>
				<th class="px-3 py-2">Estado</th>
				{#if props.control}
					<th class="px-3 py-2"><button onclick={()=>toggleSort('autor')}>Autoría{sortIndicator('autor')}</button></th>
					<th class="px-3 py-2"><button onclick={()=>toggleSort('inicio')}>Inicio{sortIndicator('inicio')}</button> / <button onclick={()=>toggleSort('fin')}>Fin{sortIndicator('fin')}</button> / <button onclick={()=>toggleSort('media')}>Media{sortIndicator('media')}</button></th>
					<th class="px-3 py-2"><button onclick={()=>toggleSort('corpus')}>Corpus{sortIndicator('corpus')}</button></th>
				{/if}
				<th class="px-3 py-2"><button onclick={()=>toggleSort('editor')}>Editor{sortIndicator('editor')}</button></th>
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
					<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={(props.onSelectionChange ? 6 : 5)+(props.control?3:0)}>
						No hay obras para mostrar.
					</td>
				</tr>
			{:else}
				{#each sortedObras as obra}
					<tr class="border-t border-[color:var(--border)]">
						{#if props.onSelectionChange}<td class="px-3 py-2"><input type="checkbox" aria-label={`Seleccionar ${obra.titulo}`} checked={selected.includes(obra.obra_id)} onchange={() => toggleSelection(obra.obra_id)} /></td>{/if}
						<td class="px-3 py-2">{obra.titulo}</td>
						<td class="px-3 py-2">
							<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">{obra.estadoTerm}</span>
						</td>
						{#if props.control}
							<td class="px-3 py-2">{obra.autores?.join(' / ') || 'Sin indicar'}</td>
							<td class="px-3 py-2">{formatoDatacion(datacionDeObra(obra))}</td>
							<td class="px-3 py-2">{obra.corpus?.join(' · ') || 'Sin corpus'}</td>
						{/if}
						<td class="px-3 py-2">{obra.editorNombre}</td>
						<td class="px-3 py-2">{formatRelative(obra.updated_at)}</td>
						<td class="px-3 py-2">
							<div class="flex items-center gap-2">
								{#if props.control && obra.tipo_ficha==='sin_ficha'}
									<a class="underline" href={'/dashboard/importador?obra='+obra.obra_id}>Importar básica</a>
									<Button variant="ghost" onclick={()=>props.onStart?.(obra.obra_id)}>Iniciar completa</Button>
								{:else if obra.canStartComplete && props.onStart}
									<Button variant="ghost" onclick={()=>props.onStart?.(obra.obra_id)}>Iniciar completa</Button>
								{:else if obra.canRead === false}
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
