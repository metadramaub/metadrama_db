<script lang="ts">
	import type { CorreccionFuente, FilaRevisionFuente, RevisionFuente } from '$lib/importador-metrico/types';

	let { filas, sinJornadas, revision, alCambiar } = $props<{
		filas: FilaRevisionFuente[];
		sinJornadas: boolean;
		revision: RevisionFuente;
		alCambiar: (valor: RevisionFuente) => void;
	}>();
	let ref = $state('');
	let inicio = $state<number>();
	let fin = $state<number>();
	let recuento = $state<number>();
	let motivo = $state('');
	const fila = $derived(filas.find((f: FilaRevisionFuente) => f.id === ref));

	function seleccionar(id: string) {
		ref = id;
		const original = filas.find((f: FilaRevisionFuente) => f.id === id);
		const corregida = revision.correcciones.find((c: CorreccionFuente) => c.tramo_ref === id);
		const datos = corregida ?? original;
		inicio = datos?.v_ini ?? undefined;
		fin = datos?.v_fin ?? undefined;
		recuento = datos?.n_versos_fuente ?? undefined;
		motivo = corregida?.motivo ?? '';
	}

	function aplicar() {
		if (!fila || !inicio || !fin || !motivo.trim()) return;
		alCambiar({
			...revision,
			correcciones: [...revision.correcciones.filter((c: CorreccionFuente) => c.tramo_ref !== ref),
				{ tramo_ref: ref, v_ini: inicio, v_fin: fin, n_versos_fuente: recuento ?? null, motivo: motivo.trim() }]
		});
		seleccionar('');
	}

	function retirar(id: string) {
		if (ref === id) seleccionar('');
		alCambiar({ ...revision, correcciones: revision.correcciones.filter((c: CorreccionFuente) => c.tramo_ref !== id) });
	}
</script>

{#if sinJornadas}
	<label class="form-field">
		<span class="form-label">Verso final de cada jornada</span>
		<input type="text" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
			value={revision.finales} oninput={(e) => alCambiar({ ...revision, finales: e.currentTarget.value })}
			aria-describedby="ayuda-finales" />
	</label>
	<p id="ayuda-finales" class="text-sm text-[color:var(--muted-foreground)]">
		Consulta la edición e indica los finales en orden, separados por comas. Incluye el último verso de la tabla. Si una fila cruza un límite, divídela antes en la vista previa.
	</p>
{/if}
{#if filas.length}
	<details class="space-y-3 rounded-md border border-[color:var(--border)] p-3">
		<summary class="cursor-pointer font-medium">
			Corregir rangos o recuentos de la fuente
			{#if revision.correcciones.length}({revision.correcciones.length}){/if}
		</summary>
		<p class="text-sm">Coteja la foto y aplica la corrección a la copia de trabajo. La transcripción original quedará registrada.</p>
		{#if revision.correcciones.length}
			<ul class="space-y-2 text-sm">
				{#each revision.correcciones as c (c.tramo_ref)}
					<li class="flex flex-wrap items-center gap-2">
						<span>{c.tramo_ref} · vv. {c.v_ini}–{c.v_fin}{c.n_versos_fuente === null ? '' : ' · ' + c.n_versos_fuente + ' versos'} · {c.motivo}</span>
						<button type="button" class="underline" onclick={() => seleccionar(c.tramo_ref)}>Editar</button>
						<button type="button" class="underline" onclick={() => retirar(c.tramo_ref)}>Retirar</button>
					</li>
				{/each}
			</ul>
		{/if}
		<label class="form-field">
			<span class="form-label">Fila de la transcripción</span>
			<select class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				value={ref} onchange={(e) => seleccionar(e.currentTarget.value)}>
				<option value="">Selecciona una fila</option>
				{#each filas as f, i}
					<option value={f.id}>{i + 1} · {f.id} · {f.denominacion_literal ?? 'Sin denominación'} · vv. {f.v_ini ?? '—'}–{f.v_fin ?? '—'}</option>
				{/each}
			</select>
		</label>
		{#if fila}
			<p class="text-sm">
				Original{fila.pagina === null ? '' : ' · p. ' + fila.pagina}
				· vv. {fila.v_ini ?? '—'}–{fila.v_fin ?? '—'}
				· {fila.n_versos_fuente === null ? 'sin recuento' : fila.n_versos_fuente + ' versos'}
			</p>
			<div class="grid gap-3 sm:grid-cols-3">
				<label class="form-field">
					<span class="form-label">Verso inicial</span>
					<input class="rounded-md border px-2 py-1" type="number" min="1" bind:value={inicio} />
				</label>
				<label class="form-field">
					<span class="form-label">Verso final</span>
					<input class="rounded-md border px-2 py-1" type="number" min="1" bind:value={fin} />
				</label>
				<label class="form-field">
					<span class="form-label">Recuento</span>
					<input class="rounded-md border px-2 py-1" type="number" min="1" bind:value={recuento} />
				</label>
			</div>
			<label class="form-field">
				<span class="form-label">Motivo de la corrección</span>
				<input class="rounded-md border px-2 py-1" maxlength="2000" bind:value={motivo} />
			</label>
			<button type="button" class="rounded-md border px-3 py-2 text-sm disabled:opacity-50"
				disabled={!inicio || !fin || !motivo.trim()} onclick={aplicar}>Aplicar a la copia de trabajo</button>
		{/if}
	</details>
{/if}
