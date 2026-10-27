<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import type { FichaMinima, SegmentoMinimo } from '$lib/importador-metrico/types';
	import type { EdicionFila, FormaEditable } from '$lib/importador-metrico/edicion';
	let { datos, tramoRef, formas, ocupado = false, onaplicar, onrestablecer, oncancelar } = $props<{
		datos: FichaMinima; tramoRef: string; formas: FormaEditable[]; ocupado?: boolean;
		onaplicar: (cambio: EdicionFila) => void; onrestablecer: () => void; oncancelar: () => void;
	}>();
	const originales = $derived<SegmentoMinimo[]>(datos.segmentos.filter((s: SegmentoMinimo) => s.origen.tramo_ref === tramoRef));
	const inicio = $derived(originales[0].v_ini);
	const fin = $derived(originales.at(-1)!.v_fin);
	const tieneRemate = $derived(originales.some((s: SegmentoMinimo) => s.detalles_fuente.some((d: Record<string, unknown>) => d.tipo_seccion === 'remate')));
	let conservarRemate = $state(true);
	let mensaje = $state('');
	let panel = $state<HTMLElement>();
	onMount(() => panel?.focus());
	type Parte = { fin: string; forma: string; arquitectura: string; nota: string; corte: string };
	let partes = $state<Parte[]>(untrack(() => originales.map((s: SegmentoMinimo) => ({
		fin: String(s.v_fin), forma: s.identificacion?.forma_slug ?? '',
		arquitectura: s.identificacion?.arquitectura_slug ?? '', nota: s.nota ?? '',
		corte: ''
	}))));
	const principio = (i: number) => i ? Number(partes[i - 1].fin) + 1 : inicio;
	function dividir(i: number) {
		const p = partes[i], corte = Number(p.corte), ultimo = Number(p.fin);
		if (!Number.isInteger(corte) || corte < principio(i) || corte >= ultimo) {
			mensaje = 'El corte debe quedar dentro de la secuencia y dejar versos a ambos lados.'; return;
		}
		partes.splice(i, 1, { ...p, fin: String(corte), corte: '' }, { ...p, corte: '' });
		mensaje = '';
	}
	function unir(i: number) {
		const p = partes[i], siguiente = partes[i + 1];
		if (p.forma !== siguiente.forma || p.arquitectura !== siguiente.arquitectura) {
			mensaje = 'Elige la misma forma y arquitectura en ambas partes antes de unirlas.'; return;
		}
		partes.splice(i, 2, { ...p, fin: siguiente.fin, nota: [...new Set([p.nota, siguiente.nota].filter(Boolean))].join(' '),
			corte: '' });
		mensaje = '';
	}
	function aplicar() {
		const cambio: EdicionFila = { tramo_ref: tramoRef, partes: partes.map((p: Parte, i: number) => ({
			v_ini: principio(i), v_fin: Number(p.fin),
			identificacion: p.forma ? { forma_slug: p.forma, arquitectura_slug: p.arquitectura || null } : null,
			nota: p.nota.trim() || null, conservar_remate: conservarRemate && i === partes.length - 1
		})) };
		if (cambio.partes.some((p) => !Number.isInteger(p.v_fin) || p.v_fin < p.v_ini) || cambio.partes.at(-1)!.v_fin !== fin) {
			mensaje = 'Revisa los límites: cada parte debe contener versos y mantener el final de la fila original.'; return;
		}
		mensaje = ''; onaplicar(cambio);
	}
</script>

