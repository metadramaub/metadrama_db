<script lang="ts">
	import { onMount } from 'svelte';
	import { beforeNavigate } from '$app/navigation';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import { currentObraStore, setCurrentObra } from '$lib/stores/currentObra';
	import type { Snippet } from 'svelte';
	import type { PageData } from './$types';

	let { data, secuencias, acciones, inicial, integrado = false }: {
		data: Pick<PageData, 'obra' | 'generoOptions' | 'roleTerm'>;
		secuencias?: Snippet;
		acciones?: Snippet;
		inicial?: string | null;
		integrado?: boolean;
	} = $props();
	let guardarDatos = $state(0);
	let guardarAutoria = $state(0);
	const tabs = $derived([
		{ id: 'datos', label: 'Datos de la obra' },
		{ id: 'autoria', label: 'Autoría' },
		...(secuencias ? [{ id: 'secuencias', label: 'Secuencias' }] : [])
	]);
	let pestaña = $state<'datos' | 'autoria' | 'secuencias'>('datos');
	const obra = $derived($currentObraStore.obra?.obra_id === data.obra.obra_id ? $currentObraStore.obra : data.obra);

	beforeNavigate(({ cancel, willUnload }) => {
		if (!$currentObraStore.dirty && !$currentObraStore.saving) return;
		if (willUnload || !window.confirm('Hay cambios pendientes de guardar. ¿Quieres salir?')) cancel();
	});

	onMount(() => {
		setCurrentObra(data.obra);
		if (inicial === 'secuencias' && secuencias) pestaña = 'secuencias';
		if (inicial === 'autoria') pestaña = 'autoria';
		return () => setCurrentObra(null);
	});
</script>

<section class="space-y-5">
	{#if !integrado}
		<a href="/dashboard/obras" class="text-sm underline">Volver a Obras</a>
		<h1 class="text-xl font-semibold">{obra.titulo}</h1>
	{/if}
	{@render acciones?.()}
	<Tabs {tabs} active={pestaña} onChange={(id) => {
		if (id === 'datos' || id === 'autoria' || id === 'secuencias') pestaña = id;
	}}>
		{#snippet actions()}
			{#if pestaña !== 'secuencias'}
			<Button loading={Boolean($currentObraStore.savingByScope[pestaña])}
				disabled={!$currentObraStore.dirtyByScope[pestaña]}
				onclick={() => {
					if (pestaña === 'datos') guardarDatos++;
					else guardarAutoria++;
				}}>Guardar</Button>
			{/if}
		{/snippet}
	</Tabs>
	<div hidden={pestaña !== 'datos'}>
		<DatosObraTab {obra} generoOptions={data.generoOptions} saveRequestToken={guardarDatos} soloDatos />
	</div>
	<div hidden={pestaña !== 'autoria'}>
		<AutoriaTab obraId={obra.obra_id} {obra} roleTerm={data.roleTerm} saveRequestToken={guardarAutoria} soloDatos />
	</div>
	<div hidden={pestaña !== 'secuencias'}>{@render secuencias?.()}</div>
</section>
