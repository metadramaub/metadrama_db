<script lang="ts">
	import { coincideDatacion, datacionDeObra } from '$lib/dataciones';
	import { portal } from '$lib/actions/portal';
	import { goto } from '$app/navigation';
	import CorpusManagement from '$lib/components/dashboard/CorpusManagement.svelte';
	import {pushToast} from '$lib/stores/toast';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import BulkAssignments from '$lib/components/dashboard/BulkAssignments.svelte';
	import CreateWorksForm from '$lib/components/dashboard/CreateWorksForm.svelte';
	import { displayTerm } from '$lib/utils/vocabulario';
	import type { PageData } from './$types';

	type DashboardObra = PageData['obras'][number];

	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let estado = $state('');
	let editor = $state('');
	let tipo=$state(''),corpus=$state(''),autor=$state('');
	let desde=$state<number|''>(''),hasta=$state<number|''>('');
	let scope = $state<'mine' | 'all'>('mine');

	let createModalOpen = $state(false);
	let selectedIds = $state<string[]>([]);
	const selectedWorks = $derived(data.obras.filter((obra: DashboardObra) => selectedIds.includes(obra.obra_id)));
	const autorOptions=$derived([...new Set<string>(data.obras.flatMap((o:DashboardObra)=>o.autores??[]))].sort((a,b)=>a.localeCompare(b,'es')));
	async function iniciar(id:string){
		try{const r=await fetch('/api/obras/'+id+'/iniciar',{method:'POST'});if(!r.ok){const d=await r.json();pushToast('error',d.message??'No se pudo iniciar.');return;}await goto('/dashboard/obras/'+id);}catch{pushToast('error','No se pudo comprobar el inicio.');}
	}

	const canReadAll = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const canCreate = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const estadoDropdownItems = $derived(
		data.estadoOptions.map((option: { termino_id: string; termino: string; etiqueta?: string | null }) => ({
			id: option.termino_id,
			label: displayTerm(option)
		}))
	);
	const editorDropdownItems = $derived(
		[{id:'sin_asignar',label:'Sin asignar'},...data.editorOptions.map((option: { user_id: string; nombre_completo: string; activo: boolean | null }) => ({
			id: option.user_id,
			label: option.nombre_completo + (option.activo === false ? ' (deshabilitado)' : '')
		}))]
	);
	const filteredObras = $derived.by(() => {
		const term = normalizeTitle(q);
		return data.obras.filter((obra: DashboardObra) => {
			if (term && !normalizeTitle(obra.titulo ?? '').includes(term)) return false;
			if (estado && (obra.estado !== estado || (data.modeloEditorial&&obra.tipo_ficha!=='completa'))) return false;
			if (editor==='sin_asignar' ? obra.editor_asignado!=null : editor && obra.editor_asignado !== editor) return false;
			if ((desde !== '' || hasta !== '') && !coincideDatacion(datacionDeObra(obra), desde === '' ? null : Number(desde), hasta === '' ? null : Number(hasta))) return false;
			if (tipo && obra.tipo_ficha!==tipo) return false;
			if (autor && !obra.autores?.includes(autor)) return false;
			if (corpus==='sin_corpus' && obra.corpus?.length) return false;
			if (corpus && corpus!=='sin_corpus' && !obra.corpus?.includes(corpus)) return false;
			return true;
		});
	});

	$effect(() => {
		// Recargar los datos tras una operación por lotes no debe perder la selección.
		if (scope !== data.scope) {
			scope = data.scope;
			selectedIds = [];
		}
	});

	function applyFilters(event: SubmitEvent) {
		event.preventDefault();
	}

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
		desde='';hasta='';
	}

</script>

