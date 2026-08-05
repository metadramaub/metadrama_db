<script lang="ts">
	import type {
		PublicArchitecture,
		PublicFormDetail,
		PublicRhymeLink,
		PublicRhymeScheme,
		PublicScheme,
		PublicSection,
		PublicSourceClaim,
		PublicTrait
	} from '$lib/metrica/formas-publicas.types';

	/**
	 * Ficha de una forma, generada del catálogo. No hay texto redactado aquí: si algo falta o
	 * se lee mal, falta o está mal en el catálogo. Es justamente lo que esta página sirve para
	 * detectar.
	 */
	const { data } = $props<{ data: { forma: PublicFormDetail } }>();
	const forma = $derived(data.forma);

	function extension(arquitectura: PublicArchitecture): string | null {
		const { unidadMin: min, unidadMax: max } = arquitectura;
		if (min == null && max == null) return 'serie abierta';
		if (min != null && max != null) {
			return min === max ? `${min} versos` : `de ${min} a ${max} versos`;
		}
		return min != null ? `desde ${min} versos` : `hasta ${max} versos`;
	}

	function repeticiones(seccion: PublicSection): string | null {
		const { repeticionesMin: min, repeticionesMax: max } = seccion;
		if (min == null && max == null) return null;
		if (max == null) return `${min ?? 0} o más`;
		if (min === max) return String(min);
		return `de ${min ?? 0} a ${max}`;
	}

	/**
	 * Qué pasa con la rima de una repetición a la siguiente. Es lo que la notación no puede
	 * decir: `[aA]…` y `[-a]…` se escriben igual, pero la silva estrena rima en cada pareado
	 * y el romance mantiene una sola asonancia. Lo dice el enlace, o su ausencia.
	 */
	function comportamientoDeLaRima(esquema: PublicRhymeScheme): string | null {
		if (esquema.enlaces.length === 0) {
			return esquema.cicla ? 'Cada repetición estrena rimas nuevas.' : null;
		}
		return null;
	}

	function describirEnlace(enlace: PublicRhymeLink, cicla: boolean): string {
		const bloque = cicla ? 'repetición' : 'bloque';
		const destino =
			enlace.desplazamiento > 0
				? `${bloque} siguiente`
				: enlace.desplazamiento < 0
					? `${bloque} anterior`
					: `mismo ${bloque}`;
		if (enlace.desde === enlace.hasta && enlace.desplazamiento !== 0) {
			return `El verso ${enlace.desde} conserva su rima en cada ${bloque}.`;
		}
		return `La rima del verso ${enlace.desde} vuelve en el verso ${enlace.hasta} del ${destino}.`;
	}

	function versos(seccion: PublicSection): string | null {
		const { versosMin: min, versosMax: max } = seccion;
		if (min == null && max == null) return null;
		if (max == null) return `${min} o más versos`;
		if (min === max) return `${min} versos`;
		return `de ${min} a ${max} versos`;
	}

</script>

