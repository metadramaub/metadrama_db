<script lang="ts">
	import { tick } from 'svelte';
	import { rasgosAdmitidos, metrosImportador } from '$lib/importador-metrico/catalogo';
	import type { DesviacionBorrador } from '$lib/importador-metrico/edicion';
	import { metricDeviationRelations, defaultRelationFor } from '$lib/components/metrica/editor-v2/sequence-draft';
	import Button from '$lib/components/ui/button.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	let { forma, arquitectura, rasgos = $bindable(), desviaciones = $bindable(), notas, inicio, fin, modo = 'registrados', prefijo } = $props<{
		forma: string; arquitectura: string; rasgos: {rasgo_slug: string; valor_slug: string}[];
		desviaciones: DesviacionBorrador[]; notas: {id: string; texto_literal: string}[]; inicio: number; fin: number;
		modo?: 'registrados' | 'anadir'; prefijo: string;
	}>();
	type Rasgo = {rasgo_slug: string; valor_slug: string};
	const admitidos = $derived(rasgosAdmitidos(forma, arquitectura));
	const visibles = $derived(admitidos.filter((r) => rasgos.some((dato: Rasgo) => dato.rasgo_slug === r.slug)));
	function elegir(slug: string, valor: string) {
		rasgos = [...rasgos.filter((r: Rasgo) => r.rasgo_slug !== slug), ...(valor ? [{rasgo_slug: slug, valor_slug: valor}] : [])];
	}
	async function anadirRasgo(slug: string) {
		if (!slug) return;
		rasgos = [...rasgos, {rasgo_slug: slug, valor_slug: ''}];
		await tick(); document.getElementById(prefijo + '-' + slug)?.focus();
	}
	async function anadirDesviacion() {
		desviaciones = [...desviaciones, {v_ini: '', v_fin: '', dimension: '', relacion_norma: '', nota_ref: notas.length === 1 ? notas[0].id : '', nota: null}];
		await tick(); document.getElementById(prefijo + '-desviacion-' + (desviaciones.length - 1))?.focus();
	}
</script>

