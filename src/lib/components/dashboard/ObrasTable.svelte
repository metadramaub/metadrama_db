<script lang="ts">
	import { datacionDeObra, limitesDatacion, mediaDatacion, formatoDatacion } from '$lib/dataciones';
	import { createEventDispatcher, onMount, type Snippet } from 'svelte';
	import { ArrowDown, ArrowUp, ClipboardCheck, ExternalLink, Eye, FilePlus2, FileText, Pencil, Upload } from 'lucide-svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import { esFichaBasica } from '$lib/importador-metrico/tipo-ficha';
	import { formatRelative } from '$lib/utils/formatters';

	export interface ObraRow {
		obra_id: string;
		slug: string | null;
		titulo: string;
		estadoTerm: string;
		estadoLabel?: string;
		tipoFichaLabel?: string;
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
		autoriaLabel?: string;
		puedeEditarMetadatos?: boolean;
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
		control?: boolean;
		buscador?: Snippet;
		mostrarDatosBibliograficos?: boolean;
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
	const dispatch = createEventDispatcher<{ open: string }>();
	type SortField = 'titulo' | 'updated_at' | 'autor' | 'editor' | 'inicio' | 'fin' | 'media' | 'corpus';
	type SortDirection = 'asc' | 'desc';
	const columnas = [
		{ id: 'autor', label: 'Autoría' },
		{ id: 'datacion', label: 'Datación' },
		{ id: 'corpus', label: 'Corpus' },
		{ id: 'ficha', label: 'Ficha' },
		{ id: 'estado', label: 'Estado' },
		{ id: 'editor', label: 'Editor' },
		{ id: 'updated_at', label: 'Modificación' }
	];
	const criterios: { id: SortField; label: string }[] = [
		{ id: 'titulo', label: 'Título' },
		{ id: 'autor', label: 'Autoría' },
		{ id: 'inicio', label: 'Datación (inicio)' },
		{ id: 'fin', label: 'Datación (fin)' },
		{ id: 'media', label: 'Datación (media)' },
		{ id: 'corpus', label: 'Corpus' },
		{ id: 'editor', label: 'Editor' },
		{ id: 'updated_at', label: 'Modificación' }
	];
	let columnasVisibles = $state(columnas.filter(({ id }) => id !== 'updated_at').map(({ id }) => id));
	const claveColumnas = 'dashboard-obras-columnas';
	onMount(() => {
		if (!props.control) return;
		try {
			const guardadas: unknown = JSON.parse(localStorage.getItem(claveColumnas) ?? 'null');
			if (Array.isArray(guardadas)) columnasVisibles = columnas.filter(({ id }) => guardadas.includes(id)).map(({ id }) => id);
		} catch {
			// La preferencia de este navegador es opcional.
		}
	});

	function cambiarColumnas(ids: string[]) {
		columnasVisibles = ids;
		try {
			localStorage.setItem(claveColumnas, JSON.stringify(ids));
		} catch {
			// La selección sigue disponible durante la visita.
		}
	}
	const columnasActivas = $derived(new Set(
		props.control ? columnasVisibles : [
			...(props.mostrarDatosBibliograficos ? ['autor', 'datacion'] : []),
			'estado', 'editor', 'updated_at'
		]
	));
	const numeroColumnas = $derived(2 + columnasActivas.size + Number(Boolean(props.onSelectionChange)));
	let sortField = $state<SortField>('updated_at');
	let sortDirection = $state<SortDirection>('desc');
	let criterioDatacion = $state<'inicio' | 'fin' | 'media'>('inicio');
	const acciones = 'inline-flex size-7 items-center justify-center rounded transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2';
	const accionNeutra = 'text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)]';
	const accionEdicion = 'text-[color:var(--success)] hover:bg-[color:var(--success)] hover:text-white';

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
		cambiarOrden(field);
	}

	function cambiarOrden(field: SortField) {
		sortField = field;
		sortDirection = field === 'updated_at' ? 'desc' : 'asc';
		if (field === 'inicio' || field === 'fin' || field === 'media') criterioDatacion = field;
	}

	function sortOrder(field: SortField) {
		if (sortField !== field) return undefined;
		return sortDirection === 'asc' ? 'ascending' : 'descending';
	}

	function actionLabel(obra: ObraRow) {
		if (obra.canEditContent) return 'Editar';
		if (obra.canReview || obra.canComment || obra.canChangeState) return 'Revisar';
		return 'Ver';
	}

	function canOpenPreview(obra: ObraRow) {
		return Boolean(obra.slug && obra.canPreviewPublicFicha);
	}

	function canOpenPublicFicha(obra: ObraRow) {
		return Boolean(obra.slug && obra.visible_publico && obra.estadoTerm === 'publicado');
	}
