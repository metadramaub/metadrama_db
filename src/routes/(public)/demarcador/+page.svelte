<script lang="ts">
	import { browser, dev } from '$app/environment';
	import {
		crearRespuestaDemarcador,
		diagnosticarSeleccionPreguntas,
		elegirSiguientePregunta,
		filtrarCandidatas,
		type EstrofaDemarcador,
		type RespuestaDemarcador,
		type ValorRespuestaDemarcador
	} from '$lib/demarcador';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let respuestas = $state<RespuestaDemarcador[]>([]);

	const estrofasDemarcador = $derived(data.estrofas);
	const preguntasDemarcador = $derived(data.preguntas);
	const candidatas = $derived(filtrarCandidatas(estrofasDemarcador, respuestas));
	const preguntaActual = $derived(
		elegirSiguientePregunta(candidatas, preguntasDemarcador, respuestas)
	);
	const tituloResultado = $derived(getTituloResultado(candidatas.length));
	const requiereDecisionEditorial = $derived(!preguntaActual && candidatas.length > 1);

	function responder(valor: ValorRespuestaDemarcador, etiqueta: string) {
		if (!preguntaActual) return;

		respuestas = [...respuestas, crearRespuestaDemarcador(preguntaActual, valor, etiqueta)];
	}

	function reiniciar() {
		respuestas = [];
	}

	function deshacerUltima() {
		respuestas = respuestas.slice(0, -1);
	}

	function getTituloResultado(total: number) {
		if (total === 0) return 'Sin candidatas compatibles';
		if (total === 1) return 'Resultado probable';
		if (total <= 5) return 'Candidatas principales';
		return 'Candidatas compatibles';
	}

	function familiaDe(candidata: EstrofaDemarcador) {
		return candidata.familyLabel ?? candidata.familySlug ?? candidata.parentSlug ?? 'Sin familia indicada';
	}

	function confianzaDe(candidata: EstrofaDemarcador) {
		if (!candidata.confianzaFormalizacion) return null;
		return `Confianza de formalización: ${candidata.confianzaFormalizacion}`;
	}
	$effect(() => {
		if (!dev || !browser) return;
		if (new URLSearchParams(window.location.search).get('debugDemarcador') !== '1') return;

		console.info(
			'[demarcador]',
			diagnosticarSeleccionPreguntas(candidatas, preguntasDemarcador, respuestas)
		);
	});
</script>

<svelte:head>
	<title>Demarcador métrico | MetaDrama</title>
	<meta
		name="description"
		content="Asistente de identificación de formas métricas por descarte."
	/>
</svelte:head>

