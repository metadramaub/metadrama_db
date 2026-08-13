<script lang="ts">
	import type {
		PublicArchitecture,
		PublicMetricScheme,
		PublicTrait
	} from '$lib/metrica/formas-publicas.types';
	import type { FilaDeRima } from '$lib/metrica/rejilla';
	import MetricPositionGrid from './MetricPositionGrid.svelte';
	import PublicFormSectionTree from './PublicFormSectionTree.svelte';
	import { renderInlineMarkdown } from '$lib/utils/markdown';

	/**
	 * Una arquitectura, leída **dimensión a dimensión**: extensión, medida, rima, partes,
	 * repetición y rasgos, una fila por cada una y con marca de si la fija la norma o la elige
	 * quien anota.
	 *
	 * Lo que sustituye: una plantilla que enseñaba prosa y repetía cada hecho hasta cuatro veces
	 * —el reparto en partes salía en la figura, en la lista de partes y en la glosa del esquema—.
	 * Aquí cada hecho se dice una vez, en su dimensión, y la prosa del catálogo solo aparece
	 * cuando dice algo que la figura no puede dibujar.
	 */
	const { arquitectura }: { arquitectura: PublicArchitecture } = $props();

	/** Qué glosa está abierta. La abre el lector con el icono de su disposición. */
	let glosaAbierta = $state<string | null>(null);

	function extension(): string {
		const { unidadMin: min, unidadMax: max } = arquitectura;
		if (min == null && max == null) return 'serie abierta';
		if (min != null && max != null) {
			return min === max ? `${min} versos` : `de ${min} a ${max} versos`;
		}
		return min != null ? `desde ${min} versos` : `hasta ${max} versos`;
	}

	/** El repertorio de una medida no fijada, dicho una vez: «7 u 11 sílabas». */
	function repertorio(esquema: PublicMetricScheme): string {
		const dominantes = esquema.repertorio.filter((medida) => medida.rol === 'dominante');
		const quebrados = esquema.repertorio.filter((medida) => medida.rol === 'quebrado');
		const listar = (medidas: typeof esquema.repertorio) =>
			medidas.map((medida) => medida.silabas).join(' · ');
		if (dominantes.length > 0 && quebrados.length > 0) {
			return `${listar(dominantes)} de base, con quebrados de ${listar(quebrados)}`;
		}
		return `${listar(esquema.repertorio)} sílabas`;
	}

	const repertoriosAbiertos = $derived(
		arquitectura.esquemasMetricos.filter((esquema) => esquema.repertorio.length > 1)
	);
	const esquemasAbiertos = $derived(
		arquitectura.esquemasRima.filter((esquema) => esquema.abierto)
	);
	const repeticionesNorma = $derived(
		arquitectura.repeticiones.filter((repeticion) => !repeticion.esAlternativa)
	);
	const repeticionesElegibles = $derived(
		arquitectura.repeticiones.filter((repeticion) => repeticion.esAlternativa)
	);

	/**
	 * Las disposiciones agrupadas por la parte de la que son, en orden de lectura. El soneto
	 * elige una para sus cuartetos **y otra** para sus tercetos, y eso solo se entiende si cada
	 * parte lleva su rótulo y su cuenta.
	 */
	const gruposDeRima = $derived.by(() => {
		const grupos: { parte: string | null; filas: FilaDeRima[] }[] = [];
		const porParte = new Map<string, (typeof grupos)[number]>();
		for (const fila of arquitectura.rejilla?.filasDeRima ?? []) {
			const clave = fila.parte ?? '';
			const grupo = porParte.get(clave);
			if (grupo) grupo.filas.push(fila);
			else {
				const nuevo = { parte: fila.parte, filas: [fila] };
				porParte.set(clave, nuevo);
				grupos.push(nuevo);
			}
		}
		return grupos;
	});

	/** La glosa abierta, en el formato que consume la rejilla. */
	const glosas = $derived.by(() => {
		if (!glosaAbierta) return {};
		const esquema = arquitectura.esquemasRima.find((item) => item.id === glosaAbierta);
		return esquema?.descripcion ? { [glosaAbierta]: esquema.descripcion } : {};
	});

	const tieneGlosa = (esquemaRimaId: string) =>
		Boolean(arquitectura.esquemasRima.find((item) => item.id === esquemaRimaId)?.descripcion);

	function alternarGlosa(esquemaRimaId: string) {
		glosaAbierta = glosaAbierta === esquemaRimaId ? null : esquemaRimaId;
	}
</script>

