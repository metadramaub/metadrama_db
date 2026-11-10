<script lang="ts">
	import {invalidateAll} from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	let {corpus,selectedIds}:{corpus:{codigo:string;nombre:string}[];selectedIds:string[]}=$props();
	let codigo=$state(''),nuevoCodigo=$state(''),nombre=$state(''),mensaje=$state(''),guardando=$state(false);
	async function ejecutar(operacion:'crear'|'renombrar'|'anadir'|'retirar'){
		if(guardando)return;guardando=true;mensaje='';
		try{
			const r=await fetch('/api/obras/corpus',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({operacion,codigo:operacion==='crear'?nuevoCodigo:codigo,nombre:nombre||undefined,obras:selectedIds})});
			const d=await r.json();if(!r.ok){mensaje=d.message??'No se pudo guardar.';return;}
			mensaje='Cambios guardados.';if(operacion==='crear'){nuevoCodigo='';nombre='';}await invalidateAll();
		}catch{mensaje='No se pudo comprobar el resultado. Recarga antes de reintentar.';}finally{guardando=false;}
	}
</script>
<details class="card space-y-3 p-4">
	<summary class="cursor-pointer font-medium">Gestionar corpus{selectedIds.length?' · '+selectedIds.length+' obras seleccionadas':''}</summary>
	<div class="mt-3 flex flex-wrap items-end gap-3">
		<label class="form-field min-w-0"><span class="form-label">Corpus</span><select bind:value={codigo} class="w-full min-w-0 border border-[color:var(--border)] p-2"><option value="">Seleccionar</option>{#each corpus as c}<option value={c.codigo}>{c.codigo} · {c.nombre}</option>{/each}</select></label>
		<Button disabled={guardando||!codigo||!selectedIds.length} onclick={()=>ejecutar('anadir')}>Añadir a seleccionadas</Button>
		<Button variant="secondary" disabled={guardando||!codigo||!selectedIds.length} onclick={()=>ejecutar('retirar')}>Retirar de seleccionadas</Button>
	</div>
	<div class="mt-3 flex flex-wrap items-end gap-3">
		<label class="form-field min-w-0"><span class="form-label">Código nuevo</span><input bind:value={nuevoCodigo} maxlength="40" class="w-full min-w-0 border border-[color:var(--border)] p-2" /></label>
		<label class="form-field min-w-0"><span class="form-label">Nombre</span><input bind:value={nombre} maxlength="200" class="w-full min-w-0 border border-[color:var(--border)] p-2" /></label>
		<Button disabled={guardando||!nuevoCodigo.trim()||!nombre.trim()} onclick={()=>ejecutar('crear')}>Crear corpus</Button>
		<Button variant="secondary" disabled={guardando||!codigo||!nombre.trim()} onclick={()=>ejecutar('renombrar')}>Renombrar seleccionado</Button>
	</div>
	{#if mensaje}<p role="status" class="mt-2 text-sm">{mensaje}</p>{/if}
</details>
