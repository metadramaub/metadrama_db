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
		FormaDemarcable,
		FormaPuntuada,
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
	let busquedaForma = $state('');
	let mostrarSugerencias = $state(false);
	let mostrarMasResultados = $state(false);

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
	const respuestasConcluyentes = $derived(
		respuestas.filter((respuesta) => respuesta.valor !== 'desconocido').length
	);
	const resultadoSuficiente = $derived(
		respuestasConcluyentes >= 3 &&
		(formasOrdenadas[0]?.arquitecturas[0]?.coincidencias ?? 0) >= 2 &&
		diferenciaPrincipal >= 0.75
	);
	const recorridoDetenido = $derived(
		Boolean(modo && (resultadoSuficiente || !pregunta) && !afinamientoSolicitado)
	);
	const resultadosVisibles = $derived(
		respuestas.length > 0
			? formasOrdenadas.slice(0, mostrarMasResultados ? 8 : 3)
			: []
	);
	const comparacionPrincipal = $derived(explicarComparacion(formasOrdenadas));
	const formasSugeridas = $derived(
		data.catalogo.formas
			.filter((forma: FormaDemarcable) =>
				normalizarBusqueda(forma.nombre).includes(normalizarBusqueda(busquedaForma))
			)
			.slice(0, 8)
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
		mostrarMasResultados = false;
	}

	function responder(
		preguntaActual: PreguntaDemarcador,
		valor: string | number | 'desconocido',
		etiqueta: string
	) {
		respuestas = [...respuestas, crearRespuesta(preguntaActual, valor, etiqueta)];
		afinamientoSolicitado = false;
		numeroRespuesta = '';
		mostrarMasResultados = false;
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

	function editarRespuesta(indice: number) {
		respuestas = respuestas.slice(0, indice);
		afinamientoSolicitado = false;
		numeroRespuesta = '';
		mostrarMasResultados = false;
	}

	function normalizarBusqueda(texto: string): string {
		return texto
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.toLocaleLowerCase('es')
			.trim();
	}

	function seleccionarForma(formaId: string) {
		const forma = data.catalogo.formas.find((item: FormaDemarcable) => item.id === formaId);
		if (!forma) return;
		formaPendienteId = forma.id;
		busquedaForma = forma.nombre;
		mostrarSugerencias = false;
	}

	function explicarComparacion(formas: FormaPuntuada[]): string | null {
		if (respuestas.length === 0 || formas.length < 2) return null;
		const primera = formas[0];
		const segunda = formas[1];
		const diferencia = primera.puntuacion - segunda.puntuacion;
		if (diferencia < 0.75) {
			return `${primera.formaNombre} y ${segunda.formaNombre} siguen muy próximas: las respuestas todavía no permiten distinguirlas con claridad.`;
		}
		const detallesSegunda = new Map(
			segunda.arquitecturas[0].detalles.map((detalle) => [detalle.dimension, detalle.estado])
		);
		const razones = primera.arquitecturas[0].detalles
			.filter(
				(detalle) =>
					detalle.estado === 'coincide' && detallesSegunda.get(detalle.dimension) !== 'coincide'
			)
			.slice(0, 2)
			.map((detalle) => detalle.etiqueta.toLocaleLowerCase('es'));
		return razones.length > 0
			? `${primera.formaNombre} queda por delante de ${segunda.formaNombre} por ${razones.join(' y ')}.`
			: `${primera.formaNombre} queda por delante, aunque todavía no hay una sola respuesta que la separe por sí misma de ${segunda.formaNombre}.`;
	}

	function reiniciar() {
		modo = null;
		formaObjetivoId = null;
		formaPendienteId = '';
		busquedaForma = '';
		mostrarSugerencias = false;
		respuestas = [];
		afinamientoSolicitado = false;
		numeroRespuesta = '';
		mostrarMasResultados = false;
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
		El demarcador ayuda a identificar la forma métrica de un pasaje a partir de rasgos que
		pueden observarse en el texto, como su extensión, su medida, su rima o la organización de
		sus partes.
	</p>
	<p>
		Con esas respuestas consulta el catálogo métrico, ordena las formas y arquitecturas que
		mejor encajan y explica las coincidencias y diferencias; puedes dejar que las preguntas
		guíen el análisis o comenzar desde una forma concreta que quieras comprobar.
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
		category="Recursos"
		title="Demarcador métrico"
		description={descripcionDemarcador}
		onHelp={() => (ayudaAbierta = true)}
	/>

	{#if !modo}
		<div class="grid gap-5 lg:grid-cols-2">
			<section class="flex flex-col border border-[color:var(--border)] bg-white p-6 shadow-sm">
				<div class="flex items-start justify-between gap-4">
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Sin una forma en mente
					</p>
					<span class="font-display text-xl text-[color:var(--gray-300)]" aria-hidden="true">01</span>
				</div>
				<h2 class="font-display mt-5 text-2xl">Identificar desde el pasaje</h2>
				<p class="mt-3 flex-1 text-sm leading-6 text-[color:var(--gray-700)]">
					Responde a preguntas breves sobre la extensión, la medida, la rima y la organización
					del fragmento. Puedes elegir «No sé» cuando un rasgo no esté claro.
				</p>
				<button
					type="button"
					class="mt-7 bg-[color:var(--foreground)] px-4 py-3 text-sm font-semibold text-[color:var(--background)] transition-colors hover:bg-[color:var(--gray-700)]"
					onclick={() => comenzar('guiado')}
				>
					Comenzar recorrido guiado
				</button>
			</section>

			<section class="flex flex-col border border-[color:var(--border)] bg-white p-6 shadow-sm">
				<div class="flex items-start justify-between gap-4">
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Con una forma en mente
					</p>
					<span class="font-display text-xl text-[color:var(--gray-300)]" aria-hidden="true">02</span>
				</div>
				<h2 class="font-display mt-5 text-2xl">Comprobar una hipótesis</h2>
				<p class="mt-3 text-sm leading-6 text-[color:var(--gray-700)]">
					Elige la forma que estás considerando. Las preguntas se centrarán en los rasgos que
					la distinguen, pero el resultado seguirá mostrando otras formas compatibles.
				</p>
				<label class="mt-5 text-sm font-medium" for="forma-objetivo">Forma propuesta</label>
				<div class="relative mt-2">
					<input
						id="forma-objetivo"
						type="search"
						autocomplete="off"
						placeholder="Escribe el nombre de una forma"
						class="w-full border border-[color:var(--border)] bg-white px-3 py-3 text-sm"
						bind:value={busquedaForma}
						role="combobox"
						aria-autocomplete="list"
						onfocus={() => (mostrarSugerencias = true)}
						oninput={() => {
							formaPendienteId = '';
							mostrarSugerencias = true;
						}}
						aria-controls="formas-sugeridas"
						aria-expanded={mostrarSugerencias}
					/>
					{#if mostrarSugerencias}
						<div
							id="formas-sugeridas"
							class="absolute inset-x-0 top-full z-20 max-h-64 overflow-y-auto border-x border-b border-[color:var(--border)] bg-white shadow-lg"
						>
							{#each formasSugeridas as forma}
								<button
									type="button"
									class="block w-full border-t border-[color:var(--border)] px-3 py-2.5 text-left text-sm first:border-t-0 hover:bg-[color:var(--gray-50)]"
									onclick={() => seleccionarForma(forma.id)}
								>
									{forma.nombre}
								</button>
							{:else}
								<p class="px-3 py-3 text-sm text-[color:var(--muted-foreground)]">No se encontró ninguna forma.</p>
							{/each}
						</div>
					{/if}
				</div>
				<button
					type="button"
					class="mt-3 border border-[color:var(--foreground)] px-4 py-3 text-sm font-semibold transition-colors hover:bg-[color:var(--gray-50)] disabled:cursor-not-allowed disabled:opacity-40"
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

		{#if respuestas.length > 0}
			<section class="border-y border-[color:var(--border)] py-3">
				<div class="flex flex-wrap items-center gap-2">
					<p class="mr-1 text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Tus respuestas
					</p>
					{#each respuestas as respuesta, indice}
						<button
							type="button"
							class="border border-[color:var(--border)] bg-white px-2.5 py-1.5 text-left text-xs transition-colors hover:border-[color:var(--foreground)]"
							title={`Cambiar la respuesta ${indice + 1}: ${respuesta.pregunta}`}
							onclick={() => editarRespuesta(indice)}
						>
							<span class="text-[color:var(--muted-foreground)]">{indice + 1}.</span>
							{respuesta.etiqueta}
							<span aria-hidden="true"> ×</span>
						</button>
					{/each}
				</div>
				<p class="mt-2 text-xs leading-5 text-[color:var(--muted-foreground)]">
					Selecciona una respuesta para retomar el recorrido desde ese punto.
				</p>
			</section>
		{/if}

		<div class="grid gap-6 lg:grid-cols-[minmax(0,0.92fr)_minmax(0,1.35fr)]">
			<div class="grid content-start gap-4 lg:sticky lg:top-5 lg:self-start">
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
							Orientación alcanzada
						</p>
						<h2 class="font-display mt-3 text-xl">
							{resultadoSuficiente
								? 'Las candidatas principales ya se distinguen'
								: 'No quedan preguntas que aporten una diferencia clara'}
						</h2>
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							El recorrido se detiene antes de pedir precisiones difíciles que aportarían poca información.
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
							Borrar respuestas
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
						{respuestas.length === 0
							? 'Todavía sin resultados'
							: resultadoSuficiente
								? 'Formas con mejor encaje'
								: 'Candidatas según tus respuestas'}
					</h2>
					<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
						Al principio se muestran candidatas, no conclusiones. Los grados de encaje aparecen cuando hay evidencias suficientes para compararlas.
					</p>
					{#if comparacionPrincipal}
						<p class="mt-3 border-l-2 border-[color:var(--foreground)] pl-3 text-sm leading-6">
							{comparacionPrincipal}
						</p>
					{/if}
				</div>

				{#if resultadosVisibles.length > 0}
					<ol class="divide-y divide-[color:var(--border)]">
						{#each resultadosVisibles as forma, index}
							<DemarcadorResultCard {forma} {index} />
						{/each}
					</ol>
					{#if formasOrdenadas.length > 3}
						<button
							type="button"
							class="w-full border-t border-[color:var(--border)] px-5 py-3 text-sm font-semibold hover:bg-[color:var(--gray-50)]"
							onclick={() => (mostrarMasResultados = !mostrarMasResultados)}
						>
							{mostrarMasResultados ? 'Mostrar solo las tres primeras' : 'Mostrar más candidatas'}
						</button>
					{/if}
				{:else}
					<p class="p-5 text-sm leading-6 text-[color:var(--muted-foreground)]">
						La orientación aparecerá después de la primera respuesta. Ninguna respuesta descarta por sí sola una forma.
					</p>
				{/if}
			</section>
		</div>
	{/if}

	<footer class="border-t border-[color:var(--border)] pt-4 text-xs leading-5 text-[color:var(--muted-foreground)]">
		Las propuestas indican qué formas encajan mejor con los rasgos introducidos y explican
		por qué. Sirven para orientar la identificación de una composición, pero no garantizan por
		sí solas un resultado correcto.
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
				<li>Las respuestas quedan visibles durante el recorrido; selecciona una para cambiarla y recalcular desde ese punto.</li>
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
			<p class="mt-1">Con pocas respuestas se muestran «Candidatas», porque una coincidencia general todavía dice poco. Los grados de encaje aparecen cuando se reúnen más evidencias y tienen en cuenta la distancia respecto de las demás formas. Una variante, una excepción o un fragmento incompleto pueden cambiar la lectura.</p>
		</section>
	</div>
</PublicHelpDialog>
