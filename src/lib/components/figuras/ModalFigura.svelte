<script lang="ts">
	// El modal de descarga de un gráfico.
	//
	// **Es un modal y no un botón que descarga** porque descargar pide decidir cosas —formato,
	// color o blanco y negro— y porque es el momento de decir cómo se cita y qué permite la
	// licencia, que es lo que se quiere que lea quien se lleva la figura. Las opciones son un
	// objeto (`OpcionesFigura`): lo que se añada mañana entra aquí sin tocar los gráficos.
	//
	// **La vista previa es el archivo.** Se compone la figura, se enseña como imagen, y de esa misma
	// composición sale el SVG y se rasteriza el PNG. No hay una figura para mirar y otra que baja.
	import { tick, type Snippet } from 'svelte';
	import { Copy, Download, LoaderCircle, X } from 'lucide-svelte';
	import { creditoDeFigura, VERSOLOGIA } from '$lib/figuras/cita';
	import { copiarAlPortapapeles } from '$lib/utils/portapapeles';
	import type { FiguraCompuesta } from '$lib/figuras/componer';
	import {
		blobPng,
		blobSvg,
		descargar,
		nombreDeArchivo,
		prepararFigura
	} from '$lib/figuras/exportar';
	import type {
		FiguraDescargable,
		OpcionesFigura,
		Paleta,
		ProcedenciaFigura
	} from '$lib/figuras/tipos';

	const props = $props<{
		figura: FiguraDescargable;
		procedencia: ProcedenciaFigura;
		grafico: Snippet<[OpcionesFigura]>;
		onClose: () => void;
	}>();

	const idTitulo = `modal-figura-${Math.random().toString(36).slice(2, 8)}`;
	/** Una sola fecha de consulta por apertura: la del pie, la de la cita y la de los metadatos. */
	const consulta = new Date();

	let paleta = $state<Paleta>('color');
	const opciones = $derived<OpcionesFigura>({ paleta });
	const credito = $derived(creditoDeFigura(props.figura, props.procedencia, opciones, consulta));

	let dialogo = $state<HTMLDivElement | null>(null);
	let lienzo = $state<HTMLDivElement | null>(null);
	let compuesta = $state<FiguraCompuesta | null>(null);
	let vistaPrevia = $state<string | null>(null);
	let preparando = $state(true);
	let descargando = $state<'png' | 'svg' | null>(null);
	let error = $state('');

	$effect(() => {
		const previo = document.activeElement instanceof HTMLElement ? document.activeElement : null;
		const desbordamiento = document.body.style.overflow;
		document.body.style.overflow = 'hidden';
		requestAnimationFrame(() => dialogo?.focus());
		const alPulsar = (evento: KeyboardEvent) => {
			if (evento.key === 'Escape') {
				evento.preventDefault();
				props.onClose();
			}
		};
		document.addEventListener('keydown', alPulsar);
		return () => {
			document.removeEventListener('keydown', alPulsar);
			document.body.style.overflow = desbordamiento;
			previo?.focus();
		};
	});

	// Se recompone cada vez que cambia una opción: el gráfico de fuera de la pantalla se vuelve a
	// pintar con ella, se espera a que Svelte lo haya hecho y se lee.
	$effect(() => {
		const actuales = opciones;
		const creditoActual = credito;
		const contenedor = lienzo;
		if (!contenedor) return;
		let cancelado = false;
		preparando = true;
		error = '';
		tick()
			.then(() =>
				prepararFigura({
					contenedor,
					credito: creditoActual,
					leyenda: props.figura.leyenda?.(actuales)
				})
			)
			.then((figura) => {
				if (cancelado) return;
				compuesta = figura;
				if (vistaPrevia) URL.revokeObjectURL(vistaPrevia);
				vistaPrevia = URL.createObjectURL(blobSvg(figura));
			})
			.catch((causa) => {
				if (cancelado) return;
				error = causa instanceof Error ? causa.message : 'No se pudo preparar la figura.';
			})
			.finally(() => {
				if (!cancelado) preparando = false;
			});
		return () => {
			cancelado = true;
		};
	});

	$effect(() => () => {
		if (vistaPrevia) URL.revokeObjectURL(vistaPrevia);
	});

	const nombre = (extension: string) =>
		`${nombreDeArchivo([
			props.procedencia.obraSlug,
			props.figura.archivo,
			paleta === 'grises' ? 'byn' : ''
		])}.${extension}`;

	async function bajar(formato: 'png' | 'svg') {
		if (!compuesta || descargando) return;
		descargando = formato;
		error = '';
		try {
			const blob = formato === 'png' ? await blobPng(compuesta, credito) : blobSvg(compuesta);
			descargar(blob, nombre(formato));
		} catch (causa) {
			error = causa instanceof Error ? causa.message : 'No se pudo descargar la figura.';
		} finally {
			descargando = null;
		}
	}

	const opcionesDePaleta: { valor: Paleta; etiqueta: string }[] = [
		{ valor: 'color', etiqueta: 'Color' },
		{ valor: 'grises', etiqueta: 'Blanco y negro' }
	];
