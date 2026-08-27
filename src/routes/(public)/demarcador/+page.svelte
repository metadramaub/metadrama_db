<script lang="ts">
	import {
		crearRespuesta,
		elegirPregunta,
		ordenarFormas
	} from '$lib/demarcador-metrico/motor';
	import DemarcadorResultCard from '$lib/components/demarcador/DemarcadorResultCard.svelte';
	import PublicHelpDialog from '$lib/components/public/PublicHelpDialog.svelte';
	import PublicResourceHeader from '$lib/components/public/PublicResourceHeader.svelte';
	import type {
		CatalogoDemarcador,
		ModoDemarcador,
		PreguntaDemarcador,
		RespuestaDemarcador
	} from '$lib/demarcador-metrico/modelo';

	let { data } = $props<{
		data: { catalogo: CatalogoDemarcador; accesoRestringido: boolean };
	}>();
	let modo = $state<ModoDemarcador | null>(null);
	let formaObjetivoId = $state<string | null>(null);
	let formaPendienteId = $state('');
	let respuestas = $state<RespuestaDemarcador[]>([]);
	let ayudaAbierta = $state(false);
	let afinamientoSolicitado = $state(false);
	let numeroRespuesta = $state('');

	const formasOrdenadas = $derived(ordenarFormas(data.catalogo, respuestas));
	const pregunta = $derived(
		modo
			? elegirPregunta(data.catalogo, respuestas, modo, formaObjetivoId)
			: null
	);
	const diferenciaPrincipal = $derived(
		formasOrdenadas.length > 1
			? formasOrdenadas[0].puntuacion - formasOrdenadas[1].puntuacion
			: Number.POSITIVE_INFINITY
	);
	const resultadoSuficiente = $derived(
		respuestas.filter((respuesta) => respuesta.valor !== 'desconocido').length >= 2 &&
		(formasOrdenadas[0]?.arquitecturas[0]?.coincidencias ?? 0) >= 2 &&
		diferenciaPrincipal >= 0.75
	);
	const recorridoDetenido = $derived(
		Boolean(modo && (resultadoSuficiente || !pregunta) && !afinamientoSolicitado)
	);
	const resultadosVisibles = $derived(
		respuestas.length > 0
			? formasOrdenadas.slice(0, resultadoSuficiente ? 3 : 5)
			: []
	);
	const formaObjetivo = $derived(
		formaObjetivoId
			? formasOrdenadas.find((forma) => forma.formaId === formaObjetivoId) ?? null
			: null
	);

	function comenzar(modoElegido: ModoDemarcador) {
		if (modoElegido === 'hipotesis' && !formaPendienteId) return;
		modo = modoElegido;
		formaObjetivoId = modoElegido === 'hipotesis' ? formaPendienteId : null;
		respuestas = [];
		afinamientoSolicitado = false;
		numeroRespuesta = '';
	}

	function responder(
		preguntaActual: PreguntaDemarcador,
		valor: string | number | 'desconocido',
		etiqueta: string
	) {
		respuestas = [...respuestas, crearRespuesta(preguntaActual, valor, etiqueta)];
		afinamientoSolicitado = false;
		numeroRespuesta = '';
	}

	function responderNumero(preguntaActual: PreguntaDemarcador) {
		const numero = Number(numeroRespuesta);
		if (!Number.isInteger(numero) || numero < 1) return;
		responder(preguntaActual, numero, `${numero} versos`);
	}

	function deshacer() {
		respuestas = respuestas.slice(0, -1);
		afinamientoSolicitado = false;
	}

	function reiniciar() {
		modo = null;
		formaObjetivoId = null;
		formaPendienteId = '';
		respuestas = [];
		afinamientoSolicitado = false;
		numeroRespuesta = '';
	}

</script>

<svelte:head>
	<title>Demarcador métrico | MetaDrama</title>
	<meta
		name="description"
		content="Herramienta para orientar la identificación de formas métricas mediante evidencias observables."
	/>
</svelte:head>

