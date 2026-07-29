<script lang="ts">
	import {
		crearRespuestaNueva,
		elegirSiguientePreguntaNueva,
		filtrarCandidatosNuevos
	} from '$lib/demarcador-nuevo/motor';
	import type {
		ArtefactoDemarcadorNuevo,
		CandidatoDemarcadorNuevo,
		FamiliaDemarcadorNuevo,
		PreguntaDemarcadorNueva,
		RespuestaDemarcadorNueva
	} from '$lib/demarcador-nuevo/modelo';

	type PageDataDemarcador = {
		artefacto: ArtefactoDemarcadorNuevo | null;
		version: {
			version_id: string;
			numero: number;
			estado: string;
			catalogo_revision: number | null;
			generado_en: string;
			publicado_en: string | null;
		} | null;
		esVersionSolicitada: boolean;
		catalogoRevisionActual: number | null;
		catalogoDesactualizado: boolean;
	};

	let { data } = $props<{ data: PageDataDemarcador }>();

	let respuestasFamilias = $state<RespuestaDemarcadorNueva[]>([]);
	let preguntasFamilias = $state<PreguntaDemarcadorNueva[]>([]);
	let respuestasVariantes = $state<RespuestaDemarcadorNueva[]>([]);
	let preguntasVariantes = $state<PreguntaDemarcadorNueva[]>([]);

	const familias = $derived(data.artefacto?.familias ?? []);
	const esCatalogoMetrico = $derived(data.artefacto?.origen === 'catalogo_metrico');
	const candidatosFamiliaBase = $derived(
		familias.map((familia: FamiliaDemarcadorNuevo) => familia.raiz)
	);
	const candidatosResiduales = $derived(
		filtrarCandidatosNuevos(
			data.artefacto?.residuales ?? [],
			preguntasFamilias,
			respuestasFamilias
		)
	);
	const candidatosFamilia = $derived(
		filtrarCandidatosNuevos(
			candidatosFamiliaBase,
			preguntasFamilias,
			respuestasFamilias
		)
	);
	const incluirPatronEnFamilias = $derived(
		data.artefacto?.origen === 'catalogo_metrico'
	);
	const familiaUnica = $derived.by(() => {
		if (candidatosFamilia.length !== 1) return null;
		return (
			familias.find(
				(familia: FamiliaDemarcadorNuevo) => familia.id === candidatosFamilia[0].familiaId
			) ?? null
		);
	});
	const afinandoVariantes = $derived(
		Boolean(
			familiaUnica &&
				familiaUnica.politica === 'variantes' &&
				familiaUnica.variantes.length > 0
		)
	);
	const candidatosVarianteBase = $derived(
		afinandoVariantes && familiaUnica ? familiaUnica.variantes : []
	);
	const candidatosVariante = $derived(
		filtrarCandidatosNuevos(
			candidatosVarianteBase,
			preguntasVariantes,
			respuestasVariantes
		)
	);
	const preguntaFamilia = $derived(
		elegirSiguientePreguntaNueva(candidatosFamilia, 'familias', respuestasFamilias, {
			incluirPatronEnFamilias
		})
	);
	const preguntaVariante = $derived(
		afinandoVariantes
			? elegirSiguientePreguntaNueva(
					candidatosVariante,
					'variantes',
					respuestasVariantes
				)
			: null
	);
	const preguntaActual = $derived(afinandoVariantes ? preguntaVariante : preguntaFamilia);
	const etapaActual = $derived(afinandoVariantes ? 'variantes' : 'familias');
	const respuestas = $derived([...respuestasFamilias, ...respuestasVariantes]);
	const candidatasResultado = $derived.by(() => {
		if (candidatosFamilia.length === 0) return candidatosResiduales;
		if (candidatosFamilia.length !== 1 || !familiaUnica) return candidatosFamilia;
		if (afinandoVariantes) return candidatosVariante;
		return [familiaUnica.raiz];
	});

	function responder(valor: string | 'desconocido', etiqueta: string) {
		if (!preguntaActual) return;
		const respuesta = crearRespuestaNueva(preguntaActual, valor, etiqueta);
		if (etapaActual === 'variantes') {
			preguntasVariantes = [...preguntasVariantes, preguntaActual];
			respuestasVariantes = [...respuestasVariantes, respuesta];
			return;
		}
		preguntasFamilias = [...preguntasFamilias, preguntaActual];
		respuestasFamilias = [...respuestasFamilias, respuesta];
		respuestasVariantes = [];
		preguntasVariantes = [];
	}

	function reiniciar() {
		respuestasFamilias = [];
		preguntasFamilias = [];
		respuestasVariantes = [];
		preguntasVariantes = [];
	}

	function deshacer() {
		if (respuestasVariantes.length > 0) {
			respuestasVariantes = respuestasVariantes.slice(0, -1);
			preguntasVariantes = preguntasVariantes.slice(0, -1);
			return;
		}
		if (respuestasFamilias.length > 0) {
			respuestasFamilias = respuestasFamilias.slice(0, -1);
			preguntasFamilias = preguntasFamilias.slice(0, -1);
		}
	}

	function tituloResultado(): string {
		if (candidatasResultado.length === 0) return 'No hay formas compatibles';
		if (candidatasResultado.length === 1) {
			if (esCatalogoMetrico) return 'Forma o configuración probable';
			return afinandoVariantes ? 'Variante probable' : 'Familia probable';
		}
		if (!preguntaActual) return 'Formas todavía compatibles';
		if (esCatalogoMetrico) return 'Formas o configuraciones compatibles';
		return etapaActual === 'variantes' ? 'Variantes compatibles' : 'Familias compatibles';
	}

	function describirMetros(candidato: CandidatoDemarcadorNuevo): string {
		return candidato.rasgos.metros.map((metro) => metro.etiqueta).join(' + ');
	}