<section class="space-y-4">
	<div class="flex items-end justify-between gap-4">
		<div>
			<h1 class="text-lg font-semibold">{data.modeloEditorial&&canReadAll&&scope==='all'?'Control de obras':'Obras'}</h1>
			{#if data.puedeVerBasicas&&!data.modeloEditorial}<a href="/dashboard/importador/fichas" class="text-sm underline">Fichas básicas</a>{/if}
			<p class="text-sm text-[color:var(--muted-foreground)]">{filteredObras.length} de {data.obras.length} obras{data.modeloEditorial?' · '+data.obras.filter((o:DashboardObra)=>o.tipo_ficha==='basica').length+' básicas · '+data.obras.filter((o:DashboardObra)=>o.tipo_ficha==='completa').length+' completas':''}</p>
		</div>
		{#if canCreate}
			<Button variant="secondary" onclick={() => (createModalOpen = true)}>Crear obras</Button>
		{/if}
	</div>

	<div class="flex flex-wrap gap-2">
		<Button
			variant={scope === 'mine' ? 'primary' : 'ghost'}
			onclick={() => goScope('mine')}
		>
			Mis obras
		</Button>
		{#if canReadAll}<Button
			variant={scope === 'all' ? 'primary' : 'ghost'}
			onclick={() => goScope('all')}
		>
			Todas las obras
		</Button>{/if}
	</div>

	<form class="grid gap-3 sm:grid-cols-2 xl:grid-cols-[minmax(0,1fr)_minmax(0,14rem)_minmax(0,14rem)_auto]" onsubmit={applyFilters}>
		<label class="form-field min-w-0">
			<span class="form-label">Buscar título</span>
			<input
				type="text"
				bind:value={q}
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			/>
		</label>

		<label class="form-field min-w-0">
			<span class="form-label">Estado</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={estadoDropdownItems.length > 8}
				placeholder="Todos"
				items={estadoDropdownItems}
				selectedIds={estado ? [estado] : []}
				onChange={(ids) => {
					estado = ids[0] ?? '';
				}}
			/>
		</label>

		<label class="form-field min-w-0">
			<span class="form-label">Editor asignado</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={editorDropdownItems.length > 8}
				placeholder="Todos"
				items={editorDropdownItems}
				disabled={!canReadAll}
				selectedIds={editor ? [editor] : []}
				onChange={(ids) => {
					editor = ids[0] ?? '';
				}}
			/>
		</label>

		<div class="flex items-end gap-2">
			<Button type="submit">Aplicar filtros</Button>
			<button
				type="button"
				class="border border-[color:var(--border)] bg-white px-2 py-2 text-xs font-medium text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
				onclick={clearFilters}
			>
				Limpiar
			</button>
		</div>
	</form>
	{#if data.modeloEditorial && canReadAll}
		<div class="grid gap-3 md:grid-cols-3">
			<label class="form-field min-w-0"><span class="form-label">Ficha</span><select bind:value={tipo} class="w-full min-w-0 border border-[color:var(--border)] p-2"><option value="">Todas</option><option value="sin_ficha">Sin ficha</option><option value="basica">Básica</option><option value="completa">Completa</option></select></label>
			<label class="form-field min-w-0"><span class="form-label">Autoría</span><select bind:value={autor} class="w-full min-w-0 border border-[color:var(--border)] p-2"><option value="">Todas</option>{#each autorOptions as a}<option value={a}>{a}</option>{/each}</select></label>
			<label class="form-field min-w-0"><span class="form-label">Corpus</span><select bind:value={corpus} class="w-full min-w-0 border border-[color:var(--border)] p-2"><option value="">Todos</option><option value="sin_corpus">Sin corpus</option>{#each data.corpusOptions as c}<option value={c.codigo}>{c.codigo} · {c.nombre}</option>{/each}</select></label>
		</div>
		<div class="flex flex-wrap gap-3">
			<label class="form-field min-w-0"><span class="form-label">Datación desde</span><input type="number" bind:value={desde} class="w-full min-w-0 border border-[color:var(--border)] p-2" /></label>
			<label class="form-field min-w-0"><span class="form-label">Datación hasta</span><input type="number" bind:value={hasta} class="w-full min-w-0 border border-[color:var(--border)] p-2" /></label>
		</div>
		<CorpusManagement corpus={data.corpusOptions} {selectedIds} />
	{/if}

	{#if canCreate && selectedIds.length}
		<div class="flex items-center gap-3 text-sm"><span>{selectedIds.length} obras seleccionadas en todos los filtros</span><Button variant="ghost" onclick={() => selectedIds = []}>Limpiar selección</Button></div>
	{/if}
	<ObrasTable
		control={data.modeloEditorial&&canReadAll}
		onStart={data.modeloEditorial?iniciar:undefined}
		{selectedIds}
		onSelectionChange={canCreate ? (ids) => selectedIds = ids : undefined}
		obras={filteredObras}
		on:open={(event) => goto(`/dashboard/obras/${event.detail}`)}
		on:preview={(event) => goto(`/obras/${event.detail}`)}
	/>
	{#if canCreate && selectedIds.length && selectedWorks.every((o:DashboardObra)=>!['basica','minima'].includes(o.tipo_ficha??''))}
		<BulkAssignments works={selectedWorks} editors={data.editorOptions} oncomplete={() => selectedIds = []} />
	{/if}
</section>

{#if createModalOpen}
	<div use:portal class="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-black/50 p-4">
		<div class="card w-full max-w-lg space-y-4 p-5">
			<div class="flex items-center justify-between"><h2 class="text-lg font-semibold">Crear obras</h2><Button variant="ghost" onclick={() => createModalOpen = false}>Cerrar</Button></div>
			<CreateWorksForm editors={data.editorOptions} allowUnassigned={data.modeloEditorial} oncomplete={async (works) => {
				createModalOpen = false;
				if (works.length === 1) await goto('/dashboard/obras/' + works[0].obra_id);
			}} />
		</div>
	</div>
{/if}
