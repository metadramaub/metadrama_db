<script lang="ts">
	import { onMount, tick, untrack } from 'svelte';
	import type { FichaMinima, SegmentoMinimo } from '$lib/importador-metrico/types';
	import { desviacionEditableSchema, type DesviacionBorrador, type EdicionFila, type FormaEditable } from '$lib/importador-metrico/edicion';
	import DatosSecuencia from './DatosSecuencia.svelte';
	import { proponerDivision, resumenCuerpo } from '$lib/importador-metrico/division';
	import type { MetricDeviationRange } from '$lib/metrica/structural-additions';
	import MetricSequenceModal from '$lib/components/metrica/editor-v2/MetricSequenceModal.svelte';
	import MetricPanelSection from '$lib/components/metrica/editor-v2/MetricPanelSection.svelte';
	import Button from '$lib/components/ui/button.svelte';
	let { datos, tramoRef, formas, ocupado = false, errores = [], notasFuente = [], onaplicar, onrestablecer, oncancelar } = $props<{
		datos: FichaMinima; tramoRef: string; formas: FormaEditable[]; ocupado?: boolean; errores?: string[];
		notasFuente?: {id: string; texto_literal: string}[];
		onaplicar: (cambio: EdicionFila) => void; onrestablecer: () => void; oncancelar: () => void;
	}>();
	const originales = $derived<SegmentoMinimo[]>(datos.segmentos.filter((s: SegmentoMinimo) => s.origen.tramo_ref === tramoRef));
	const inicio = $derived(originales[0].v_ini);
	const fin = $derived(originales.at(-1)!.v_fin);
	const notas = $derived([...new Map([...notasFuente, ...originales.flatMap((s) => s.desviaciones.map((d) => ({id: String(d.nota_ref), texto_literal: String(d.texto_fuente)})))].map((n) => [n.id, n])).values()]);
	type Parte = { id: number; fin: string; forma: string; arquitectura: string; nota: string; mostrarNota: boolean; remate: string | null; extras: boolean; rasgos: {rasgo_slug: string; valor_slug: string}[]; desviaciones: DesviacionBorrador[] };
	let siguienteId = untrack(() => originales.length);
	let partes = $state<Parte[]>(untrack(() => originales.map((s: SegmentoMinimo, i: number) => ({
		id: i, fin: String(s.v_fin), forma: s.identificacion?.forma_slug ?? '', arquitectura: s.identificacion?.arquitectura_slug ?? '',
		nota: s.nota ?? '', mostrarNota: Boolean(s.nota), remate: s.detalles_fuente.some((d: Record<string, unknown>) => d.tipo_seccion === 'remate') ? String(s.detalles_fuente.find((d: Record<string, unknown>) => d.tipo_seccion === 'remate')!.n_versos) : null,
		rasgos: s.detalles_fuente.filter((d) => d.rasgo_slug).map((d) => ({rasgo_slug: String(d.rasgo_slug), valor_slug: String(d.valor_slug)})),
		desviaciones: s.desviaciones.map((d) => ({v_ini: String(d.v_ini), v_fin: String(d.v_fin), dimension: d.dimension as 'metro' | 'estructura', relacion_norma: d.relacion_norma as DesviacionBorrador['relacion_norma'], nota_ref: String(d.nota_ref), nota: d.nota as string | null, ...(d.metro_observado_slug ? {metro_observado_slug: String(d.metro_observado_slug)} : {})})),
		extras: false
	}))));
	const desviaciones = $derived<MetricDeviationRange[]>(partes.flatMap((p) => p.desviaciones).map((d) => ({
		v_ini: Number(d.v_ini), v_fin: Number(d.v_fin), dimension: String(d.dimension), relacion_norma: String(d.relacion_norma)
	})));
	let mensaje = $state('');
	let sucio = $state(false);
	const contenidoInicial = untrack(() => JSON.stringify(partes));
	$effect(() => { if (JSON.stringify(partes) !== contenidoInicial) sucio = true; });
	let panel = $state<HTMLElement>();
	let dividiendo = $state<number | null>(null);
	let nuevoInicio = $state('');
	onMount(() => panel?.focus());
	const principio = (i: number) => i ? Number(partes[i - 1].fin) + 1 : inicio;
	type Seccion = NonNullable<FormaEditable['secciones']>[number];
	function secciones(p: Parte, tipo: string): Seccion[] {
		return formas.find((f: FormaEditable) => f.slug === p.forma)?.secciones?.filter((s: Seccion) => s.tipo_seccion === tipo && (!p.arquitectura || s.arquitectura === p.arquitectura)) ?? [];
	}
	function propuesta(i: number) {
		try {
			if (partes[i].desviaciones.some((d) => !desviacionEditableSchema.safeParse({...d, v_ini: Number(d.v_ini), v_fin: Number(d.v_fin)}).success)) throw new Error('Completa las desviaciones antes de dividir.');
			if (partes[i].rasgos.some((r) => r.rasgo_slug === 'distico_final') && Number(nuevoInicio) >= Number(partes[i].fin) - 1) throw new Error('El dístico final pertenece a la tirada: conserva sus dos versos dentro de la nueva secuencia.');
			if (partes[i].remate !== null && (!Number.isInteger(Number(partes[i].remate)) || Number(partes[i].remate) < 1)) throw new Error('Revisa la extensión del remate antes de dividir.');
			return { rangos: proponerDivision(principio(i), Number(partes[i].fin), Number(nuevoInicio), desviaciones, Number(partes[i].remate)), error: '' };
		}
		catch (e) { return { rangos: null, error: e instanceof Error ? e.message : 'Revisa el verso de inicio.' }; }
	}
	function problemaRemate(p: Parte): string | null {
		if (p.remate === null) return null;
		const n = Number(p.remate), admitidos = secciones(p, 'remate');
		if (!Number.isInteger(n) || n < 1) return 'Indica cuántos versos tiene el remate.';
		if (!admitidos.length) return 'La forma seleccionada no admite este remate en el catálogo de referencia.';
		if (!admitidos.some((s: Seccion) => (s.versos_min == null || n >= s.versos_min) && (s.versos_max == null || n <= s.versos_max))) {
			const fijos = [...new Set(admitidos.map((s: Seccion) => s.versos_min === s.versos_max ? s.versos_min : null))];
			return fijos.length === 1 && fijos[0] ? `El remate debe tener ${fijos[0]} ${fijos[0] === 1 ? 'verso' : 'versos'} según el catálogo.` : 'La extensión del remate no corresponde a la forma y arquitectura elegidas.';
		}
		return null;
	}
	async function dividir(i: number) {
		const calculo = propuesta(i);
		if (!calculo.rangos) { mensaje = calculo.error; return; }
		const p = partes[i], id = siguienteId++;
		partes.splice(i, 1, { ...p, fin: String(calculo.rangos.anterior.v_fin), remate: null, rasgos: p.rasgos.filter((r) => r.rasgo_slug !== 'distico_final'), desviaciones: p.desviaciones.filter((d) => Number(d.v_fin) < Number(nuevoInicio)) },
			{ ...p, id, forma: '', arquitectura: '', nota: '', mostrarNota: false, rasgos: p.rasgos.map((r) => ({...r})), desviaciones: p.desviaciones.filter((d) => Number(d.v_ini) >= Number(nuevoInicio)), extras: false });
		dividiendo = null; nuevoInicio = ''; mensaje = ''; sucio = true;
		await tick(); document.getElementById('forma-importada-' + id)?.focus();
	}
	function unir(i: number) {
		const p = partes[i], siguiente = partes[i + 1];
		if (p.forma !== siguiente.forma || p.arquitectura !== siguiente.arquitectura) { mensaje = 'Elige la misma forma y arquitectura antes de unir las secuencias.'; return; }
		if (p.remate !== null) { mensaje = 'La primera secuencia tiene un remate. Revísalo antes de unirla con la siguiente.'; return; }
		if (p.rasgos.some((r) => r.rasgo_slug === 'distico_final')) { mensaje = 'Revisa el dístico final de la primera secuencia antes de unirla.'; return; }
		if (p.rasgos.some((r) => siguiente.rasgos.some((s) => r.rasgo_slug === s.rasgo_slug && r.valor_slug !== s.valor_slug))) { mensaje = 'Revisa los rasgos diferentes antes de unir las secuencias.'; return; }
		partes.splice(i, 2, { ...p, fin: siguiente.fin, remate: siguiente.remate,
			rasgos: [...new Map([...p.rasgos, ...siguiente.rasgos].map((r) => [r.rasgo_slug, r])).values()], desviaciones: [...p.desviaciones, ...siguiente.desviaciones],
			nota: [...new Set([p.nota, siguiente.nota].filter(Boolean))].join(' '), mostrarNota: p.mostrarNota || siguiente.mostrarNota, extras: p.extras || siguiente.extras });
		dividiendo = null; mensaje = ''; sucio = true;
	}
	function aplicar() {
		if (dividiendo !== null) { mensaje = 'Termina o cancela la división antes de comprobar.'; return; }
		const problema = partes.map((p: Parte) => problemaRemate(p)).find(Boolean);
		if (problema) { mensaje = problema; return; }
		const desviacionesValidadas = partes.map((p) => p.desviaciones.map((d) => desviacionEditableSchema.safeParse({...d, v_ini: Number(d.v_ini), v_fin: Number(d.v_fin), nota: d.nota?.trim() || null, ...(d.metro_observado_slug === '' ? {metro_observado_slug: undefined} : {})})));
		if (desviacionesValidadas.some((ds) => ds.some((d) => !d.success))) { mensaje = 'Completa la nota de origen, la dimensión, la relación y los versos de cada desviación.'; return; }
		const cambio: EdicionFila = { tramo_ref: tramoRef, partes: partes.map((p: Parte, i: number) => ({
			v_ini: principio(i), v_fin: Number(p.fin), identificacion: p.forma ? { forma_slug: p.forma, arquitectura_slug: p.arquitectura || null } : null,
			nota: p.nota.trim() || null, remate: p.remate !== null ? { n_versos: Number(p.remate) } : null, rasgos: p.rasgos.filter((r) => r.valor_slug),
			desviaciones: desviacionesValidadas[i].map((d) => { if (!d.success) throw new Error('Desviación incompleta'); return d.data; })
		})) };
		if (cambio.partes.some((p) => !Number.isInteger(p.v_fin) || p.v_fin < p.v_ini || (p.remate && (!Number.isInteger(p.remate.n_versos) || p.remate.n_versos < 1 || p.remate.n_versos > p.v_fin - p.v_ini + 1))) || cambio.partes.at(-1)!.v_fin !== fin) {
			mensaje = 'Revisa los límites y la extensión del remate. No se cambia la numeración original.'; return;
		}
		mensaje = ''; onaplicar(cambio);
	}