<section class="grid gap-6">
	<header class="border-b border-[color:var(--border)] pb-6">
		<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
			Recurso editorial
		</p>
		<h1 class="font-display mt-2 text-3xl text-[color:var(--gray-900)] md:text-4xl">
			Demarcador métrico
		</h1>
		<p class="mt-2 max-w-3xl text-base text-[color:var(--gray-700)]">
			Asistente de identificación de formas métricas por descarte
		</p>
		<p class="mt-4 max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			Responde a las preguntas para reducir progresivamente las formas métricas candidatas.
			Puedes responder ‘No sé’ cuando un rasgo no sea claro.
		</p>
	</header>

	<div class="grid gap-4 md:grid-cols-3" aria-live="polite">
		<div class="card p-4">
			<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
				Candidatas actuales
			</p>
			<p class="mt-2 text-3xl font-semibold text-[color:var(--gray-900)]">
				{candidatas.length}
				<span class="text-sm font-normal text-[color:var(--muted-foreground)]">
					/ {estrofasDemarcador.length}
				</span>
			</p>
		</div>

		<div class="card p-4">
			<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
				Preguntas respondidas
			</p>
			<p class="mt-2 text-3xl font-semibold text-[color:var(--gray-900)]">{respuestas.length}</p>
		</div>

		<div class="card flex items-center p-4">
			<button
				type="button"
				class="w-full border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-4 py-3 text-sm font-semibold text-white transition-colors hover:bg-[color:var(--gray-700)] focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
				onclick={reiniciar}
			>
				Reiniciar
			</button>
		</div>
	</div>

	<div class="grid gap-6 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.6fr)]">
		<div class="grid content-start gap-6">
			<section class="card p-5">
				<div class="flex items-start justify-between gap-3">
					<div>
						<h2 class="font-display text-lg text-[color:var(--gray-900)]">Pregunta actual</h2>
					</div>
				</div>

				{#if preguntaActual}
					<p class="mt-5 text-base leading-7 text-[color:var(--gray-900)]">
						{preguntaActual.pregunta}
					</p>
					{#if preguntaActual.ayuda}
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							{preguntaActual.ayuda}
						</p>
					{/if}

					{#if preguntaActual.tipo === 'opcion'}
						<div class="mt-5 grid max-h-80 gap-2 overflow-y-auto pr-1 sm:grid-cols-2">
							{#each preguntaActual.opciones as opcion}
								<button
									type="button"
									class="border border-[color:var(--border)] bg-white px-3 py-2 text-left text-sm text-[color:var(--gray-800)] transition-colors hover:border-[color:var(--primary)] hover:bg-[color:var(--muted)] focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
									onclick={() => responder(opcion, String(opcion))}
								>
									{opcion}
								</button>
							{/each}
						</div>
						{#if preguntaActual.admiteDesconocido}
							<button
								type="button"
								class="mt-3 w-full border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-sm font-semibold text-[color:var(--gray-800)] transition-colors hover:bg-white focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
								onclick={() => responder('desconocido', 'No sé')}
							>
								No sé
							</button>
						{/if}
					{:else}
						<div class="mt-5 grid gap-2 sm:grid-cols-3">
							<button
								type="button"
								class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-3 text-sm font-semibold text-white transition-colors hover:bg-[color:var(--gray-700)] focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
								onclick={() => responder(true, 'Sí')}
							>
								Sí
							</button>
							<button
								type="button"
								class="border border-[color:var(--border)] bg-white px-3 py-3 text-sm font-semibold text-[color:var(--gray-800)] transition-colors hover:border-[color:var(--gray-800)] focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
								onclick={() => responder(false, 'No')}
							>
								No
							</button>
							<button
								type="button"
								class="border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-3 text-sm font-semibold text-[color:var(--gray-800)] transition-colors hover:bg-white focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[color:var(--primary)]"
								onclick={() => responder('desconocido', 'No sé')}
							>
								No sé
							</button>
						</div>
					{/if}
				{:else}
					<p class="mt-5 text-sm leading-6 text-[color:var(--muted-foreground)]">
						No hay una pregunta adicional claramente útil para separar las candidatas actuales.
					</p>
					{#if requiereDecisionEditorial}
						<p class="mt-3 border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-sm font-semibold text-[color:var(--gray-800)]">
							Requiere decisión editorial.
						</p>
					{/if}
				{/if}
			</section>

			<section class="card p-5">
				<div class="flex items-center justify-between gap-3">
					<h2 class="font-display text-lg text-[color:var(--gray-900)]">Historial</h2>
					<button
						type="button"
						class="border border-[color:var(--border)] px-3 py-2 text-xs font-semibold text-[color:var(--gray-800)] transition-colors hover:border-[color:var(--gray-800)] disabled:cursor-not-allowed disabled:opacity-50"
						disabled={respuestas.length === 0}
						onclick={deshacerUltima}
					>
						Deshacer última
					</button>
				</div>

				{#if respuestas.length}
					<ol class="mt-4 grid gap-3">
						{#each respuestas as respuesta, index}
							<li class="border-l-2 border-[color:var(--primary)] pl-3 text-sm">
								<p class="font-semibold text-[color:var(--gray-900)]">
									{index + 1}. {respuesta.etiqueta}
								</p>
								<p class="mt-1 leading-5 text-[color:var(--muted-foreground)]">
									{respuesta.pregunta}
								</p>
							</li>
						{/each}
					</ol>
				{:else}
					<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">
						Todavía no hay respuestas registradas.
					</p>
				{/if}
			</section>
		</div>

		<section class="card overflow-hidden">
			<div class="border-b border-[color:var(--border)] bg-white p-5">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Panel de resultado
				</p>
				<h2 class="font-display mt-2 text-xl text-[color:var(--gray-900)]">{tituloResultado}</h2>
				<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
					La herramienta muestra formas compatibles con las respuestas dadas. La formalización es
					revisable y el resultado no debe leerse como una clasificación cerrada.
				</p>
			</div>

			{#if candidatas.length}
				<ul class="divide-y divide-[color:var(--border)]">
					{#each candidatas as candidata}
						<li class="grid gap-3 p-5">
							<div class="flex flex-wrap items-start justify-between gap-3">
								<div>
									<h3 class="text-base font-semibold text-[color:var(--gray-900)]">
										{candidata.label}
									</h3>
									<p class="mt-1 font-mono text-xs text-[color:var(--muted-foreground)]">
										{candidata.slug}
									</p>
								</div>
								{#if candidata.confianzaFormalizacion}
									<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--gray-700)]">
										{candidata.confianzaFormalizacion}
									</span>
								{/if}
							</div>

							<div class="grid gap-2 text-sm leading-6 text-[color:var(--gray-700)]">
								<p>
									<span class="font-semibold text-[color:var(--gray-900)]">Familia o padre:</span>
									{familiaDe(candidata)}
								</p>
								{#if candidata.definicion}
									<p>{candidata.definicion}</p>
								{/if}
								{#if candidata.patronEspecifico}
									<p>
										<span class="font-semibold text-[color:var(--gray-900)]">Patrón:</span>
										<span class="font-mono">{candidata.patronEspecifico}</span>
									</p>
								{/if}
							</div>

							<div class="flex flex-wrap gap-2 text-xs text-[color:var(--muted-foreground)]">
								{#if confianzaDe(candidata)}
									<span class="border border-[color:var(--border)] px-2 py-1">
										{confianzaDe(candidata)}
									</span>
								{/if}
								{#if candidata.requiereRevision}
									<span class="border border-[color:var(--border)] px-2 py-1">
										Formalización pendiente de revisión
									</span>
								{/if}
							</div>
						</li>
					{/each}
				</ul>
			{:else}
				<div class="p-5">
					<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
						No quedan candidatas compatibles con las respuestas actuales. Revisa el historial o
						deshaz la última respuesta para recuperar alternativas.
					</p>
				</div>
			{/if}
		</section>
	</div>
</section>