<svelte:head>
	<title>{forma.nombre} · Catálogo de formas · Versología</title>
	{#if forma.definicion}
		<meta name="description" content={forma.definicion} />
	{/if}
</svelte:head>

<article class="mx-auto w-full max-w-4xl px-4 py-10">
	<nav class="text-sm text-[color:var(--muted-foreground)]">
		<a class="hover:underline" href="/formas">Catálogo de formas</a>
	</nav>

	<header class="mt-4">
		<h1 class="font-display text-3xl">{forma.nombre}</h1>
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
			{forma.tipoRegistro === 'forma' ? 'Forma' : 'Tramo sin forma'} · nivel {forma.nivelEstructural}{forma.gradoEspecificacion
				? ` · ${forma.gradoEspecificacion}`
				: ''}{forma.tradiciones.length > 0
				? ` · tradición ${forma.tradiciones.join(' y ').toLowerCase()}`
				: ''}{forma.tiposRima.length > 0 ? ` · rima ${forma.tiposRima.join(' o ')}` : ''}
		</p>
		{#if forma.definicion}
			<p class="mt-4 max-w-3xl text-lg leading-8">{forma.definicion}</p>
		{:else}
			<p class="mt-4 text-[color:var(--muted-foreground)]">
				Esta forma todavía no tiene definición en el catálogo.
			</p>
		{/if}
	</header>

	{#if forma.denominacionesDetalle.length > 0}
		<section class="mt-8">
			<h2 class="font-display text-xl">También llamada</h2>
			<ul class="mt-2 space-y-1">
				{#each forma.denominacionesDetalle as denominacion (denominacion.nombre)}
					<li class="leading-7">
						{denominacion.nombre}
						<span class="text-sm text-[color:var(--muted-foreground)]">
							· {denominacion.tipo === 'posterior'
								? 'denominación posterior'
								: denominacion.tipo === 'historico'
									? 'denominación histórica'
									: denominacion.tipo}
						</span>
					</li>
				{/each}
			</ul>
		</section>
	{/if}

	{#if forma.arquitecturas_.length > 0}
		<section class="mt-10">
			<h2 class="font-display text-2xl">
				{forma.arquitecturas_.length === 1 ? 'Arquitectura' : 'Arquitecturas'}
			</h2>
			<p class="mt-2 max-w-3xl leading-7 text-[color:var(--muted-foreground)]">
				Cada arquitectura es una manera de realizar la forma: su medida, su rima y sus partes.
			</p>

			<div class="mt-6 space-y-8">
				{#each forma.arquitecturas_ as arquitectura (arquitectura.slug)}
					<section class="border border-[color:var(--border)] p-5">
						<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
							<h3 class="font-display text-xl">{arquitectura.nombre}</h3>
							{#if arquitectura.principal}
								<span class="text-xs uppercase tracking-wide text-[color:var(--primary)]">
									principal
								</span>
							{/if}
							<span class="text-sm text-[color:var(--muted-foreground)]">
								{extension(arquitectura)}{arquitectura.modalidad
									? ` · ${arquitectura.modalidad}`
									: ''}
							</span>
						</div>

						{#if arquitectura.descripcion}
							<p class="mt-2 max-w-3xl leading-7">{arquitectura.descripcion}</p>
						{/if}

						{#if arquitectura.denominaciones.length > 0}
							<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
								También: {arquitectura.denominaciones.join(' · ')}
							</p>
						{/if}

						{#if arquitectura.esquemasMetricos.length > 0 || arquitectura.esquemasRima.length > 0}
							<div class="mt-4 grid gap-4 sm:grid-cols-2">
								{#if arquitectura.esquemasMetricos.length > 0}
									<div>
										<h4 class="text-sm font-semibold">Medida</h4>
										<ul class="mt-1 space-y-1 text-sm">
											{#each arquitectura.esquemasMetricos as esquema (esquema.nombre)}
												<li>
													{esquema.nombre}
													{#if esquema.descripcion}
														<span class="block text-[color:var(--muted-foreground)]">
															{esquema.descripcion}
														</span>
													{/if}
												</li>
											{/each}
										</ul>
									</div>
								{/if}
								{#if arquitectura.esquemasRima.length > 0}
									<div>
										<h4 class="text-sm font-semibold">Rima</h4>
										<ul class="mt-1 space-y-1 text-sm">
											{#each arquitectura.esquemasRima as esquema (esquema.nombre)}
												<li>
													{esquema.nombre}{esquema.notacion ? ` · ${esquema.notacion}` : ''}
													{#if esquema.descripcion}
														<span class="block text-[color:var(--muted-foreground)]">
															{esquema.descripcion}
														</span>
													{/if}
													{#each esquema.enlaces as enlace, indice (indice)}
														<span class="block text-[color:var(--muted-foreground)]">
															{enlace.nota ?? describirEnlace(enlace, esquema.cicla)}
														</span>
													{/each}
													{#if comportamientoDeLaRima(esquema)}
														<span class="block text-[color:var(--muted-foreground)]">
															{comportamientoDeLaRima(esquema)}
														</span>
													{/if}
												</li>
											{/each}
										</ul>
									</div>
								{/if}
							</div>
						{/if}

						{#if arquitectura.secciones.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Partes</h4>
								<ul class="mt-2 space-y-2 text-sm">
									{#each arquitectura.secciones as seccion (seccion.nombre)}
										<li class="border-l-2 border-[color:var(--border)] pl-3">
											<span class="font-medium">{seccion.nombre}</span>
											{#if versos(seccion) || repeticiones(seccion)}
												<span class="text-[color:var(--muted-foreground)]">
													· {[versos(seccion), repeticiones(seccion) ? `×${repeticiones(seccion)}` : null]
														.filter(Boolean)
														.join(' ')}
												</span>
											{/if}
											{#if seccion.reutiliza}
												<span class="block text-[color:var(--muted-foreground)]">
													Reutiliza el repertorio de «{seccion.reutiliza}»
												</span>
											{/if}
											{#if seccion.nota}
												<span class="block text-[color:var(--muted-foreground)]">
													{seccion.nota}
												</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

						{#if arquitectura.variedades.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Variedades</h4>
								<ul class="mt-1 space-y-1 text-sm">
									{#each arquitectura.variedades as variedad (variedad.nombre)}
										<li>
											{variedad.nombre}
											{#if variedad.descripcion}
												<span class="block text-[color:var(--muted-foreground)]">
													{variedad.descripcion}
												</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

						{#if arquitectura.rasgos.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Rasgos que admite</h4>
								<ul class="mt-1 space-y-1 text-sm">
									{#each arquitectura.rasgos as rasgo (rasgo.nombre + (rasgo.valor ?? ''))}
										<li>
											{rasgo.nombre}{rasgo.valor ? `: ${rasgo.valor}` : ''}
											{#if rasgo.modalidad}
												<span class="text-[color:var(--muted-foreground)]">
													· {rasgo.modalidad}
												</span>
											{/if}
											{#if rasgo.nota}
												<span class="block text-[color:var(--muted-foreground)]">{rasgo.nota}</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

					</section>
				{/each}
			</div>
		</section>
	{/if}

	{#if forma.fuentes.length > 0}
		<section class="mt-10">
			<h2 class="font-display text-2xl">Lo que dicen las fuentes</h2>
			<ul class="mt-4 space-y-4">
				{#each forma.fuentes as fuente, indice (indice)}
					<li class="border-l-2 border-[color:var(--border)] pl-4">
						{#if fuente.resumen}
							<p class="leading-7">{fuente.resumen}</p>
						{/if}
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							{fuente.cita}{fuente.localizador ? `, ${fuente.localizador}` : ''} · sobre {fuente.sobre}
						</p>
					</li>
				{/each}
			</ul>
		</section>
	{/if}
</article>
