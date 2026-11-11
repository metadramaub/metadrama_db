<script lang="ts">
	import { coincideDatacion, datacionDeObra } from '$lib/dataciones';
	import { portal } from '$lib/actions/portal';
	import { goto } from '$app/navigation';
	import { Plus, Search, SlidersHorizontal, X } from 'lucide-svelte';
	import CorpusManagement from '$lib/components/dashboard/CorpusManagement.svelte';
	import {pushToast} from '$lib/stores/toast';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import BulkAssignments from '$lib/components/dashboard/BulkAssignments.svelte';
	import CreateWorksForm from '$lib/components/dashboard/CreateWorksForm.svelte';
	import type { PageData } from './$types';

	type DashboardObra = PageData['obras'][number];

	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let estado = $state('');
	let editor = $state('');
	let tipo=$state(''),corpus=$state(''),autor=$state('');
	let desde = $state<number | undefined>();
	let hasta = $state<number | undefined>();
	let scope = $state<'mine' | 'all'>('mine');

	let createModalOpen = $state(false);
	let masFiltros = $state(false);
	let selectedIds = $state<string[]>([]);
	const selectedWorks = $derived(data.obras.filter((obra: DashboardObra) => selectedIds.includes(obra.obra_id)));
	const autorOptions = $derived(
		[...new Set<string>(data.obras.flatMap((obra: DashboardObra) => obra.autores ?? []))]
			.sort((a, b) => a.localeCompare(b, 'es'))
			.map((nombre) => ({ id: nombre, label: nombre }))
	);
	const corpusOptions = $derived([
		{ id: 'sin_corpus', label: 'Sin corpus' },
		...data.corpusOptions.map(({ codigo, nombre }: { codigo: string; nombre: string }) => ({
			id: codigo,
			label: nombre + ' (' + codigo + ')'
		}))
	]);
	const tipos = [
		{ id: 'sin_ficha', label: 'Sin ficha' },
		{ id: 'basica', label: 'Básica' },
		{ id: 'completa', label: 'Completa' }
	];
	const ambitos = [{ id: 'mine', label: 'Mis obras' }, { id: 'all', label: 'Todas las obras' }];
	const filtroActivo = $derived(Boolean(q || estado || editor || tipo || corpus || autor || desde != null || hasta != null));
	const campoFiltro = 'h-9 min-w-0 w-full border border-[color:var(--border)] bg-white px-2.5 text-sm';
	async function iniciar(id:string){
		try{const r=await fetch('/api/obras/'+id+'/iniciar',{method:'POST'});if(!r.ok){const d=await r.json();pushToast('error',d.message??'No se pudo iniciar.');return;}await goto('/dashboard/obras/'+id);}catch{pushToast('error','No se pudo comprobar el inicio.');}
	}

	const canReadAll = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const control = $derived(data.modeloEditorial && canReadAll);
	const canCreate = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const estadoDropdownItems = $derived([
		{ id: 'por_iniciar', label: 'Por iniciar' },
		...data.estadoOptions
	]);
	const editorDropdownItems = $derived(
		[{id:'sin_asignar',label:'Sin asignar'},...data.editorOptions.map((option: { user_id: string; nombre_completo: string; activo: boolean | null }) => ({
			id: option.user_id,
			label: option.nombre_completo + (option.activo === false ? ' (deshabilitado)' : '')
		}))]
	);
	const filtrosAdicionales = $derived([
		estadoDropdownItems.find((item) => item.id === estado)?.label,
		editorDropdownItems.find((item) => item.id === editor)?.label,
		tipos.find((item) => item.id === tipo)?.label,
		desde != null && hasta != null ? `${desde}–${hasta}`
			: desde != null ? `Desde ${desde}` : hasta != null ? `Hasta ${hasta}` : null
	].filter(Boolean));
	const filteredObras = $derived.by(() => {
		const term = normalizeTitle(q);
		return data.obras.filter((obra: DashboardObra) => {
			if (term && !normalizeTitle(obra.titulo ?? '').includes(term)) return false;
			if (estado && obra.estadoEditorial !== estado) return false;
			if (editor==='sin_asignar' ? obra.editor_asignado!=null : editor && obra.editor_asignado !== editor) return false;
			if ((desde != null || hasta != null) && !coincideDatacion(datacionDeObra(obra), desde ?? null, hasta ?? null)) return false;
			if (tipo && obra.tipo_ficha!==tipo) return false;
			if (autor && !obra.autores?.includes(autor)) return false;
			if (corpus==='sin_corpus' && obra.corpus?.length) return false;
			if (corpus && corpus!=='sin_corpus' && !obra.corpus?.includes(corpus)) return false;
			return true;
		});
	});
	const seleccionFueraDelFiltro = $derived(
		selectedIds.length - filteredObras.filter((obra: DashboardObra) => selectedIds.includes(obra.obra_id)).length
	);

	$effect(() => {
		// Recargar los datos tras una operación por lotes no debe perder la selección.
		if (scope !== data.scope) {
			scope = data.scope;
			selectedIds = [];
		}
	});

	function goScope(nextScope: 'mine' | 'all') {
		const params = new URLSearchParams();
		params.set('scope', nextScope);
		goto(`/dashboard/obras?${params.toString()}`);
	}

	function normalizeTitle(value: string) {
		return value
			.normalize('NFD')
			.replace(/\p{Diacritic}/gu, '')
			.trim()
			.toLowerCase();
	}

	function clearFilters() {
		q = '';
		estado = '';
		editor = '';
		tipo='';corpus='';autor='';
		desde = undefined;
		hasta = undefined;
	}