</script>

<MetricSequenceModal titulo={partes.length === 1 ? 'Editar secuencia' : 'Editar secuencias'} rango={{ v_ini: inicio, v_fin: fin }}
	guardando={ocupado} {sucio} error={[mensaje, ...errores].filter(Boolean).join(' ') || null}
	alCerrar={oncancelar} alGuardar={aplicar} etiquetaGuardar="Comprobar cambios" etiquetaProcesando="Comprobando…">
	<section bind:this={panel} tabindex="-1" aria-label="Editar secuencias" class="space-y-4 p-5 focus:outline-none" oninput={() => sucio = true} onchange={() => sucio = true}>
		<p class="text-sm text-[color:var(--muted-foreground)]">En la edición: {originales[0].origen.denominacion_literal ?? '—'}</p>
		{#each notas.filter((n) => !partes.some((p) => p.desviaciones.some((d) => d.nota_ref === n.id))) as n}
			<p class="text-sm text-[color:var(--muted-foreground)]">{n.texto_literal}</p>
		{/each}
		{#each partes as parte, i (parte.id)}
			{@const unidad = secciones(parte, 'terceto').find((s: Seccion) => s.versos_min && s.versos_min === s.versos_max)?.versos_min}
			<fieldset class="space-y-4 border border-[color:var(--border)] bg-white p-4" disabled={ocupado}>
				<legend class="px-1 text-sm font-medium">{partes.length > 1 ? 'Secuencia ' + (i + 1) + ' · ' : ''}vv. {principio(i)}–{parte.fin} · {Number(parte.fin) - principio(i) + 1} versos</legend>
				<div class="grid gap-4 sm:grid-cols-2">
					<label class="form-field"><span class="form-label">Forma</span><select id={'forma-importada-' + parte.id} aria-label={'Forma · secuencia ' + (i + 1)} value={parte.forma} onchange={(e) => { parte.forma = e.currentTarget.value; parte.arquitectura = ''; }} class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
						<option value="">Forma sin resolver</option>{#each formas as forma}<option value={forma.slug}>{forma.nombre}</option>{/each}
					</select></label>
					<label class="form-field"><span class="form-label">Arquitectura <span class="font-normal">(opcional)</span></span><select aria-label={'Arquitectura · secuencia ' + (i + 1) + ' (opcional)'} bind:value={parte.arquitectura} disabled={!parte.forma} class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 disabled:opacity-50">
						<option value="">Sin especificar</option>{#each formas.find((f: FormaEditable) => f.slug === parte.forma)?.arquitecturas ?? [] as a}<option value={a.slug}>{a.nombre}</option>{/each}
					</select></label>
				</div>
				{#if i < partes.length - 1}<label class="form-field"><span class="form-label">Último verso de esta secuencia</span><input aria-label={'Último verso · secuencia ' + (i + 1)} inputmode="numeric" bind:value={parte.fin} class="w-40 rounded-md border border-[color:var(--border)] px-3 py-2" /></label>{/if}
				{#if parte.remate !== null}
					{@const resumen = resumenCuerpo(principio(i), Number(parte.fin), Number(parte.remate), desviaciones)}
					<div class="space-y-2 border-t border-[color:var(--border)] pt-3">
						<div class="flex flex-wrap items-end gap-3"><label class="form-field"><span class="form-label">Remate final · número de versos</span><input aria-label={'Versos del remate · secuencia ' + (i + 1)} inputmode="numeric" bind:value={parte.remate} class="w-28 rounded-md border border-[color:var(--border)] px-3 py-2" /></label>
						<Button variant="secondary" onclick={() => { parte.remate = null; sucio = true; }}>Quitar dato de remate</Button></div>
						{#if Number.isInteger(Number(parte.remate)) && Number(parte.remate) > 0}<p class="text-sm">Cuerpo: {resumen.cuerpo} versos{unidad ? ' en tercetos' : ''} · Remate: {parte.remate} {Number(parte.remate) === 1 ? 'verso' : 'versos'}{resumen.adicionales ? ' · Versos añadidos: ' + resumen.adicionales : ''} · Total: {resumen.total}</p>{/if}
						{#if parte.remate.trim() && problemaRemate(parte)}<p role="status" class="text-sm text-[color:var(--danger)]">{problemaRemate(parte)}</p>{/if}
					</div>
				{/if}
				{#if unidad && resumenCuerpo(principio(i), Number(parte.fin), Number(parte.remate), desviaciones).cuerpo % unidad !== 0}
					<p role="status" class="border-l-2 border-amber-400 bg-amber-50 p-3 text-sm">El cuerpo no es múltiplo de {unidad}. Revisa el remate, los límites o las desviaciones. La numeración no se modifica.</p>
				{/if}
				<div class="flex flex-wrap gap-2">
					{#if Number(parte.fin) > principio(i) && dividiendo !== parte.id}<Button variant="secondary" onclick={() => { dividiendo = parte.id; nuevoInicio = ''; mensaje = ''; }}>Dividir secuencia</Button>{/if}
					{#if i < partes.length - 1}<Button variant="secondary" onclick={() => unir(i)}>Unir con la siguiente</Button>{/if}
				</div>
				{#if dividiendo === parte.id}
					<div class="space-y-3 border-l-2 border-[color:var(--primary)] bg-[color:var(--muted)] p-4" aria-label="Dividir secuencia">
						<label class="form-field"><span class="form-label">La nueva secuencia empieza en el verso</span><input aria-label="Primer verso de la nueva secuencia" inputmode="numeric" bind:value={nuevoInicio} onkeydown={(e) => { if (e.key === 'Enter') { e.preventDefault(); if (propuesta(i).rangos) dividir(i); } }} class="w-40 rounded-md border border-[color:var(--border)] bg-white px-3 py-2" /></label>
						{#if nuevoInicio.trim()}
							{@const calculo = propuesta(i)}
							{#if calculo.rangos}<p class="text-sm">Primera: vv. {calculo.rangos.anterior.v_ini}–{calculo.rangos.anterior.v_fin} · Nueva: vv. {calculo.rangos.nueva.v_ini}–{calculo.rangos.nueva.v_fin}</p>
							{:else}<p role="alert" class="text-sm text-[color:var(--danger)]">{calculo.error}</p>{/if}
						{/if}
						<div class="flex gap-2"><Button variant="secondary" disabled={!nuevoInicio.trim() || !propuesta(i).rangos} onclick={() => dividir(i)}>Crear nueva secuencia</Button><Button variant="secondary" onclick={() => dividiendo = null}>Cancelar división</Button></div>
					</div>
				{/if}
				<DatosSecuencia prefijo={'datos-secuencia-' + parte.id} forma={parte.forma} arquitectura={parte.arquitectura} bind:rasgos={parte.rasgos} bind:desviaciones={parte.desviaciones} {notas} inicio={principio(i)} fin={Number(parte.fin)} />
				{#if parte.mostrarNota}
					<div class="form-field"><div class="flex items-baseline justify-between gap-3"><label for={'nota-secuencia-' + parte.id} class="form-label">Nota <span class="font-normal">(opcional)</span></label><button type="button" class="link-action link-action--danger text-xs" onclick={() => { parte.nota = ''; parte.mostrarNota = false; }}>Quitar</button></div><textarea id={'nota-secuencia-' + parte.id} aria-label={'Nota · secuencia ' + (i + 1) + ' (opcional)'} rows="2" maxlength="4000" bind:value={parte.nota} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"></textarea></div>
				{/if}
				<MetricPanelSection id={'datos-importados-' + parte.id} titulo="Añadir datos" abierta={parte.extras} alAlternar={() => parte.extras = !parte.extras} sinContenedor>
					{#if parte.remate === null && secciones(parte, 'remate').length}<Button variant="secondary" onclick={() => { const s = secciones(parte, 'remate')[0]; parte.remate = s.versos_min && s.versos_min === s.versos_max ? String(s.versos_min) : ''; sucio = true; }}>Añadir remate</Button>{/if}
					<DatosSecuencia modo="anadir" prefijo={'datos-secuencia-' + parte.id} forma={parte.forma} arquitectura={parte.arquitectura} bind:rasgos={parte.rasgos} bind:desviaciones={parte.desviaciones} {notas} inicio={principio(i)} fin={Number(parte.fin)} />
					{#if !parte.mostrarNota}<Button variant="secondary" onclick={async () => { parte.mostrarNota = true; await tick(); document.getElementById('nota-secuencia-' + parte.id)?.focus(); }}>Añadir nota</Button>{/if}
				</MetricPanelSection>
			</fieldset>
		{/each}
		<Button variant="secondary" onclick={onrestablecer} disabled={ocupado}>Restablecer fila</Button>
	</section>
</MetricSequenceModal>