{#snippet descripcionDemarcador()}
	<p>
		Contrasta lo que observas en el texto con las formas y arquitecturas del catálogo métrico.
		Puedes comenzar desde cero o comprobar una identificación que ya tengas en mente.
	</p>
{/snippet}

{#if data.accesoRestringido}
	<section class="mx-auto max-w-3xl py-10">
		<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
			Herramienta en pruebas
		</p>
		<h1 class="font-display mt-2 text-3xl text-[color:var(--gray-900)] md:text-4xl">
			Demarcador métrico
		</h1>
		<p class="mt-5 text-base leading-7 text-[color:var(--gray-700)]">
			Durante esta fase, el catálogo del demarcador solo está disponible para los perfiles que
			administran el dominio métrico.
		</p>
	</section>
{:else}
<section class="grid gap-7">
	<PublicResourceHeader
		category="Herramienta de análisis"
		title="Demarcador métrico"
		description={descripcionDemarcador}
		onHelp={() => (ayudaAbierta = true)}
	/>

	{#if !modo}
		<div class="grid gap-5 lg:grid-cols-2">
			<section class="card flex flex-col p-6">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Recorrido guiado
				</p>
				<h2 class="font-display mt-3 text-2xl">Identificar una forma</h2>
				<p class="mt-3 flex-1 text-sm leading-6 text-[color:var(--gray-700)]">
					Empieza por observaciones accesibles. Las propiedades técnicas se deducen y solo se
					preguntan cuando pueden aportar una diferencia clara.
				</p>
				<button
					type="button"
					class="mt-6 bg-[color:var(--foreground)] px-4 py-3 text-sm font-semibold text-[color:var(--background)]"
					onclick={() => comenzar('guiado')}
				>
					Empezar identificación
				</button>
			</section>

			<section class="card flex flex-col p-6">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Comprobación
				</p>
				<h2 class="font-display mt-3 text-2xl">Tengo una hipótesis</h2>
				<p class="mt-3 text-sm leading-6 text-[color:var(--gray-700)]">
					Selecciona la forma que estás considerando. El demarcador priorizará sus rasgos
					definitorios sin ocultar otras identificaciones posibles.
				</p>
				<label class="mt-5 text-sm font-medium" for="forma-objetivo">Forma que quieres comprobar</label>
				<select
					id="forma-objetivo"
					class="mt-2 w-full border border-[color:var(--border)] bg-white px-3 py-3 text-sm"
					bind:value={formaPendienteId}
				>
					<option value="">Selecciona una forma</option>
					{#each data.catalogo.formas as forma}
						<option value={forma.id}>{forma.nombre}</option>
					{/each}
				</select>
				<button
					type="button"
					class="mt-3 border border-[color:var(--foreground)] px-4 py-3 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-40"
					disabled={!formaPendienteId}
					onclick={() => comenzar('hipotesis')}
				>
					Comprobar hipótesis
				</button>
			</section>
		</div>
	{:else}
		<div class="flex flex-wrap items-center justify-between gap-3 text-sm">
			<div class="flex flex-wrap items-center gap-x-5 gap-y-2">
				<p class="font-semibold">
					{modo === 'guiado' ? 'Identificación guiada' : `Comprobando: ${formaObjetivo?.formaNombre ?? ''}`}
				</p>
				<p class="text-[color:var(--muted-foreground)]">
					{respuestas.length} {respuestas.length === 1 ? 'respuesta' : 'respuestas'}
				</p>
			</div>
			<button type="button" class="text-sm font-medium underline underline-offset-4" onclick={reiniciar}>
				Cambiar recorrido
			</button>
		</div>

		<div class="grid gap-6 lg:grid-cols-[minmax(0,0.92fr)_minmax(0,1.35fr)]">
			<div class="grid content-start gap-4">
				<section class="card p-5 sm:p-6">
					{#if pregunta && !recorridoDetenido}
						<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
							Pregunta {respuestas.length + 1}
						</p>
						<h2 class="font-display mt-4 text-xl leading-7 text-[color:var(--gray-900)]">
							{pregunta.pregunta}
						</h2>
						{#if pregunta.ayuda}
							<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
								{pregunta.ayuda}
							</p>
						{/if}

						{#if pregunta.tipo === 'numero'}
							<form class="mt-5 flex gap-2" onsubmit={(event) => { event.preventDefault(); responderNumero(pregunta); }}>
								<label class="sr-only" for="numero-versos">Número de versos</label>
								<input
									id="numero-versos"
									type="number"
									min="1"
									step="1"
									placeholder="Número de versos"
									class="min-w-0 flex-1 border border-[color:var(--border)] px-3 py-3 text-sm"
									bind:value={numeroRespuesta}
								/>
								<button class="border border-[color:var(--foreground)] px-4 py-3 text-sm font-semibold" type="submit">
									Responder
								</button>
							</form>
						{:else}
							<div class={`mt-5 grid gap-2 ${pregunta.tipo === 'booleano' ? 'grid-cols-2' : ''}`}>
								{#each pregunta.opciones as opcion}
									<button
										type="button"
										class="border border-[color:var(--border)] bg-white px-3 py-3 text-left text-sm font-medium transition-colors hover:border-[color:var(--gray-800)]"
										onclick={() => responder(pregunta, opcion.clave, opcion.etiqueta)}
									>
										{opcion.etiqueta}
									</button>
								{/each}
							</div>
						{/if}
						<button
							type="button"
							class="mt-2 w-full border border-[color:var(--border)] bg-white px-3 py-3 text-sm font-semibold text-[color:var(--muted-foreground)] transition-colors hover:border-[color:var(--gray-800)] hover:text-[color:var(--foreground)]"
							onclick={() => responder(pregunta, 'desconocido', 'No sé')}
						>
							No sé
						</button>
					{:else}
						<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
							Resultado provisional
						</p>
						<h2 class="font-display mt-3 text-xl">Ya hay una orientación suficiente</h2>
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							El motor se detiene antes de pedir precisiones difíciles que aportarían poca información.
						</p>
						{#if pregunta}
							<button
								type="button"
								class="mt-5 border border-[color:var(--border)] px-4 py-2 text-sm font-semibold"
								onclick={() => (afinamientoSolicitado = true)}
							>
								Seguir afinando
							</button>
						{/if}
					{/if}
				</section>

				{#if respuestas.length > 0}
					<div class="grid grid-cols-2 gap-2">
						<button
							type="button"
							class="border border-[color:var(--border)] px-3 py-2 text-sm font-medium"
							onclick={deshacer}
						>
							Deshacer
						</button>
						<button
							type="button"
							class="border border-[color:var(--border)] px-3 py-2 text-sm font-medium"
							onclick={() => comenzar(modo!)}
						>
							Reiniciar
						</button>
					</div>
				{/if}
			</div>

			<section class="card overflow-hidden">
				<div class="border-b border-[color:var(--border)] p-5">
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Orientación
					</p>
					<h2 class="font-display mt-2 text-2xl">
						{respuestas.length === 0 ? 'Todavía sin resultados' : 'Formas más compatibles'}
					</h2>
					<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
						La forma aparece como identidad principal; la arquitectura solo precisa una realización estructural.
					</p>
				</div>

				{#if resultadosVisibles.length > 0}
					<ol class="divide-y divide-[color:var(--border)]">
						{#each resultadosVisibles as forma, index}
							<DemarcadorResultCard {forma} {index} />
						{/each}
					</ol>
				{:else}
					<p class="p-5 text-sm leading-6 text-[color:var(--muted-foreground)]">
						La orientación aparecerá después de la primera respuesta. Ninguna respuesta descarta por sí sola una forma.
					</p>
				{/if}
			</section>
		</div>
	{/if}

	<footer class="border-t border-[color:var(--border)] pt-4 text-xs leading-5 text-[color:var(--muted-foreground)]">
		El resultado expresa compatibilidad con las evidencias declaradas en el catálogo. No sustituye el análisis métrico ni la revisión editorial.
	</footer>
</section>
{/if}

<PublicHelpDialog
	open={ayudaAbierta}
	title="Cómo usar el demarcador"
	onClose={() => (ayudaAbierta = false)}
>
	<div class="space-y-6 text-sm leading-6 text-[color:var(--gray-700)]">
		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Dos maneras de empezar</h3>
			<p class="mt-1"><strong>Identificar una forma</strong> parte de observaciones generales. <strong>Tengo una hipótesis</strong> comprueba una forma concreta sin favorecerla artificialmente en el resultado.</p>
		</section>
		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Responde solo por lo que ves</h3>
			<ul class="mt-1 list-disc space-y-1 pl-5">
				<li>Selecciona el pasaje que quieres identificar; puede contener una o varias unidades.</li>
				<li>No necesitas decidir de antemano dónde termina cada unidad: el demarcador propondrá agrupaciones posibles.</li>
				<li>«No sé» no afirma ni niega y reduce la prioridad de preguntas similares.</li>
				<li>Una coincidencia preferente o admitida orienta, pero no se trata como una regla absoluta.</li>
				<li>El recorrido se detiene si las precisiones restantes son difíciles y aportan poco.</li>
			</ul>
		</section>
		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Conceptos básicos</h3>
			<dl class="mt-2 grid gap-3 sm:grid-cols-[8rem_1fr]">
				<dt class="font-medium text-[color:var(--foreground)]">Metro</dt><dd>Medida métrica de los versos, con sinalefas y ajustes acentuales.</dd>
				<dt class="font-medium text-[color:var(--foreground)]">Pasaje</dt><dd>Fragmento completo seleccionado para el análisis; puede contener una estrofa, una serie, una composición o varias unidades consecutivas.</dd>
				<dt class="font-medium text-[color:var(--foreground)]">Rima</dt><dd>Relación entre las terminaciones; puede ser consonante, asonante o ausente.</dd>
				<dt class="font-medium text-[color:var(--foreground)]">Arquitectura</dt><dd>Una realización estructural admitida dentro de una forma. Nunca sustituye su nombre.</dd>
			</dl>
		</section>
		<section class="border-t border-[color:var(--border)] pt-5">
			<h3 class="font-semibold text-[color:var(--foreground)]">Interpretar la orientación</h3>
			<p class="mt-1">«Muy compatible» significa que coinciden varias evidencias relevantes y hay una diferencia clara respecto de otras formas. Las demás formas no desaparecen: una variante, una excepción o un fragmento incompleto pueden cambiar la lectura.</p>
		</section>
	</div>
</PublicHelpDialog>
