<script lang="ts">
	import { onMount } from 'svelte';
	import { beforeNavigate } from '$app/navigation';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { currentObraStore, setCurrentObra } from '$lib/stores/currentObra';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let guardarDatos = $state(0);
	let guardarAutoria = $state(0);
	const obra = $derived($currentObraStore.obra?.obra_id === data.obra.obra_id ? $currentObraStore.obra : data.obra);

	beforeNavigate(({ cancel, willUnload }) => {
		if (!$currentObraStore.dirty && !$currentObraStore.saving) return;
		if (willUnload || !window.confirm('Hay cambios pendientes de guardar. ¿Quieres salir?')) cancel();
	});

	onMount(() => {
		setCurrentObra(data.obra);
		return () => setCurrentObra(null);
	});
</script>

<section class="space-y-5">
	<a href="/dashboard/obras" class="text-sm underline">Volver a Obras</a>
	<h1 class="text-xl font-semibold">{obra.titulo}</h1>
	<div class="space-y-3">
		<DatosObraTab {obra} generoOptions={data.generoOptions} saveRequestToken={guardarDatos} soloDatos />
		<Button loading={Boolean($currentObraStore.savingByScope.datos)}
			disabled={!$currentObraStore.dirtyByScope.datos} onclick={() => guardarDatos++}>Guardar datos</Button>
	</div>
	<div class="space-y-3 border-t border-[color:var(--border)] pt-5">
		<AutoriaTab obraId={obra.obra_id} {obra} roleTerm={data.roleTerm} saveRequestToken={guardarAutoria} soloDatos />
		<Button loading={Boolean($currentObraStore.savingByScope.autoria)}
			disabled={!$currentObraStore.dirtyByScope.autoria} onclick={() => guardarAutoria++}>Guardar autoría</Button>
	</div>
</section>
