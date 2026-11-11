<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { ArrowLeft, ChevronRight, Layers, Plus, Search, X } from 'lucide-svelte';
	import Button from '$lib/components/ui/button.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import { normalizeWorkTitle } from '$lib/utils/editor-management';

	type Obra = { obra_id: string; titulo: string; autores?: string[]; corpus?: string[] };
	type Corpus = { codigo: string; nombre: string };
	type VistaObras = 'pertenecen' | 'disponibles';
	let { corpus, obras }: { corpus: Corpus[]; obras: Obra[] } = $props();

	const vistas = [
		{ id: 'pertenecen', label: 'En el corpus' },
		{ id: 'disponibles', label: 'Añadir obras' }
	];
	const inputClass = 'h-9 w-full border border-[color:var(--border)] bg-white px-2.5 text-sm';
	let dialogo = $state<HTMLDialogElement>();
	let codigo = $state('');
	let creando = $state(false);
	let nuevoCodigo = $state('');
	let nuevoNombre = $state('');
	let vista = $state<VistaObras>('pertenecen');
	let busqueda = $state('');
	let seleccion = $state<string[]>([]);
	let mensaje = $state('');
	let error = $state(false);
	let guardando = $state(false);

	const corpusActivo = $derived(corpus.find((item) => item.codigo === codigo));
	const consulta = $derived(normalizeWorkTitle(busqueda));
	const catalogo = $derived(corpus.filter((item) => normalizeWorkTitle(item.nombre + ' ' + item.codigo).includes(consulta)));
	const obrasOrdenadas = $derived([...obras].sort((a, b) => a.titulo.localeCompare(b.titulo, 'es', { sensitivity: 'base' })));
	const recuentos = $derived.by(() => {
		const recuento = new Map<string, number>();
		for (const obra of obras) {
			for (const id of obra.corpus ?? []) recuento.set(id, (recuento.get(id) ?? 0) + 1);
		}
		return recuento;
	});
	const obrasDeLaVista = $derived(obrasOrdenadas.filter((obra) =>
		Boolean(obra.corpus?.includes(codigo)) === (vista === 'pertenecen')
	));
	const resultados = $derived(obrasDeLaVista.filter((obra) =>
		normalizeWorkTitle([obra.titulo, ...(obra.autores ?? [])].join(' ')).includes(consulta)
	));
	const obrasSeleccionadas = $derived(obrasDeLaVista.filter((obra) => seleccion.includes(obra.obra_id)));
	const operacion = $derived(vista === 'disponibles' ? 'anadir' : 'retirar');

	function cantidadDeObras(id: string) {
		const cantidad = recuentos.get(id) ?? 0;
		return cantidad + (cantidad === 1 ? ' obra' : ' obras');
	}

	function limpiarLista() {
		busqueda = '';
		seleccion = [];
		mensaje = '';
	}

	function abrirCorpus(id: string) {
		codigo = id;
		creando = false;
		vista = 'pertenecen';
		limpiarLista();
	}

	function abrir() {
		abrirCorpus('');
		dialogo?.showModal();
	}

	function cambiarVista(id: string | null) {
		if (id !== 'pertenecen' && id !== 'disponibles') return;
		vista = id;
		limpiarLista();
	}

	function marcar(id: string, marcado: boolean) {
		seleccion = marcado ? [...seleccion, id] : seleccion.filter((obraId) => obraId !== id);
	}

	async function guardar(accion: 'crear' | 'anadir' | 'retirar') {
		if (guardando) return;
		const nuevo = accion === 'crear';
		const destino = nuevo ? nuevoCodigo.trim() : corpusActivo?.codigo;
		const ids = nuevo ? [] : obrasSeleccionadas.map((obra) => obra.obra_id);
		if (!destino || (nuevo ? !nuevoNombre.trim() : !ids.length || ids.length > 500)) return;

		guardando = true;
		error = false;
		mensaje = '';
		try {
			const respuesta = await fetch('/api/obras/corpus', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					operacion: accion,
					codigo: destino,
					nombre: nuevo ? nuevoNombre.trim() : undefined,
					obras: ids
				})
			});
			if (!respuesta.ok) {
				const datos = await respuesta.json();
				error = true;
				mensaje = datos.message ?? 'No se pudo guardar.';
				return;
			}
			await invalidateAll();
			seleccion = [];
			if (nuevo) {
				nuevoCodigo = '';
				nuevoNombre = '';
				abrirCorpus(destino);
				mensaje = 'Corpus creado.';
			} else {
				mensaje = accion === 'anadir' ? 'Obras añadidas al corpus.' : 'Obras retiradas del corpus.';
			}
		} catch {
			error = true;
			mensaje = 'No se pudo comprobar el resultado. Recarga antes de reintentar.';
		} finally {
			guardando = false;
		}
	}
