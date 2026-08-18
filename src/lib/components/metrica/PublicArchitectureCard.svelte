<script lang="ts">
	import type {
		PublicArchitecture,
		PublicMetricScheme,
		PublicRhymeScheme,
		PublicTrait
	} from '$lib/metrica/formas-publicas.types';
	import type { FilaDeRima, Rejilla } from '$lib/metrica/rejilla';
	import MetricPositionGrid from './MetricPositionGrid.svelte';
	import MetricDeterminationLabel from './MetricDeterminationLabel.svelte';
	import PublicFormSectionTree from './PublicFormSectionTree.svelte';
	import Badge from '$lib/components/ui/badge.svelte';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';
	import { renderInlineMarkdown } from '$lib/utils/markdown';
	import {
		determinacionDeExtension,
		determinacionDeMedida,
		determinacionDePartes,
		determinacionDeRepeticion,
		determinacionDeRima,
		type DeterminacionMetrica
	} from '$lib/metrica/determinacion';
	import { rangoDeModalidad } from '$lib/metrica/modalidad';

	/**
	 * Una arquitectura, leída **dimensión a dimensión**: extensión, medida, rima, partes,
	 * repetición y rasgos, una fila por cada una y con marca de cuánto deja determinado la
	 * arquitectura y cuánto concreta cada poema.
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
	const extensionDeterminada = $derived(determinacionDeExtension(arquitectura));
	const medidaDeterminada = $derived(determinacionDeMedida(arquitectura));
	const rimaDeterminada = $derived(determinacionDeRima(arquitectura));
	const partesDeterminadas = $derived(determinacionDePartes(arquitectura));

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
	const esquemasRimaDibujados = $derived(
		new Set(gruposDeRima.flatMap((grupo) => grupo.filas.map((fila) => fila.esquemaRimaId)))
	);
	/** Disposiciones cerradas que existen en el catálogo pero no caben en una rejilla abierta. */
	const esquemasCerradosSinDibujo = $derived(
		arquitectura.esquemasRima.filter(
			(esquema) => !esquema.abierto && !esquemasRimaDibujados.has(esquema.id)
		)
	);

	/** La glosa abierta, en el formato que consume la rejilla. */
	const glosas = $derived.by(() => {
		if (!glosaAbierta) return {};
		const esquema = arquitectura.esquemasRima.find((item) => item.id === glosaAbierta);
		return esquema?.descripcion ? { [glosaAbierta]: esquema.descripcion } : {};
	});

	const tieneGlosa = (esquemaRimaId: string) =>
		Boolean(arquitectura.esquemasRima.find((item) => item.id === esquemaRimaId)?.descripcion);

	/**
	 * A partir de cuántos valores un rasgo excluyente pasa de lista en columna a fila envuelta.
	 *
	 * Los dos o tres valores de un rasgo ordinario piden una línea cada uno, porque llevan detrás
	 * su modalidad y a veces su nota. Un inventario cerrado y de nombres cortos —las diecinueve
	 * asonancias— pide lo contrario: puestos en columna eran diecinueve líneas iguales, y en fila
	 * caben en dos. **No se esconde ninguno**: el recuento acompaña a los valores, no los sustituye.
	 */
	const TOPE_ENUMERAR_RASGOS = 6;

	/**
	 * Un inventario largo se ordena por su nombre, dentro de cada modalidad.
	 *
	 * El `orden` que trae la opción no significa nada para estos valores: las mismas diecinueve
	 * asonancias llegaban en un orden distinto en cada arquitectura del romance, de modo que el
	 * mismo inventario parecía dos. Cuando nada distingue a unos valores de otros, el orden del
	 * nombre es el único que el lector puede seguir. En `arquitectura_rasgos.nombre` está el
	 * nombre del rasgo, igual en todas las filas, así que la comparación va por `valor`.
	 */
	const ordenarInventario = (valores: PublicTrait[]) =>
		[...valores].sort(
			(a, b) =>
				rangoDeModalidad(a.modalidad) - rangoDeModalidad(b.modalidad) ||
				String(a.valor ?? '').localeCompare(String(b.valor ?? ''), 'es', {
					sensitivity: 'base',
					numeric: true
				})
		);

	/** La modalidad compartida por todos los valores, cuando la comparten. */
	const modalidadComun = (valores: PublicTrait[]) => {
		const modalidades = new Set(valores.map((valor) => valor.modalidad ?? ''));
		return modalidades.size === 1 ? (valores[0]?.modalidad ?? null) : null;
	};

	function alternarGlosa(esquemaRimaId: string) {
		glosaAbierta = glosaAbierta === esquemaRimaId ? null : esquemaRimaId;
	}

	/** Una disposición autónoma cuando la arquitectura abierta no ofrece columnas comunes. */
	function rejillaDeEsquema(esquema: PublicRhymeScheme): Rejilla {
		return {
			celdas: esquema.figura.map((_, indice) => ({ verso: indice + 1, medida: null })),
			filasDeRima: [
				{
					esquemaRimaId: esquema.id,
					nombre: esquema.nombre,
					notacion: esquema.notacion,
					modalidad: esquema.modalidad ?? null,
					tipoRima: esquema.tipoRima,
					parte: esquema.deLaSeccion,
					desde: 1,
					hasta: esquema.figura.length,
					clases: esquema.figura
				}
			],
			bandas: [],
			enlaces: [],
			cicla: esquema.cicla,
			recortada: false,
			tieneMedida: false,
			tieneRima: true,
			parte: esquema.deLaSeccion,
			repeticionesDeLaParte: null
		};
	}