</script>

<!-- El gráfico que se exporta, pintado fuera de la vista. `inert` para que el tabulador no
     entre en él. -->
<div class="modal-figura__lienzo" aria-hidden="true" inert bind:this={lienzo}>
	{@render props.grafico(opciones)}
</div>

<div
	class="fixed inset-0 z-[120] flex items-start justify-center overflow-y-auto bg-black/40 p-4 md:items-center"
	role="presentation"
	onclick={(evento) => {
		if (evento.target === evento.currentTarget) props.onClose();
	}}
>
	<div
		bind:this={dialogo}
		class="w-full max-w-5xl border border-[color:var(--border)] bg-white shadow-lg outline-none"
		role="dialog"
		aria-modal="true"
		aria-labelledby={idTitulo}
		tabindex="-1"
	>
		<header class="flex items-start justify-between gap-4 border-b border-[color:var(--border)] px-5 py-4">
			<div class="min-w-0">
				<p class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">DESCARGAR EL GRÁFICO</p>
				<h2 id={idTitulo} class="mt-1 text-lg font-semibold">{props.figura.titulo}</h2>
			</div>
			<button
				type="button"
				class="inline-flex h-8 w-8 shrink-0 items-center justify-center border border-[color:var(--border)] hover:bg-[color:var(--muted)]"
				aria-label="Cerrar"
				onclick={props.onClose}
			>
				<X class="h-4 w-4" aria-hidden="true" />
			</button>
		</header>

		<div class="grid gap-6 p-5 lg:grid-cols-[minmax(0,1fr)_18rem]">
			<figure class="m-0">
				<div
					class="flex min-h-[16rem] items-center justify-center border border-[color:var(--border)] bg-[color:var(--gray-100)] p-3"
				>
					{#if vistaPrevia}
						<img
							src={vistaPrevia}
							alt={`Vista previa: ${props.figura.titulo}`}
							class="block max-h-[60vh] w-auto max-w-full bg-white shadow-sm"
							class:opacity-60={preparando}
						/>
					{:else if !error}
						<LoaderCircle class="h-5 w-5 animate-spin text-[color:var(--muted-foreground)]" aria-hidden="true" />
						<span class="sr-only">Preparando la vista previa</span>
					{/if}
				</div>
			</figure>

			<div class="space-y-6">
				<fieldset>
					<legend class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Color
					</legend>
					<div class="mt-2 grid grid-cols-2">
						{#each opcionesDePaleta as opcion (opcion.valor)}
							{@const desactivada = opcion.valor === 'grises' && !props.figura.admiteGrises}
							<label
								class={`flex cursor-pointer items-center justify-center border px-2 py-1.5 text-xs font-semibold ${
									paleta === opcion.valor
										? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white'
										: 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'
								} ${desactivada ? 'cursor-not-allowed opacity-40' : ''}`}
							>
								<input
									class="sr-only"
									type="radio"
									name={`${idTitulo}-paleta`}
									value={opcion.valor}
									bind:group={paleta}
									disabled={desactivada}
								/>
								{opcion.etiqueta}
							</label>
						{/each}
					</div>
					{#if !props.figura.admiteGrises}
						<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
							Solo en color para distinguir correctamente los datos.
						</p>
					{/if}
				</fieldset>

				<div>
					<p class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Formato
					</p>
					<div class="mt-2 space-y-2">
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-left text-white hover:bg-[color:var(--gray-700)] disabled:opacity-50"
							disabled={!compuesta || preparando || descargando !== null}
							onclick={() => bajar('png')}
						>
							<span>
								<span class="block text-sm font-semibold">PNG</span>
								<span class="block text-xs text-white/75">Alta resolución (300 ppp)</span>
							</span>
							{#if descargando === 'png'}
								<LoaderCircle class="h-4 w-4 animate-spin" aria-hidden="true" />
							{:else}
								<Download class="h-4 w-4" aria-hidden="true" />
							{/if}
						</button>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 border border-[color:var(--gray-800)] bg-white px-3 py-2 text-left text-[color:var(--gray-900)] hover:bg-[color:var(--gray-50)] disabled:opacity-50"
							disabled={!compuesta || preparando || descargando !== null}
							onclick={() => bajar('svg')}
						>
							<span>
								<span class="block text-sm font-semibold">SVG</span>
								<span class="block text-xs text-[color:var(--muted-foreground)]">Vectorial</span>
							</span>
							{#if descargando === 'svg'}
								<LoaderCircle class="h-4 w-4 animate-spin" aria-hidden="true" />
							{:else}
								<Download class="h-4 w-4" aria-hidden="true" />
							{/if}
						</button>
					</div>
				</div>

				{#if error}
					<p class="text-xs text-[color:var(--danger)]" role="alert">{error}</p>
				{/if}
			</div>
		</div>

		<div class="grid gap-6 border-t border-[color:var(--border)] p-5 md:grid-cols-2">
			<section>
				<h3 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Cómo citarlo
				</h3>
				<p class="mt-2 text-sm leading-6 text-[color:var(--gray-800)]">
					{#each credito.pie[0].slice(1) as tramo, indice (indice)}
						{#if tramo.cursiva}<em>{tramo.texto}</em>{:else}{tramo.texto}{/if}
					{/each}
				</p>
				<button
					type="button"
					class="mt-3 inline-flex items-center gap-1.5 border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold text-[color:var(--gray-800)] hover:bg-[color:var(--gray-50)]"
					onclick={() => copiarAlPortapapeles(credito.cita)}
				>
					<Copy class="h-3.5 w-3.5" aria-hidden="true" /> Copiar la cita
				</button>
			</section>

			<!-- **El uso académico se permite expresamente**, por encima de la licencia: CC no tiene
			     excepción académica, y un artículo en una revista de editorial comercial queda en terreno
			     gris con NC. Lo comercial de verdad —un libro de venta— pide permiso firmado. -->
			<section class="text-sm leading-6 text-[color:var(--gray-800)]">
				<h3 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Uso
				</h3>
				<p class="mt-2">
					Puedes usarlo con fines académicos, citando la fuente. Para un uso comercial,
					<a
						class="font-semibold text-[color:var(--primary)] underline decoration-1 underline-offset-2"
						href="/contacto">escríbenos</a
					>.
				</p>
				<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
					Licencia
					<a
						class="font-semibold text-[color:var(--primary)] underline decoration-1 underline-offset-2"
						href={VERSOLOGIA.licenciaUrl}
						target="_blank"
						rel="noreferrer noopener">{VERSOLOGIA.licencia}</a
					>
				</p>
			</section>
		</div>
	</div>
</div>

<style>
	/* Fuera de la vista pero pintado: `display: none` no calcularía nada que leer. */
	.modal-figura__lienzo {
		position: fixed;
		top: 0;
		left: -20000px;
		width: 1200px;
		pointer-events: none;
	}
</style>