</script>

<svelte:head>
	<title>Demarcador métrico | MetaDrama</title>
	<meta
		name="description"
		content="Asistente en pruebas para identificar formas métricas desde el nuevo catálogo estructurado."
	/>
</svelte:head>

{#if !data.artefacto}
	<section class="mx-auto max-w-3xl py-10">
		<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
			Recurso editorial
		</p>
		<h1 class="font-display mt-2 text-3xl text-[color:var(--gray-900)] md:text-4xl">
			Demarcador métrico
		</h1>
		<p class="mt-5 text-base leading-7 text-[color:var(--gray-700)]">
			Todavía no se ha compilado ninguna prueba desde el nuevo catálogo métrico.
		</p>
		<a
			class="mt-6 inline-flex border border-[color:var(--border)] px-4 py-2 text-sm font-semibold"
			href="/dashboard/metrica?tab=validation"
		>
			Ir al catálogo métrico
		</a>
	</section>
{:else}
	<section class="grid gap-6">
		{#if data.catalogoDesactualizado}
			<div class="border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-950">
				Esta prueba se compiló con la revisión {data.version?.catalogo_revision ?? 'desconocida'},
				pero el catálogo ya está en la revisión {data.catalogoRevisionActual}. Genera una prueba
				nueva desde «Modelo y validación».
			</div>
		{:else if data.esVersionSolicitada}
			<div class="border border-sky-300 bg-sky-50 px-4 py-3 text-sm text-sky-950">
				Prueba guardada de la revisión {data.version?.catalogo_revision ?? 'desconocida'} del
				catálogo.
			</div>
		{/if}

		<header class="border-b border-[color:var(--border)] pb-6">
			<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
				Recurso
			</p>
			<h1 class="font-display mt-2 text-3xl text-[color:var(--gray-900)] md:text-4xl">
				Demarcador métrico
			</h1>
			<p class="mt-3 max-w-3xl text-sm leading-6 text-[color:var(--muted-foreground)]">
				{#if esCatalogoMetrico}
					Prueba interna compilada desde el nuevo catálogo. Compara las formas y sus
					configuraciones demarcables sin modificar ningún dato editorial. «No sé» nunca
					descarta candidatas.
				{:else}
					Responde solo a aquello que puedas observar. La herramienta identifica primero una
					familia métrica y, cuando procede, intenta precisar su variante. «No sé» nunca
					descarta formas.
				{/if}
			</p>
		</header>

		<div class="grid gap-3 sm:grid-cols-3" aria-live="polite">
			<div class="card p-4">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Etapa
				</p>
				<p class="mt-2 text-lg font-semibold">
					{esCatalogoMetrico
						? 'Identificar forma'
						: afinandoVariantes
							? 'Precisar variante'
							: 'Identificar familia'}
				</p>
			</div>
			<div class="card p-4">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Candidatas
				</p>
				<p class="mt-2 text-3xl font-semibold">{candidatasResultado.length}</p>
			</div>
			<div class="card p-4">
				<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Respuestas
				</p>
				<p class="mt-2 text-3xl font-semibold">{respuestas.length}</p>
			</div>
		</div>

		<div class="grid gap-6 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.5fr)]">
			<div class="grid content-start gap-5">
				<section class="card p-5">
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						{afinandoVariantes && familiaUnica
							? `Familia identificada: ${familiaUnica.etiqueta}`
							: 'Pregunta actual'}
					</p>

					{#if preguntaActual}
						<h2 class="font-display mt-4 text-xl leading-7 text-[color:var(--gray-900)]">
							{preguntaActual.pregunta}
						</h2>
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							{preguntaActual.ayuda}
						</p>

						{#if preguntaActual.tipo === 'opciones'}
							<div class="mt-5 grid gap-2">
								{#each preguntaActual.opciones as opcion}
									<button
										type="button"
										class="border border-[color:var(--border)] bg-white px-3 py-3 text-left text-sm font-medium transition-colors hover:border-[color:var(--gray-800)]"
										onclick={() => responder(opcion.valor, opcion.etiqueta)}
									>
										{opcion.etiqueta}
									</button>
								{/each}
							</div>
						{:else}
							<div class="mt-5 grid grid-cols-2 gap-2">
								<button
									type="button"
									class="bg-[color:var(--gray-800)] px-3 py-3 text-sm font-semibold text-white"
									onclick={() => responder('si', 'Sí')}
								>
									Sí
								</button>
								<button
									type="button"
									class="border border-[color:var(--border)] bg-white px-3 py-3 text-sm font-semibold"
									onclick={() => responder('no', 'No')}
								>
									No
								</button>
							</div>
						{/if}
						<button
							type="button"
							class="mt-2 w-full border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-3 text-sm font-semibold"
							onclick={() => responder('desconocido', 'No sé')}
						>
							No sé
						</button>
					{:else}
						<h2 class="font-display mt-4 text-xl text-[color:var(--gray-900)]">
							No quedan preguntas útiles
						</h2>
						<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
							El resultado conserva todas las formas
							{esCatalogoMetrico ? ' y configuraciones' : ''}
							que no contradicen tus respuestas.
						</p>
					{/if}
				</section>

				<div class="grid grid-cols-2 gap-2">
					<button
						type="button"
						class="border border-[color:var(--border)] px-3 py-2 text-sm font-medium disabled:opacity-40"
						disabled={respuestas.length === 0}
						onclick={deshacer}
					>
						Deshacer
					</button>
					<button
						type="button"
						class="border border-[color:var(--border)] px-3 py-2 text-sm font-medium"
						onclick={reiniciar}
					>
						Reiniciar
					</button>
				</div>

				{#if respuestas.length > 0}
					<details class="card p-4">
						<summary class="cursor-pointer text-sm font-semibold">
							Ver historial ({respuestas.length})
						</summary>
						<ol class="mt-4 space-y-3">
							{#each respuestas as respuesta, index}
								<li class="border-l-2 border-[color:var(--primary)] pl-3 text-sm">
									<p class="font-medium">{index + 1}. {respuesta.etiqueta}</p>
									<p class="mt-1 text-[color:var(--muted-foreground)]">
										{respuesta.pregunta}
									</p>
								</li>
							{/each}
						</ol>
					</details>
				{/if}
			</div>

			<section class="card overflow-hidden">
				<div class="border-b border-[color:var(--border)] p-5">
					<p class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
						Resultado
					</p>
					<h2 class="font-display mt-2 text-2xl">{tituloResultado()}</h2>
					{#if candidatasResultado.length > 1 && !preguntaActual}
						<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
							Los datos estructurados no permiten separar más estas
							{esCatalogoMetrico ? ' candidatas' : ' formas'} con preguntas razonables.
						</p>
					{/if}
				</div>

				{#if candidatasResultado.length > 0}
					<ul class="divide-y divide-[color:var(--border)]">
						{#each candidatasResultado as candidata}
							<li class="p-5">
								<h3 class="text-lg font-semibold">{candidata.etiqueta}</h3>
								{#if candidata.esResidual}
									<p class="mt-1 text-xs font-medium text-amber-800">
										Salida residual: úsala solo si no corresponde a una forma más precisa
									</p>
								{/if}
								{#if !candidata.esFamilia}
									<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
										Variante de {candidata.familiaEtiqueta}
									</p>
								{/if}
								{#if candidata.definicion}
									<p class="mt-3 text-sm leading-6 text-[color:var(--gray-700)]">
										{candidata.definicion}
									</p>
								{/if}
								<dl class="mt-4 grid gap-x-4 gap-y-2 text-sm sm:grid-cols-2">
									{#if candidata.rasgos.metros.length > 0}
										<div>
											<dt class="text-xs text-[color:var(--muted-foreground)]">Metro</dt>
											<dd>{describirMetros(candidata)}</dd>
										</div>
									{/if}
									{#if candidata.rasgos.rima}
										<div>
											<dt class="text-xs text-[color:var(--muted-foreground)]">Rima</dt>
											<dd>{candidata.rasgos.rima.etiqueta}</dd>
										</div>
									{/if}
									{#if candidata.rasgos.tamanio}
										<div>
											<dt class="text-xs text-[color:var(--muted-foreground)]">Tamaño</dt>
											<dd>{candidata.rasgos.tamanio} versos</dd>
										</div>
									{/if}
									{#if candidata.rasgos.patron}
										<div>
											<dt class="text-xs text-[color:var(--muted-foreground)]">Patrón</dt>
											<dd class="font-mono">{candidata.rasgos.patronEtiqueta ?? candidata.rasgos.patron}</dd>
										</div>
									{/if}
								</dl>
							</li>
						{/each}
					</ul>
				{:else}
					<p class="p-5 text-sm leading-6 text-[color:var(--muted-foreground)]">
						Ninguna forma declara rasgos compatibles con todas las respuestas. Deshaz la última
						respuesta o reinicia el recorrido.
					</p>
				{/if}
			</section>
		</div>

		<footer class="border-t border-[color:var(--border)] pt-4 text-xs text-[color:var(--muted-foreground)]">
			Prueba {data.version?.numero}, compilada desde la revisión
			{data.version?.catalogo_revision ?? 'desconocida'} del catálogo. La herramienta propone
			identificaciones compatibles, no una clasificación definitiva.
		</footer>
	</section>
{/if}