</script>

{#snippet dimension(
	rotulo: string,
	determinacion: DeterminacionMetrica,
	ayuda: string | null = null
)}
	<th class="w-40 py-2.5 pr-4 align-top text-left">
		<span
			class="inline-flex items-center gap-1 text-[0.66rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]"
		>
			{rotulo}
			{#if ayuda}
				<InlineNotePopover text={ayuda} label={`Explicar ${rotulo.toLocaleLowerCase('es')}`} />
			{/if}
		</span>
		<MetricDeterminationLabel valor={determinacion} />
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
			<InlineNotePopover text={rasgo.nota} label={`Mostrar nota sobre ${rasgo.nombre}`} />
		{/if}
	</li>
{/snippet}

<section class="border border-[color:var(--border)] p-5">
	<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
		<h3 class="font-display text-xl">{arquitectura.nombre}</h3>
		<div class="flex flex-wrap items-center gap-1.5">
			{#if arquitectura.principal}
				<Badge
					class="bg-[color:var(--gray-50)] text-[0.65rem] uppercase tracking-[0.06em] text-[color:var(--gray-700)]"
				>
					Principal
				</Badge>
			{/if}
			{#if arquitectura.modalidad}
				<Badge
					class="bg-white text-[0.65rem] capitalize tracking-[0.04em] text-[color:var(--muted-foreground)]"
				>
					{arquitectura.modalidad}
				</Badge>
			{/if}
		</div>
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
				{@render dimension('Extensión', extensionDeterminada)}
				<td class="py-2.5 align-top">{extension()}</td>
			</tr>

			<!-- Cuando la arquitectura se elige por variedad, medida y rima no son dos preguntas:
			     son las dos caras de una, y separarlas obliga a recomponer las parejas de memoria. -->
			{#if arquitectura.eligeVariedad}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Variedades', medidaDeterminada)}
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
				{#if repertoriosAbiertos.length === 0 && arquitectura.rejilla?.tieneMedida}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension('Medida', medidaDeterminada)}
						<td class="py-2.5 align-top">
							<!-- Sin pie: el ciclo y los enlaces hablan del dibujo entero y se dicen una sola
							     vez, abajo, donde está la rima que los produce. -->
							<MetricPositionGrid
								rejilla={arquitectura.rejilla}
								mostrar="medida"
								bandas={false}
								pie={false}
							/>
						</td>
					</tr>
				{/if}

				{#each repertoriosAbiertos as esquema, i (`m:${i}`)}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension(
							esquema.deLaSeccion ? `Medida · ${esquema.deLaSeccion}` : 'Medida',
							medidaDeterminada
						)}
						<td class="py-2.5 align-top">
							<span class="font-medium">{repertorio(esquema)}</span>
							{#if esquema.descripcion}
								<InlineNotePopover
									text={esquema.descripcion}
									label="Mostrar explicación de la medida"
								/>
							{/if}
						</td>
					</tr>
				{/each}

				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rima', rimaDeterminada)}
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
											? `una de ${grupo.filas.length}`
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

						{#if esquemasCerradosSinDibujo.length > 0}
							<div class="mt-2 space-y-2">
								{#each esquemasCerradosSinDibujo as esquema (esquema.id)}
									<div class="flex items-start gap-1">
										<MetricPositionGrid
											rejilla={rejillaDeEsquema(esquema)}
											mostrar="rima"
											bandas={false}
										/>
										{#if esquema.descripcion}
											<InlineNotePopover
												text={esquema.descripcion}
												label={`Mostrar explicación de ${esquema.nombre}`}
											/>
										{/if}
									</div>
								{/each}
							</div>
						{/if}

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
												El catálogo no declara restricciones: «{esquema.nombre}» no fija la
												disposición ni dice qué la acota.
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
					{@render dimension(
						'Partes',
						partesDeterminadas,
						'El signo × indica cuántas veces puede aparecer una parte dentro de la estructura que la contiene. Cuando no se muestra, aparece una sola vez.'
					)}
					<td class="py-2.5 align-top">
						<PublicFormSectionTree sections={arquitectura.secciones} />
					</td>
				</tr>
			{/if}

			{#if repeticionesNorma.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Repetición', determinacionDeRepeticion(arquitectura, false))}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each repeticionesNorma as repeticion, i (`rn:${i}`)}
								<li>
								<span class="font-medium">{repeticion.nombre}</span>
								{#if repeticion.descripcion}
									<InlineNotePopover
										text={repeticion.descripcion}
										label={`Mostrar explicación de ${repeticion.nombre}`}
									/>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if repeticionesElegibles.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Estribillo', determinacionDeRepeticion(arquitectura, true))}
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
									<InlineNotePopover
										text={repeticion.descripcion}
										label={`Mostrar explicación de ${repeticion.nombre}`}
									/>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if arquitectura.rasgos.declarados.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos', { grado: 'fijo' })}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.rasgos.declarados as rasgo, i (`rd:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if arquitectura.rasgos.permitidos.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos permitidos', { grado: 'permitido' })}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.rasgos.permitidos as rasgo, i (`rp:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#each arquitectura.rasgos.excluyentes as grupo, i (`rx:${i}`)}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension(
						grupo.nombre,
						grupo.opcional
							? { grado: 'opcional', detalle: 'una posibilidad como máximo' }
							: { grado: 'variable', detalle: 'una posibilidad' }
					)}
					<td class="py-2.5 align-top">
						<!-- Un inventario cerrado se enseña entero, en fila envuelta y sin repetir la
						     modalidad en cada valor: las diecinueve asonancias del romance ocupan así
						     dos líneas, y de un vistazo se ve que el inventario está cerrado. En
						     columna, con su «· admitida» detrás, eran diecinueve líneas iguales. -->
						{#if grupo.valores.length > TOPE_ENUMERAR_RASGOS}
							<ul class="flex flex-wrap gap-1">
								{#each ordenarInventario(grupo.valores) as rasgo, j (`rxv:${j}`)}
									<li
										class="border border-[color:var(--border)] px-1.5 py-0.5 text-xs font-medium leading-5"
									>
										{rasgo.valor ?? 'Sí'}
										{#if !modalidadComun(grupo.valores) && rasgo.modalidad}
											<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
										{/if}
									</li>
								{/each}
							</ul>
							<p class="mt-1.5 text-xs text-[color:var(--muted-foreground)]">
								{grupo.valores.length} posibilidades{modalidadComun(grupo.valores)
									? `, todas de modalidad ${modalidadComun(grupo.valores)}`
									: ''}
								{#if grupo.nota}
									<InlineNotePopover
										text={grupo.nota}
										label={`Mostrar nota sobre ${grupo.nombre}`}
									/>
								{/if}
							</p>
						{:else}
							<ul class="space-y-1">
								{#each grupo.valores as rasgo, j (`rxv:${j}`)}
									<li>
										<span class="font-medium">{rasgo.valor ?? 'Sí'}</span>
										{#if rasgo.modalidad}
											<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
										{/if}
										{#if rasgo.nota}
											<InlineNotePopover
												text={rasgo.nota}
												label={`Mostrar nota sobre ${grupo.nombre}`}
											/>
										{/if}
									</li>
								{/each}
							</ul>
						{/if}
					</td>
				</tr>
			{/each}

			{#if arquitectura.rasgos.opcionales.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos', { grado: 'opcional' })}
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
