<script lang="ts">
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type { ActionData, PageData } from './$types';

	let { data, form } = $props<{
		data: Pick<PageData, 'pagina' | 'haySiguiente' | 'correspondencias'>;
		form: ActionData;
	}>();
	let pendiente = $state(false);
	let confirmarRetirada = $state<string | null>(null);

	const fecha = new Intl.DateTimeFormat('es-ES', { dateStyle: 'medium', timeZone: 'Europe/Madrid' });
	const accion = (nombre: string) => `?pagina=${data.pagina}&/${nombre}`;

	const enviar: SubmitFunction = ({ cancel }) => {
		if (pendiente) return cancel();
		pendiente = true;
		return async ({ result, update }) => {
			try {
				if (result.type === 'success') confirmarRetirada = null;
				await update();
				if (result.type === 'success' && typeof result.data?.exito === 'string') {
					pushToast('success', result.data.exito);
				} else if (result.type === 'failure' && typeof result.data?.mensaje === 'string') {
					pushToast('error', result.data.mensaje);
				}
			} finally {
				pendiente = false;
			}
		};
	};
</script>

<svelte:head><title>Correspondencias del importador — Versología</title></svelte:head>

<section class="space-y-5">
	<header class="flex flex-wrap items-center justify-between gap-3">
		<h1 class="font-display text-3xl">Correspondencias del importador</h1>
		<a href="/dashboard/importador" class="text-sm underline">Volver al importador</a>
	</header>

	<noscript>
		{#if form?.mensaje}<p role="alert" class="text-sm text-red-800">{form.mensaje}</p>{/if}
		{#if form?.exito}<p role="status" class="text-sm text-green-800">{form.exito}</p>{/if}
	</noscript>

	{#if data.correspondencias.length === 0}
		<p>Todavía no hay correspondencias registradas.</p>
	{:else}
		<div class="card overflow-x-auto">
			<table class="w-full text-left text-sm">
				<thead class="border-b border-[color:var(--border)]">
					<tr>
						<th scope="col" class="px-4 py-3">Término de la edición</th>
						<th scope="col" class="px-4 py-3">Identificación</th>
						<th scope="col" class="px-4 py-3">Procedencia</th>
						<th scope="col" class="px-4 py-3">Registro y revisión</th>
						<th scope="col" class="px-4 py-3">Acciones</th>
					</tr>
				</thead>
				<tbody>
					{#each data.correspondencias as item (item.id)}
						<tr class="border-b border-[color:var(--border)] align-top last:border-b-0">
							<th scope="row" class="min-w-32 break-words px-4 py-3 font-medium">{item.literal}</th>
							<td class="min-w-32 px-4 py-3">
								{item.forma}
								{#if item.arquitectura}<p>{item.arquitectura}</p>{/if}
							</td>
							<td class="min-w-44 px-4 py-3">
								<p>{item.obra ?? 'Obra sin indicar'}</p>
								{#if item.edicion}<p class="break-words">{item.edicion}</p>{/if}
								<p class="text-xs text-[color:var(--muted-foreground)]">
									{[item.fila && 'Fila ' + item.fila, item.foto, item.paginaFuente && 'p. ' + item.paginaFuente].filter(Boolean).join(' · ')}
								</p>
							</td>
							<td class="min-w-40 px-4 py-3">
								<p>{item.autor} · {fecha.format(new Date(item.creadoEn))}</p>
								{#if item.revisadoEn}
									<p>Revisada por {item.revisor} · {fecha.format(new Date(item.revisadoEn))}</p>
								{:else}
									<p>Pendiente de revisión</p>
								{/if}
							</td>
							<td class="min-w-44 px-4 py-3">
								{#if confirmarRetirada === item.id}
									<form method="POST" action={accion('retirar')} use:enhance={enviar} class="space-y-2">
										<input type="hidden" name="id" value={item.id} />
										<p>Dejará de proponerse en nuevas importaciones.</p>
										<div class="flex flex-wrap gap-2">
											<Button variant="secondary" disabled={pendiente} onclick={() => confirmarRetirada = null}>Cancelar</Button>
											<Button type="submit" variant="danger" disabled={pendiente}>Confirmar retirada</Button>
										</div>
									</form>
								{:else}
									<div class="flex flex-wrap gap-2">
										{#if !item.revisadoEn}
											<form method="POST" action={accion('revisar')} use:enhance={enviar}>
												<input type="hidden" name="id" value={item.id} />
												<Button type="submit" variant="secondary" disabled={pendiente}>Marcar revisada</Button>
											</form>
										{/if}
										<Button variant="danger" disabled={pendiente} onclick={() => confirmarRetirada = item.id}>Retirar</Button>
									</div>
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}

	{#if data.pagina > 1 || data.haySiguiente}
		<nav aria-label="Páginas del registro" class="flex flex-wrap items-center justify-end gap-4 text-sm">
			{#if data.pagina > 1}<a class="underline" href={'?pagina=' + (data.pagina - 1)}>Anterior</a>{/if}
			<span>Página {data.pagina}</span>
			{#if data.haySiguiente}<a class="underline" href={'?pagina=' + (data.pagina + 1)}>Siguiente</a>{/if}
		</nav>
	{/if}
</section>