{#snippet dimension(rotulo: string, estado: 'fija' | 'elige' | null, nota: string | null)}
	<th class="w-40 py-2.5 pr-4 align-top text-left">
		<span class="text-[0.66rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
			{rotulo}
		</span>
		{#if nota}
			<span
				class="block text-[0.6rem] font-normal {estado === 'fija'
					? 'text-[color:var(--success)]'
					: 'text-[color:var(--warning)]'}"
			>
				{nota}
			</span>
		{/if}
	</th>
{/snippet}

{#snippet rasgoLinea(rasgo: PublicTrait)}
	<li>
		{rasgo.nombre}{rasgo.valor ? ': ' : ''}{#if rasgo.valor}<span class="font-medium"
				>{rasgo.valor}</span
			>{/if}
		{#if rasgo.modalidad}
			<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
		{/if}
		{#if rasgo.posicionesMax !== null}
			<span class="text-[color:var(--muted-foreground)]">
				· hasta {rasgo.posicionesMax}
				{rasgo.posicionesMax === 1 ? 'posición' : 'posiciones'}
			</span>
		{/if}
		{#if rasgo.nota}
			<span class="block text-[color:var(--muted-foreground)]">
				{@html renderInlineMarkdown(rasgo.nota)}
			</span>
		{/if}
	</li>
{/snippet}

<section class="border border-[color:var(--border)] p-5">
	<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
		<h3 class="font-display text-xl">{arquitectura.nombre}</h3>
		{#if arquitectura.principal}
			<span class="text-xs uppercase tracking-wide text-[color:var(--primary)]">principal</span>
		{/if}
		<span class="text-sm text-[color:var(--muted-foreground)]">
			{extension()}{arquitectura.modalidad ? ` · ${arquitectura.modalidad}` : ''}
		</span>
	</div>

	{#if arquitectura.descripcion}
		<p class="mt-2 max-w-3xl leading-7">{@html renderInlineMarkdown(arquitectura.descripcion)}</p>
	{/if}
	{#if arquitectura.denominaciones.length > 0}
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
			También: {arquitectura.denominaciones.join(' · ')}
		</p>
	{/if}

	<table class="mt-4 w-full border-collapse text-sm">
		<tbody>
			<tr class="border-t border-[color:var(--border)]">
				{@render dimension('Extensión', 'fija', 'la fija la norma')}
				<td class="py-2.5 align-top">{extension()}</td>
			</tr>

			<!-- Cuando la arquitectura se elige por variedad, medida y rima no son dos preguntas:
			     son las dos caras de una, y separarlas obliga a recomponer las parejas de memoria. -->
			{#if arquitectura.eligeVariedad}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Variedades', 'elige', 'se elige una: medida y rima')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.variedades as variedad, i (`v:${i}`)}
								<li class="flex flex-wrap items-baseline gap-x-3">
									<span class="min-w-36 font-medium">{variedad.nombre}</span>
									{#if variedad.medida}<span class="font-mono text-xs">{variedad.medida}</span>{/if}
									{#if variedad.rima}<span class="font-mono text-xs">{variedad.rima}</span>{/if}
									{#if variedad.modalidad}
										<span class="text-xs text-[color:var(--muted-foreground)]">
											· {variedad.modalidad}
										</span>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{:else}
				{#if arquitectura.rejilla?.tieneMedida}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension('Medida', 'fija', 'la fija la norma')}
						<td class="py-2.5 align-top">
							<MetricPositionGrid rejilla={arquitectura.rejilla} mostrar="medida" bandas={false} />
						</td>
					</tr>
				{/if}

				{#each repertoriosAbiertos as esquema, i (`m:${i}`)}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension(
							esquema.deLaSeccion ? `Medida · ${esquema.deLaSeccion}` : 'Medida',
							'elige',
							esquema.uniforme ? 'una para todo el pasaje' : 'verso a verso'
						)}
						<td class="py-2.5 align-top">
							<span class="font-medium">{repertorio(esquema)}</span>
							{#if esquema.descripcion}
								<span class="block text-[color:var(--muted-foreground)]">
									{@html renderInlineMarkdown(esquema.descripcion)}
								</span>
							{/if}
						</td>
					</tr>
				{/each}

				<tr class="border-t border-[color:var(--border)]">
					{@render dimension(
						'Rima',
						gruposDeRima.some((grupo) => grupo.filas.length > 1) ? 'elige' : 'fija',
						gruposDeRima.length > 1 ? 'una por parte' : null
					)}
					<td class="py-2.5 align-top">
						<!-- El régimen es lo primero que hay que saber de una rima, y se declara en el
						     nivel que le corresponde: arriba si es uno, y en cada disposición si dentro
						     de la arquitectura varía. -->
						{#if arquitectura.tipoRima}
							<span class="font-medium">{arquitectura.tipoRima}</span>
						{:else if arquitectura.tipoRimaPorDisposicion}
							<span class="text-[color:var(--muted-foreground)]">según la disposición</span>
						{:else}
							<span class="text-[color:var(--danger)]">
								El catálogo no declara el régimen de rima.
							</span>
						{/if}

						{#each gruposDeRima as grupo, i (`g:${i}`)}
							{#if grupo.parte}
								<p class="mt-2 text-[0.66rem] uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
									{grupo.parte}
									<span class="normal-case tracking-normal">
										— {grupo.filas.length > 1
											? `se elige una de ${grupo.filas.length}`
											: 'disposición única'}
									</span>
								</p>
							{/if}
							<div class="mt-1">
								<MetricPositionGrid
									rejilla={arquitectura.rejilla!}
									mostrar="rima"
									filas={grupo.filas}
									numeros={i === gruposDeRima.length - 1}
									bandas={i === gruposDeRima.length - 1}
									{glosas}
								/>
							</div>
							<!-- La glosa se pide aquí y se abre como una columna de la rejilla: flotando
							     sobre ella se recortaba contra el borde del contenedor con scroll. -->
							{#if grupo.filas.some((fila) => tieneGlosa(fila.esquemaRimaId))}
								<p class="mt-1 flex flex-wrap gap-x-3 text-xs">
									{#each grupo.filas.filter((fila) => tieneGlosa(fila.esquemaRimaId)) as fila (fila.esquemaRimaId)}
										<button
											type="button"
											class="underline decoration-dotted hover:no-underline"
											aria-expanded={glosaAbierta === fila.esquemaRimaId}
											onclick={() => alternarGlosa(fila.esquemaRimaId)}
										>
											{glosaAbierta === fila.esquemaRimaId ? 'Ocultar' : 'Qué distingue'}
											{fila.nombre ?? fila.notacion}
										</button>
									{/each}
								</p>
							{/if}
						{/each}

						{#if esquemasAbiertos.length > 0}
							<ul class="mt-2 space-y-1">
								{#each esquemasAbiertos as esquema (esquema.id)}
									<li>
										{#if esquema.deLaSeccion}
											<span class="text-[color:var(--muted-foreground)]">
												{esquema.deLaSeccion}:
											</span>
										{/if}
										{#if esquema.restricciones.length > 0}
											{esquema.restricciones.map((restriccion) => restriccion.texto).join('. ')}
										{:else}
											<span class="text-[color:var(--danger)]">
												La norma no está declarada: «{esquema.nombre}» no fija la disposición ni
												dice qué la acota.
											</span>
										{/if}
										{#if esquema.descripcion}
											<span class="block text-[color:var(--muted-foreground)]">
												{@html renderInlineMarkdown(esquema.descripcion)}
											</span>
										{/if}
									</li>
								{/each}
							</ul>
						{/if}
					</td>
				</tr>
			{/if}

			{#if arquitectura.secciones.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Partes', 'fija', 'la fija la norma')}
					<td class="py-2.5 align-top">
						<PublicFormSectionTree sections={arquitectura.secciones} />
					</td>
				</tr>
			{/if}

			{#if repeticionesNorma.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Repetición', 'fija', 'la fija la norma')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each repeticionesNorma as repeticion, i (`rn:${i}`)}
								<li>
									<span class="font-medium">{repeticion.nombre}</span>
									{#if repeticion.descripcion}
										<span class="block text-[color:var(--muted-foreground)]">
											{@html renderInlineMarkdown(repeticion.descripcion)}
										</span>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if repeticionesElegibles.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Estribillo', 'elige', 'se responde en cada ciclo')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each repeticionesElegibles as repeticion, i (`re:${i}`)}
								<li>
									<span class="font-medium">{repeticion.nombre}</span>
									{#if repeticion.modalidad}
										<span class="text-[color:var(--muted-foreground)]">
											· {repeticion.modalidad}
										</span>
									{/if}
									{#if repeticion.descripcion}
										<span class="block text-[color:var(--muted-foreground)]">
											{@html renderInlineMarkdown(repeticion.descripcion)}
										</span>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if arquitectura.rasgos.declarados.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos', 'fija', 'los afirma la arquitectura')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.rasgos.declarados as rasgo, i (`rd:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#each arquitectura.rasgos.excluyentes as grupo, i (`rx:${i}`)}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension(grupo.nombre, 'elige', 'uno de estos, no varios')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each grupo.valores as rasgo, j (`rxv:${j}`)}
								<li>
									<span class="font-medium">{rasgo.valor ?? 'Sí'}</span>
									{#if rasgo.modalidad}
										<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
									{/if}
									{#if rasgo.nota}
										<span class="block text-[color:var(--muted-foreground)]">
											{@html renderInlineMarkdown(rasgo.nota)}
										</span>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/each}

			{#if arquitectura.rasgos.opcionales.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Se observa', 'elige', 'puede no darse')}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.rasgos.opcionales as rasgo, i (`ro:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}
		</tbody>
	</table>
</section>