<section bind:this={panel} tabindex="-1" class="card space-y-4 border-l-2 border-[color:var(--foreground)] p-4 focus:outline-none sm:p-6" aria-label="Editar secuencias">
	<header class="flex flex-wrap items-start justify-between gap-3">
		<div><h3 class="font-semibold">Editar secuencias · vv. {inicio}–{fin}</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">En la edición: {originales[0].origen.denominacion_literal ?? '—'}</p></div>
		<button type="button" class="text-sm underline" onclick={oncancelar} disabled={ocupado}>Cancelar</button>
	</header>
	{#if mensaje}<p role="alert" class="border-l-2 border-red-400 bg-red-50 p-3 text-sm">{mensaje}</p>{/if}
	{#each partes as parte, i}
		<fieldset class="space-y-3 border border-[color:var(--border)] p-4" disabled={ocupado}>
			<legend class="px-1 text-sm font-medium">Secuencia {i + 1} · vv. {principio(i)}–{parte.fin}</legend>
			<div class="grid gap-3 sm:grid-cols-2">
				<label class="form-field"><span class="form-label">Forma</span>
					<select aria-label={'Forma · secuencia ' + (i + 1)} value={parte.forma} onchange={(e) => { parte.forma = e.currentTarget.value; parte.arquitectura = ''; }} class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
						<option value="">Forma sin resolver</option>
						{#each formas as forma}<option value={forma.slug}>{forma.nombre}</option>{/each}
					</select></label>
				<label class="form-field"><span class="form-label">Arquitectura <span class="font-normal">(opcional)</span></span>
					<select aria-label={'Arquitectura · secuencia ' + (i + 1) + ' (opcional)'} bind:value={parte.arquitectura} disabled={!parte.forma} class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 disabled:opacity-50">
						<option value="">Sin especificar</option>
						{#each formas.find((f: FormaEditable) => f.slug === parte.forma)?.arquitecturas ?? [] as a}<option value={a.slug}>{a.nombre}</option>{/each}
					</select></label>
				{#if i < partes.length - 1}
					<label class="form-field"><span class="form-label">Último verso <span class="font-normal text-[color:var(--danger)]" aria-label="obligatorio">*</span></span>
						<input aria-label={'Último verso · secuencia ' + (i + 1)} inputmode="numeric" bind:value={parte.fin} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" /></label>
				{/if}
				<label class="form-field sm:col-span-2"><span class="form-label">Nota <span class="font-normal">(opcional)</span></span>
					<textarea aria-label={'Nota · secuencia ' + (i + 1) + ' (opcional)'} rows="2" maxlength="4000" bind:value={parte.nota} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"></textarea></label>
			</div>
			<div class="flex flex-wrap items-end gap-3">
				<label class="form-field"><span class="form-label">Dividir después del verso</span>
					<input aria-label={'Dividir después del verso · secuencia ' + (i + 1)} inputmode="numeric" bind:value={parte.corte} class="w-36 rounded-md border border-[color:var(--border)] px-3 py-2" /></label>
				<button type="button" aria-label={'Dividir secuencia ' + (i + 1)} disabled={!parte.corte.trim() || Number(parte.fin) <= principio(i)} class="rounded-md border border-[color:var(--border)] px-3 py-2 text-sm disabled:opacity-50" onclick={() => dividir(i)}>Dividir</button>
				{#if i < partes.length - 1}<button type="button" aria-label={'Unir secuencia ' + (i + 1) + ' con la siguiente'} class="rounded-md border border-[color:var(--border)] px-3 py-2 text-sm" onclick={() => unir(i)}>Unir con la siguiente</button>{/if}
			</div>
		</fieldset>
	{/each}
	{#if tieneRemate}<label class="flex items-center gap-2 text-sm"><input type="checkbox" bind:checked={conservarRemate} disabled={ocupado} /> Conservar el remate al final de la última secuencia</label>{/if}
	<div class="flex flex-wrap gap-3">
		<button type="button" class="rounded-md bg-[color:var(--foreground)] px-4 py-2 text-sm text-white disabled:opacity-50" disabled={ocupado} onclick={aplicar}>{ocupado ? 'Comprobando…' : 'Comprobar secuencias'}</button>
		<button type="button" class="rounded-md border border-[color:var(--border)] px-4 py-2 text-sm" disabled={ocupado} onclick={onrestablecer}>Restablecer fila</button>
	</div>
</section>
