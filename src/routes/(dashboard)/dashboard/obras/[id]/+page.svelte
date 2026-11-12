<script lang="ts">
	import { enhance } from '$app/forms';
	import Button from '$lib/components/ui/button.svelte';
	import FichaCompleta from './FichaCompleta.svelte';
	import SecuenciasBasicas from './SecuenciasBasicas.svelte';
	import MetadatosObra from './metadatos/MetadatosObra.svelte';
	import type { ActionData, PageData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();
	let modo = $state('');
	let pendiente = $state(false);
</script>

{#key data.obra.obra_id}
	{#if data.pantalla === 'completa'}
		<FichaCompleta {data} />
	{:else if data.pantalla === 'basica' && data.basica.puedeEditarMetadatos}
		<MetadatosObra {data} inicial={data.pestaña === 'basica' ? 'secuencias' : data.pestaña}>
			{#snippet acciones()}
				<details class="rounded-md border border-[color:var(--border)] p-3">
					<summary class="cursor-pointer font-medium">Encargar ficha completa</summary>
					<form method="POST" action="?/encargarCompleta" use:enhance={() => {
						pendiente = true;
						return async ({ update }) => {
							try { await update(); } finally { pendiente = false; }
						};
					}} class="mt-3 flex flex-wrap items-end gap-3">
						<label class="grid gap-1 text-sm">
							Editor asignado
							<select class="input" name="editor" required>
								<option value="">Selecciona un editor</option>
								{#each data.pantalla === 'basica' ? data.editores : [] as editor (editor.user_id)}
									<option value={editor.user_id}>{editor.nombre_completo}</option>
								{/each}
							</select>
						</label>
						<Button type="submit" loading={pendiente}>Encargar completa</Button>
					</form>
					{#if form?.mensaje}<p class="mt-2 text-sm text-[color:var(--danger)]" role="alert">{form.mensaje}</p>{/if}
				</details>
			{/snippet}
			{#snippet secuencias()}
				{#if data.pantalla === 'basica'}<SecuenciasBasicas data={data.basica} />{/if}
			{/snippet}
		</MetadatosObra>
	{:else if data.pantalla === 'basica' || data.pantalla === 'referencia'}
		<section class="space-y-5">
			<a href={data.pantalla === 'referencia' ? '/dashboard/obras/' + data.obra.obra_id : '/dashboard/obras'} class="text-sm underline">Volver</a>
			<h1 class="text-xl font-semibold">{data.obra.titulo}</h1>
			<h2 class="font-semibold">Ficha básica</h2>
			<SecuenciasBasicas data={data.basica} />
		</section>
	{:else}
		<section class="max-w-2xl space-y-5">
			<a href="/dashboard/obras" class="text-sm underline">Volver a Obras</a>
			<h1 class="text-xl font-semibold">{data.obra.titulo}</h1>
			<h2 class="font-semibold">Ficha completa por iniciar</h2>
			<a href={'/dashboard/obras/' + data.obra.obra_id + '?tab=basica'} class="text-sm underline">Consultar ficha básica</a>
			{#if data.puedeIniciar}
				<form method="POST" action="?/iniciarDesdeBasica" use:enhance={() => {
					pendiente = true;
					return async ({ update }) => {
						try { await update(); } finally { pendiente = false; }
					};
				}} class="space-y-4">
					<fieldset class="grid gap-3">
						<legend class="mb-2 font-medium">Cómo iniciar la ficha completa</legend>
						<label class="flex items-start gap-2">
							<input class="mt-1" type="radio" name="modo" value="reutilizar" bind:group={modo} required />
							<span>Reutilizar jornadas y secuencias<span class="block text-sm text-[color:var(--muted-foreground)]">Conserva la edición base de la básica. Las formas métricas aparecerán como propuestas.</span></span>
						</label>
						<label class="flex items-start gap-2">
							<input class="mt-1" type="radio" name="modo" value="desde_cero" bind:group={modo} />
							<span>Empezar desde cero<span class="block text-sm text-[color:var(--muted-foreground)]">Crea tu propia estructura y elige la edición base.</span></span>
						</label>
					</fieldset>
					{#if modo === 'desde_cero'}
						<label class="grid gap-1 text-sm">Edición base<textarea class="input" name="edicion" required rows="3"></textarea></label>
					{/if}
					{#if form?.mensaje}<p class="text-sm text-[color:var(--danger)]" role="alert">{form.mensaje}</p>{/if}
					<Button type="submit" loading={pendiente}>Iniciar completa</Button>
				</form>
			{/if}
		</section>
	{/if}
{/key}