</script>

{#snippet ordenar(field: SortField, label: string)}
	<button type="button" class="inline-flex items-center gap-0.5 whitespace-nowrap underline-offset-2 hover:underline"
		onclick={() => toggleSort(field)}>
		{label}
		{#if sortField === field}
			{#if sortDirection === 'asc'}<ArrowUp size={12} aria-hidden="true" />
			{:else}<ArrowDown size={12} aria-hidden="true" />{/if}
		{/if}
	</button>
{/snippet}

{#snippet accion(Icon: typeof Pencil, label: string, onclick: () => void, editar = false)}
	<button type="button" class={acciones + ' ' + (editar ? accionEdicion : accionNeutra)}
		aria-label={label} title={label} {onclick}>
		<Icon size={16} aria-hidden="true" />
	</button>
{/snippet}

{#snippet enlaceFicha(Icon: typeof Pencil, label: string, slug: string)}
	<a class={acciones + ' ' + accionNeutra} href={'/obras/' + slug} aria-label={label} title={label}>
		<Icon size={16} aria-hidden="true" />
	</a>
{/snippet}

{#if props.control || props.buscador}
	<div class="mb-2 flex flex-wrap items-center justify-end gap-2 text-sm">
		{#if props.buscador}
			<div class="mr-auto w-full sm:max-w-xs">{@render props.buscador()}</div>
		{/if}
		{#if props.control}
		<div class="ml-auto flex flex-wrap items-center gap-2">
		<label class="flex items-center gap-2">
			<span>Ordenar por</span>
			<select value={sortField} onchange={(event) => cambiarOrden(event.currentTarget.value as SortField)}
				class="h-8 border border-[color:var(--border)] bg-white px-2">
				{#each criterios as criterio (criterio.id)}
					<option value={criterio.id}>{criterio.label}</option>
				{/each}
			</select>
		</label>
		{@render accion(sortDirection === 'asc' ? ArrowUp : ArrowDown,
			sortDirection === 'asc' ? 'Orden ascendente. Cambiar a descendente' : 'Orden descendente. Cambiar a ascendente',
			() => toggleSort(sortField))}
		<CheckDropdown compact portal closeOnSelect={false} label="Columnas visibles" placeholder="Columnas"
			items={columnas} selectedIds={columnasVisibles} onChange={cambiarColumnas} triggerLabel="Columnas" />
		</div>
		{/if}
	</div>
{/if}

<div class="overflow-x-auto">
	<table class="w-full text-left text-sm">
		<thead class="text-xs text-[color:var(--foreground)]">
			<tr>
				{#if props.onSelectionChange}
					<th scope="col" class="w-px px-3 py-2">
						<input type="checkbox" class="align-middle accent-[color:var(--gray-900)]" aria-label="Seleccionar todas las obras filtradas" checked={allSelected} onchange={toggleAll} />
					</th>
				{/if}
				<th scope="col" class="min-w-48 px-3 py-2 font-medium" aria-sort={sortOrder('titulo')}>
					{@render ordenar('titulo', 'Título')}
				</th>
				{#if columnasActivas.has('autor')}
					<th scope="col" class="min-w-[8rem] px-3 py-2 font-medium" aria-sort={sortOrder('autor')}>
						{@render ordenar('autor', 'Autoría')}
					</th>
				{/if}
				{#if columnasActivas.has('datacion')}
					<th scope="col" class="px-3 py-2 font-medium" aria-sort={sortOrder(criterioDatacion)}>
						{@render ordenar(criterioDatacion, 'Datación')}
					</th>
				{/if}
				{#if columnasActivas.has('corpus')}
					<th scope="col" class="px-3 py-2 font-medium" aria-sort={sortOrder('corpus')}>
						{@render ordenar('corpus', 'Corpus')}
					</th>
				{/if}
				{#if columnasActivas.has('ficha')}<th scope="col" class="px-3 py-2 font-medium">Ficha</th>{/if}
				{#if columnasActivas.has('estado')}<th scope="col" class="px-3 py-2 font-medium">Estado</th>{/if}
				{#if columnasActivas.has('editor')}
					<th scope="col" class="min-w-36 px-3 py-2 font-medium" aria-sort={sortOrder('editor')}>
						{@render ordenar('editor', 'Editor')}
					</th>
				{/if}
				{#if columnasActivas.has('updated_at')}
					<th scope="col" class="px-3 py-2 font-medium" aria-sort={sortOrder('updated_at')}>
						{@render ordenar('updated_at', 'Modificación')}
					</th>
				{/if}
				<th scope="col" class="w-px px-3 py-2 text-right font-medium">Acciones</th>
			</tr>
		</thead>
		<tbody>
			{#each sortedObras as obra (obra.obra_id)}
				{@const checked = selected.includes(obra.obra_id)}
				{@const label = actionLabel(obra)}
				<tr class={`border-t border-[color:var(--border)] hover:bg-[color:var(--muted)] ${checked ? 'bg-[color:var(--muted)]' : ''}`}>
					{#if props.onSelectionChange}
						<td class="px-3 py-2">
							<input type="checkbox" class="align-middle accent-[color:var(--gray-900)]" aria-label={'Seleccionar ' + obra.titulo} {checked} onchange={() => toggleSelection(obra.obra_id)} />
						</td>
					{/if}
					<th scope="row" class="px-3 py-2 font-medium">{obra.titulo}</th>
					{#if columnasActivas.has('autor')}
						<td class="px-3 py-2 text-[color:var(--muted-foreground)]" title={obra.autoriaLabel || obra.autores?.length ? undefined : 'Sin autoría indicada'}>
							{obra.autoriaLabel || obra.autores?.join(', ') || '—'}
						</td>
					{/if}
					{#if columnasActivas.has('datacion')}
						<td class="whitespace-nowrap px-3 py-2 tabular-nums">{formatoDatacion(datacionDeObra(obra))}</td>
					{/if}
					{#if columnasActivas.has('corpus')}
						<td class="px-3 py-2 text-xs text-[color:var(--muted-foreground)]" title={obra.corpus?.length ? undefined : 'Sin corpus'}>
							{obra.corpus?.join(', ') || '—'}
						</td>
					{/if}
					{#if columnasActivas.has('ficha')}
						<td class="whitespace-nowrap px-3 py-2 text-xs">{obra.tipoFichaLabel ?? '—'}</td>
					{/if}
					{#if columnasActivas.has('estado')}
						<td class="whitespace-nowrap px-3 py-2 text-xs text-[color:var(--muted-foreground)]">{obra.estadoLabel ?? obra.estadoTerm}</td>
					{/if}
					{#if columnasActivas.has('editor')}<td class="px-3 py-2">{obra.editorNombre}</td>{/if}
					{#if columnasActivas.has('updated_at')}
						<td class="whitespace-nowrap px-3 py-2 text-xs text-[color:var(--muted-foreground)]">{formatRelative(obra.updated_at)}</td>
					{/if}
					<td class="px-3 py-2">
						<div class="flex items-center justify-end gap-0.5">
							{#if obra.puedeEditarMetadatos}
								<a class={acciones + ' ' + accionEdicion} href={'/dashboard/obras/' + obra.obra_id + '/metadatos'}
									aria-label="Editar datos de la obra" title="Editar datos de la obra"><Pencil size={16} aria-hidden="true" /></a>
							{/if}
							{#if props.control && obra.tipo_ficha === 'sin_ficha'}
								<a class={acciones + ' ' + accionNeutra} href={'/dashboard/importador?obra=' + obra.obra_id}
									aria-label="Importar básica" title="Importar básica"><Upload size={16} aria-hidden="true" /></a>
								{#if props.onStart}
									{@render accion(FilePlus2, 'Iniciar completa', () => props.onStart?.(obra.obra_id), true)}
								{/if}
							{:else if obra.canStartComplete && props.onStart}
								{@render accion(FilePlus2, 'Iniciar completa', () => props.onStart?.(obra.obra_id), true)}
							{:else if obra.canRead !== false && obra.tipo_ficha !== 'sin_ficha'}
								{@render accion(label === 'Editar' ? Pencil : label === 'Revisar' ? ClipboardCheck : esFichaBasica(obra) ? FileText : Eye,
									label + (esFichaBasica(obra) ? ' ficha básica' : ' obra'),
									() => dispatch('open', obra.obra_id), label === 'Editar')}
							{/if}
							{#if obra.slug && canOpenPreview(obra)}
								{@render enlaceFicha(Eye, 'Vista previa', obra.slug)}
							{:else if obra.slug && canOpenPublicFicha(obra)}
								{@render enlaceFicha(ExternalLink, 'Ver ficha pública', obra.slug)}
							{/if}
						</div>
					</td>
				</tr>
			{:else}
				<tr>
					<td class="px-3 py-6 text-center text-[color:var(--muted-foreground)]" colspan={numeroColumnas}>
						No hay obras para mostrar.
					</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>