</script>

{#snippet buscar(label: string)}
	<label class="relative block">
		<span class="sr-only">{label}</span>
		<Search size={16} aria-hidden="true" class="pointer-events-none absolute left-2.5 top-2.5 text-[color:var(--muted-foreground)]" />
		<input type="search" bind:value={busqueda} placeholder={label} class={inputClass + ' pl-8'} disabled={guardando} />
	</label>
{/snippet}

<Button variant="ghost" onclick={abrir}>
	<Layers size={16} aria-hidden="true" /> Gestionar corpus
</Button>

<dialog
	bind:this={dialogo}
	aria-labelledby="gestionar-corpus-titulo"
	class={`card m-auto max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-xl p-0 backdrop:bg-black/50 ${corpusActivo ? 'h-[min(40rem,calc(100dvh-2rem))] overflow-hidden open:flex open:flex-col' : ''}`}
	oncancel={(event) => { if (guardando) event.preventDefault(); }}
>
	<header class="flex shrink-0 items-start justify-between gap-3 border-b border-[color:var(--border)] px-5 py-4">
		<div class="flex items-start gap-2">
			{#if corpusActivo || creando}
				<button type="button" class="rounded p-1 hover:bg-[color:var(--muted)]" aria-label="Volver al catálogo de corpus" title="Volver"
					disabled={guardando} onclick={() => abrirCorpus('')}>
					<ArrowLeft size={18} aria-hidden="true" />
				</button>
			{/if}
			<div>
				<h2 id="gestionar-corpus-titulo" class="text-lg font-semibold">{corpusActivo?.nombre ?? (creando ? 'Nuevo corpus' : 'Gestionar corpus')}</h2>
				{#if corpusActivo}
					<p class="text-sm text-[color:var(--muted-foreground)]">{corpusActivo.codigo} ({cantidadDeObras(codigo)})</p>
				{/if}
			</div>
		</div>
		<button type="button" class="rounded p-1 hover:bg-[color:var(--muted)]" aria-label="Cerrar gestión de corpus" title="Cerrar" disabled={guardando} onclick={() => dialogo?.close()}>
			<X size={18} aria-hidden="true" />
		</button>
	</header>

	<div class={corpusActivo ? 'flex min-h-0 flex-1 flex-col gap-3 p-5' : 'space-y-3 p-5'}>
		{#if creando}
			<form class="space-y-4" onsubmit={(event) => { event.preventDefault(); void guardar('crear'); }}>
				<div class="grid gap-3 sm:grid-cols-[8rem_minmax(0,1fr)]">
					<label class="form-field">
						<span class="form-label">Código</span>
						<input bind:value={nuevoCodigo} maxlength="40" class={inputClass} disabled={guardando} required />
					</label>
					<label class="form-field">
						<span class="form-label">Nombre</span>
						<input bind:value={nuevoNombre} maxlength="200" class={inputClass} disabled={guardando} required />
					</label>
				</div>
				<div class="flex justify-end">
					<Button type="submit" loading={guardando} disabled={!nuevoCodigo.trim() || !nuevoNombre.trim()}>Crear corpus</Button>
				</div>
			</form>
		{:else if corpusActivo}
			<SegmentedChoice items={vistas} value={vista} ariaLabel="Obras del corpus" disabled={guardando} onChange={cambiarVista} />
			{@render buscar('Buscar por título o autoría')}
			<ul class="min-h-0 flex-1 divide-y divide-[color:var(--border)] overflow-y-auto border border-[color:var(--border)]">
				{#each resultados as obra (obra.obra_id)}
					<li>
						<label class="flex cursor-pointer items-start gap-2.5 px-3 py-2 hover:bg-[color:var(--muted)] has-[:checked]:bg-[color:var(--muted)]">
							<input type="checkbox" checked={seleccion.includes(obra.obra_id)} disabled={guardando}
								class="mt-1 shrink-0 accent-[color:var(--primary)]"
								onchange={(event) => marcar(obra.obra_id, event.currentTarget.checked)} />
							<span class="min-w-0 text-sm">
								<span class="block font-medium">{obra.titulo}</span>
								{#if obra.autores?.length}
									<span class="text-xs text-[color:var(--muted-foreground)]">{obra.autores.join(', ')}</span>
								{/if}
							</span>
						</label>
					</li>
				{:else}
					<li class="px-3 py-4 text-sm text-[color:var(--muted-foreground)]">
						{busqueda ? 'No hay obras que coincidan.' : vista === 'pertenecen' ? 'Este corpus aún no tiene obras.' : 'Todas las obras ya pertenecen a este corpus.'}
					</li>
				{/each}
			</ul>
			<div class="shrink-0 space-y-2 border-t border-[color:var(--border)] pt-2">
				<div class="flex flex-wrap items-center justify-between gap-2">
					<p aria-live="polite" class="text-sm font-medium">
						{obrasSeleccionadas.length} {obrasSeleccionadas.length === 1 ? 'obra seleccionada' : 'obras seleccionadas'}
					</p>
					<div class="flex items-center gap-2">
						{#if obrasSeleccionadas.length}
							<button type="button" class="text-xs underline underline-offset-2" disabled={guardando} onclick={() => (seleccion = [])}>
								Limpiar selección
							</button>
						{/if}
						<Button variant={operacion === 'retirar' ? 'ghost' : 'primary'} loading={guardando}
							disabled={!obrasSeleccionadas.length || obrasSeleccionadas.length > 500} onclick={() => guardar(operacion)}>
							{operacion === 'retirar' ? 'Retirar del corpus' : 'Añadir al corpus'}
						</Button>
					</div>
				</div>
				<ul aria-label="Obras seleccionadas" class="flex h-16 flex-wrap content-start gap-1 overflow-y-auto">
					{#each obrasSeleccionadas as obra (obra.obra_id)}
						<li class="max-w-full">
							<button type="button" title={obra.titulo} aria-label={'Quitar ' + obra.titulo + ' de la selección'}
								class="flex max-w-full items-center gap-1.5 border border-[color:var(--border)] px-2 py-1 text-left text-xs hover:bg-[color:var(--muted)]"
								disabled={guardando} onclick={() => marcar(obra.obra_id, false)}>
								<span class="min-w-0 break-words">{obra.titulo}</span><X size={13} aria-hidden="true" class="shrink-0" />
							</button>
						</li>
					{/each}
				</ul>
				{#if obrasSeleccionadas.length > 500}<p class="text-sm">Selecciona hasta 500 obras por operación.</p>{/if}
			</div>
		{:else}
			<div class="flex flex-wrap items-center gap-2">
				<div class="min-w-0 flex-1">{@render buscar('Buscar corpus')}</div>
				<Button variant="secondary" onclick={() => { limpiarLista(); creando = true; }}>
					<Plus size={16} aria-hidden="true" /> Nuevo corpus
				</Button>
			</div>
			<ul class="max-h-[48vh] divide-y divide-[color:var(--border)] overflow-y-auto border border-[color:var(--border)]">
				{#each catalogo as item (item.codigo)}
					<li>
						<button type="button" class="flex w-full items-center justify-between gap-3 px-3 py-2 text-left text-sm hover:bg-[color:var(--muted)]"
							onclick={() => abrirCorpus(item.codigo)}>
							<span class="min-w-0">
								<span class="block font-medium">{item.nombre}</span>
								<span class="text-xs text-[color:var(--muted-foreground)]">{item.codigo} ({cantidadDeObras(item.codigo)})</span>
							</span>
							<ChevronRight size={16} aria-hidden="true" class="shrink-0" />
						</button>
					</li>
				{:else}
					<li class="px-3 py-4 text-sm text-[color:var(--muted-foreground)]">{busqueda ? 'No hay corpus que coincidan.' : 'Aún no hay corpus.'}</li>
				{/each}
			</ul>
		{/if}
		{#if mensaje}
			<p role="status" class={error ? 'text-sm text-[color:var(--danger)]' : 'text-sm text-[color:var(--success)]'}>{mensaje}</p>
		{/if}
	</div>
</dialog>