<div class="space-y-4">
	{#if modo === 'registrados'}
	{#if visibles.length}
		<div class="grid gap-3 sm:grid-cols-2">
			{#each visibles as rasgo}
				<div class="form-field"><div class="flex items-baseline justify-between gap-3"><label for={prefijo + '-' + rasgo.slug} class="form-label">{rasgo.nombre}</label><button type="button" class="link-action link-action--danger text-xs" onclick={() => elegir(rasgo.slug, '')}>Quitar</button></div>
					<select id={prefijo + '-' + rasgo.slug} aria-label={rasgo.nombre} value={rasgos.find((r: Rasgo) => r.rasgo_slug === rasgo.slug)?.valor_slug ?? ''} onchange={(e) => elegir(rasgo.slug, e.currentTarget.value)} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm">
						<option value="">Sin especificar</option>{#each rasgo.valores as valor}<option value={valor.slug}>{valor.nombre}</option>{/each}
					</select>
				</div>
			{/each}
		</div>
	{/if}
	{#each rasgos.filter((r: Rasgo) => r.valor_slug && !admitidos.some((a) => a.slug === r.rasgo_slug && a.valores.some((v) => v.slug === r.valor_slug))) as rasgo}
		<div role="alert" class="text-sm text-[color:var(--danger)]">El rasgo {rasgo.rasgo_slug.replaceAll('_', ' ')} no corresponde a la forma y arquitectura elegidas. <button type="button" class="link-action link-action--danger" onclick={() => elegir(rasgo.rasgo_slug, '')}>Quitar</button></div>
	{/each}
	{#each desviaciones as d, n}
		<div class="space-y-3 border-t border-[color:var(--border)] pt-3">
			<div class="flex items-center justify-between"><span class="text-xs uppercase tracking-wide">Desviación {n + 1}</span><button type="button" class="link-action link-action--danger text-xs" onclick={() => desviaciones = desviaciones.filter((_: DesviacionBorrador, i: number) => i !== n)}>Quitar</button></div>
			<label class="form-field"><span class="form-label">Nota de la edición</span><select aria-label={'Nota de la edición · desviación ' + (n + 1)} bind:value={d.nota_ref} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"><option value="">Elegir nota</option>{#each notas as nota}<option value={nota.id}>{nota.texto_literal}</option>{/each}</select></label>
			<div class="grid gap-3 sm:grid-cols-2">
				<label class="form-field"><span class="form-label">Dimensión</span><select id={prefijo + '-desviacion-' + n} aria-label={'Dimensión · desviación ' + (n + 1)} value={d.dimension} onchange={(e) => { d.dimension = e.currentTarget.value as DesviacionBorrador['dimension']; d.relacion_norma = defaultRelationFor(d.dimension, d.relacion_norma); if (d.dimension === 'estructura' && ['menor_que_norma', 'mayor_que_norma'].includes(d.relacion_norma)) d.relacion_norma = ''; delete d.metro_observado_slug; }} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"><option value="">De qué…</option><option value="metro">Metro</option><option value="estructura">Estructura</option></select></label>
				<label class="form-field"><span class="form-label">Relación con la norma</span><select aria-label={'Relación · desviación ' + (n + 1)} bind:value={d.relacion_norma} disabled={!d.dimension} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"><option value="">Elegir</option>{#each metricDeviationRelations(d.dimension).filter((r) => d.dimension !== 'estructura' || !['menor_que_norma', 'mayor_que_norma'].includes(r.value)) as r}<option value={r.value}>{r.label}</option>{/each}</select></label>
				<label class="form-field"><span class="form-label">Verso inicial</span><input aria-label={'Verso inicial · desviación ' + (n + 1)} inputmode="numeric" bind:value={d.v_ini} class="h-10 w-full border border-[color:var(--border)] px-2 text-sm" /></label>
				<label class="form-field"><span class="form-label">Verso final</span><input aria-label={'Verso final · desviación ' + (n + 1)} inputmode="numeric" bind:value={d.v_fin} class="h-10 w-full border border-[color:var(--border)] px-2 text-sm" /></label>
				{#if d.dimension === 'metro'}<label class="form-field"><span class="form-label">Metro observado <span class="font-normal">(opcional)</span></span><select aria-label={'Metro observado · desviación ' + (n + 1)} bind:value={d.metro_observado_slug} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"><option value="">Sin especificar</option>{#each metrosImportador as m}<option value={m.slug}>{m.nombre}</option>{/each}</select></label>{/if}
			</div>
			{#if d.relacion_norma === 'otra'}<label class="form-field"><span class="form-label">Descripción</span><textarea bind:value={d.nota} rows="2" maxlength="4000" class="w-full border border-[color:var(--border)] px-2 py-2 text-sm"></textarea></label>{/if}
			<p class="text-xs text-[color:var(--muted-foreground)]">Dentro de vv. {inicio}–{fin}.</p>
		</div>
	{/each}
	{:else}
	{#if admitidos.some((r) => !visibles.some((v) => v.slug === r.slug))}
		<label class="form-field"><span class="form-label">Añadir rasgo <span class="font-normal">(opcional)</span></span>
			<select aria-label="Añadir rasgo" value="" onchange={(e) => { anadirRasgo(e.currentTarget.value); e.currentTarget.value = ''; }} class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm">
				<option value="">Elegir dato del catálogo</option>{#each admitidos.filter((r) => !visibles.some((v) => v.slug === r.slug)) as rasgo}<option value={rasgo.slug}>{rasgo.nombre}</option>{/each}
			</select>
		</label>
	{/if}
	<div class="flex items-center gap-2"><Button variant="secondary" disabled={!notas.length} onclick={anadirDesviacion}>Registrar desviación</Button>
		<FieldHelpTooltip label="Desviaciones de la edición" text="Registra la desviación que aclara una nota de la edición. Los versos añadidos se descuentan al comprobar la estructura; las lagunas ya numeradas no se cuentan dos veces. Si falta la nota, añádela primero al JSON de la extracción." />
	</div>
	{/if}
</div>
