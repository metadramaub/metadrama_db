<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import type { PageData } from './$types';
	let {data}: {data:PageData} = $props();
	let guardando=$state(false),mensaje=$state('');
	async function iniciar(){
		if(guardando)return;
		guardando=true;mensaje='';
		try{
			const r=await fetch(`/api/obras/${data.obraId}/iniciar`,{method:'POST'});
			if(!r.ok){const d=await r.json();mensaje=d.message??'No se pudo iniciar la ficha.';return;}
			await goto(`/dashboard/obras/${data.obraId}`,{invalidateAll:true});
		}catch{mensaje='No se pudo comprobar el inicio. Vuelve al listado antes de reintentar.';}
		finally{guardando=false;}
	}
</script>

<section class="card space-y-4 p-5">
	<h1 class="text-lg font-semibold">{data.titulo}</h1>
	<p>La ficha completa está encargada y todavía no se ha iniciado.</p>
	{#if data.puedeIniciar}
		<Button loading={guardando} onclick={iniciar}>Iniciar ficha completa</Button>
	{:else}
		<p>El editor responsable iniciará la elaboración.</p>
	{/if}
	{#if mensaje}<p role="alert">{mensaje}</p>{/if}
	<a class="block underline" href="/dashboard/obras">Volver a mis obras</a>
</section>