</script>

{#snippet filtro(label: string, items: { id: string; label: string }[], value: string, change: (value: string) => void)}
	<div class="form-field min-w-0">
		<span class="form-label">{label}</span>
		<CheckDropdown compact search portal multiple={false} allowSingleClear
			{label} {items} placeholder="Cualquiera" selectedIds={value ? [value] : []}
			onChange={(ids) => change(ids[0] ?? '')} />
	</div>
{/snippet}

<section class="space-y-4">
	<header class="flex flex-wrap items-center justify-between gap-3">
		<div>
			<h1 class="font-display text-3xl text-[color:var(--gray-900)]">{ambitos.find((ambito) => ambito.id === data.scope)?.label}</h1>
			{#if data.puedeVerBasicas && !data.modeloEditorial}
				<a href="/dashboard/importador/fichas" class="text-sm underline">Fichas básicas</a>
			{/if}
		</div>
		<div class="flex flex-wrap gap-2">
			{#if data.modeloEditorial && canReadAll}
				<CorpusManagement corpus={data.corpusOptions} obras={data.obrasParaCorpus} />
			{/if}
			{#if canCreate}
				<Button variant="dark" onclick={() => (createModalOpen = true)}>
					<Plus size={16} aria-hidden="true" /> Crear obras
				</Button>
			{/if}
		</div>
	</header>

	{#if canReadAll}
		<div>
			<SegmentedChoice items={ambitos} value={scope} tone="neutral" ariaLabel="Ámbito de obras"
				onChange={(id) => { if (id === 'mine' || id === 'all') goScope(id); }} />
		</div>
	{/if}

	{#if control}
		<div class="grid items-end gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto]">
			{@render filtro('Autoría', autorOptions, autor, (value) => (autor = value))}
			{@render filtro('Corpus', corpusOptions, corpus, (value) => (corpus = value))}
			<button type="button" class={campoFiltro + ' inline-flex items-center justify-center gap-2 whitespace-nowrap'}
				aria-expanded={masFiltros} aria-controls="filtros-adicionales-obras"
				onclick={() => (masFiltros = !masFiltros)}>
				<SlidersHorizontal size={15} aria-hidden="true" /> Más filtros
				{#if filtrosAdicionales.length}({filtrosAdicionales.length}){/if}
			</button>
		</div>
	{/if}
	<div id="filtros-adicionales-obras" hidden={control && !masFiltros}>
		<div class="grid items-end gap-2 sm:grid-cols-2 lg:grid-cols-4">
			{@render filtro('Estado', estadoDropdownItems, estado, (value) => (estado = value))}
			{#if canReadAll}
				{@render filtro('Editor', editorDropdownItems, editor, (value) => (editor = value))}
			{/if}
			{#if control}
				{@render filtro('Ficha', tipos, tipo, (value) => (tipo = value))}
				<div class="form-field min-w-0">
					<span class="form-label">Datación</span>
					<div class="grid grid-cols-2 gap-1">
						<input type="number" bind:value={desde} aria-label="Datación desde" placeholder="Desde" class={campoFiltro} />
						<input type="number" bind:value={hasta} aria-label="Datación hasta" placeholder="Hasta" class={campoFiltro} />
					</div>
				</div>
			{/if}
		</div>
	</div>

	<div class="flex min-h-7 flex-wrap items-center justify-between gap-x-3 gap-y-1 text-sm">
		<div class="flex flex-wrap items-center gap-2 text-[color:var(--muted-foreground)]">
			<span>{filteredObras.length} de {data.obras.length} obras</span>
			{#if control && !masFiltros}
				{#each filtrosAdicionales as etiqueta}
					<span class="border border-[color:var(--border)] px-1.5 py-0.5 text-xs">{etiqueta}</span>
				{/each}
			{/if}
			{#if filtroActivo}
				<button type="button" class="inline-flex items-center gap-1 px-1 py-0.5 hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)]" onclick={clearFilters}>
					<X size={14} aria-hidden="true" /> Limpiar filtros
				</button>
			{/if}
		</div>
		{#if canCreate && selectedIds.length}
			<div class="flex items-center gap-2">
				<span>{selectedIds.length} {selectedIds.length === 1 ? 'obra seleccionada' : 'obras seleccionadas'}</span>
				{#if seleccionFueraDelFiltro > 0}
					<span class="text-xs text-[color:var(--muted-foreground)]">{seleccionFueraDelFiltro} fuera del filtro</span>
				{/if}
				<button type="button" class="rounded p-1 hover:bg-[color:var(--muted)]" aria-label="Limpiar selección" title="Limpiar selección" onclick={() => (selectedIds = [])}>
					<X size={15} aria-hidden="true" />
				</button>
			</div>
		{/if}
	</div>
	<ObrasTable
		{control}
		mostrarDatosBibliograficos={data.modeloEditorial}
		onStart={data.modeloEditorial ? iniciar : undefined}
		{selectedIds}
		onSelectionChange={canCreate ? (ids) => (selectedIds = ids) : undefined}
		obras={filteredObras}
		on:open={(event) => goto('/dashboard/obras/' + event.detail)}
	>
		{#snippet buscador()}
			<label class="relative block">
				<span class="sr-only">Buscar por título</span>
				<Search size={16} aria-hidden="true" class="pointer-events-none absolute left-2.5 top-2 text-[color:var(--muted-foreground)]" />
				<input type="search" bind:value={q} placeholder="Buscar por título"
					class="h-8 w-full border border-[color:var(--border)] bg-white pl-8 pr-2.5 text-sm" />
			</label>
		{/snippet}
	</ObrasTable>
	{#if canCreate && selectedIds.length && selectedWorks.every((obra: DashboardObra) => !['basica', 'minima'].includes(obra.tipo_ficha ?? ''))}
		<BulkAssignments works={selectedWorks} editors={data.editorOptions} oncomplete={() => (selectedIds = [])} />
	{/if}
</section>

{#if createModalOpen}
	<div use:portal class="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-black/50 p-4">
		<div class="card w-full max-w-lg space-y-4 p-5">
			<div class="flex items-center justify-between"><h2 class="text-lg font-semibold">Crear obras</h2><Button variant="ghost" onclick={() => createModalOpen = false}>Cerrar</Button></div>
			<CreateWorksForm editors={data.editorOptions} allowUnassigned={data.modeloEditorial} oncomplete={async (works) => {
				createModalOpen = false;
				if (works.length === 1 && works[0].editor_asignado) {
					await goto('/dashboard/obras/' + works[0].obra_id);
				} else if (scope === 'mine' && works.some((obra) => !obra.editor_asignado)) {
					goScope('all');
				}
			}} />
		</div>
	</div>
{/if}
