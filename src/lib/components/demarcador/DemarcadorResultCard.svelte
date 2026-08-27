<script lang="ts">
	import { etiquetaNivel } from '$lib/demarcador-metrico/motor';
	import MetricPositionGrid from '$lib/components/metrica/MetricPositionGrid.svelte';
	import type {
		DesviacionLongitud,
		FormaPuntuada,
		InterpretacionLongitud,
		ModalidadEvidencia
	} from '$lib/demarcador-metrico/modelo';

	let { forma, index }: { forma: FormaPuntuada; index: number } = $props();
	const arquitectura = $derived(forma.arquitecturas[0]);
	const otrasArquitecturas = $derived(forma.arquitecturas.slice(1));

	function cantidadVersos(cantidad: number): string {
		return `${cantidad} ${cantidad === 1 ? 'verso' : 'versos'}`;
	}

	function explicarLongitud(interpretacion: InterpretacionLongitud): string {
		if (interpretacion.tipo === 'repeticion') {
			return `El pasaje se divide regularmente en ${interpretacion.unidades} unidades completas de ${cantidadVersos(interpretacion.versosPorUnidad ?? 0)} cada una.`;
		}
		if (interpretacion.tipo === 'unidad') {
			return `El pasaje coincide con una unidad completa de ${cantidadVersos(interpretacion.versosPorUnidad ?? interpretacion.observada)}.`;
		}
		if (interpretacion.tipo === 'serie') {
			return `Los ${cantidadVersos(interpretacion.observada)} forman una sola serie de longitud regular.`;
		}
		return `Los ${cantidadVersos(interpretacion.observada)} cumplen la extensión declarada por esta arquitectura.`;
	}

	function explicarDesviacion(desviacion: DesviacionLongitud): string {
		const alternativas: string[] = [];
		if (desviacion.regularAnterior !== null) {
			alternativas.push(
				`sobra ${cantidadVersos(desviacion.observada - desviacion.regularAnterior)} respecto de una extensión regular de ${desviacion.regularAnterior}`
			);
		}
		if (desviacion.regularSiguiente !== null) {
			alternativas.push(
				`faltan ${cantidadVersos(desviacion.regularSiguiente - desviacion.observada)} para una extensión regular de ${desviacion.regularSiguiente}`
			);
		}
		return `Con ${cantidadVersos(desviacion.observada)} la extensión no es regular: ${alternativas.join(' o ')}. Puede haber una laguna, una adición, otra desviación de la norma o una delimitación distinta del pasaje.`;
	}

	function etiquetaModalidad(modalidad: ModalidadEvidencia): string {
		if (modalidad === 'habitual') return 'habitual';
		if (modalidad === 'admitida') return 'admitido';
		if (modalidad === 'excepcional') return 'excepcional';
		return 'definitorio';
	}
</script>

<li class="p-5 sm:p-6">
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="text-xs font-medium text-[color:var(--muted-foreground)]">{index + 1}</p>
			<h3 class="mt-1 text-xl font-semibold">{forma.formaNombre}</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				{arquitectura.hipotesis.nivelEstructural} · {arquitectura.hipotesis.arquitecturaNombre}
			</p>
		</div>
		<span class="border border-[color:var(--border)] px-2 py-1 text-xs font-medium">
			{arquitectura.desviacionLongitud ? 'Posible con desviación' : etiquetaNivel(forma.nivel)}
		</span>
	</div>

	{#if forma.formaDefinicion}
		<p class="mt-3 text-sm leading-6 text-[color:var(--gray-700)]">{forma.formaDefinicion}</p>
	{/if}
	{#if arquitectura.hipotesis.arquitecturaDescripcion}
		<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
			<strong class="font-semibold text-[color:var(--foreground)]">Esta arquitectura:</strong>
			{arquitectura.hipotesis.arquitecturaDescripcion}
		</p>
	{/if}

	{#if arquitectura.interpretacionLongitud}
		<div class="mt-4 border-l-2 border-[color:var(--foreground)] pl-3">
			<p class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
				Cómo encaja la extensión
			</p>
			<p class="mt-1 text-sm leading-6 text-[color:var(--gray-700)]">
				{explicarLongitud(arquitectura.interpretacionLongitud)}
			</p>
			{#if arquitectura.interpretacionLongitud.regla}
				<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
					Regla del catálogo: {arquitectura.interpretacionLongitud.regla}.
				</p>
			{/if}
		</div>
	{:else if arquitectura.desviacionLongitud}
		<div class="mt-4 border-l-2 border-[color:var(--foreground)] pl-3">
			<p class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
				Extensión no regular
			</p>
			<p class="mt-1 text-sm leading-6 text-[color:var(--gray-700)]">
				{explicarDesviacion(arquitectura.desviacionLongitud)}
			</p>
		</div>
	{/if}

	<!-- La misma rejilla que la ficha del catálogo métrico: una forma se ve igual dondequiera que se mire,
	     y aquí sirve además para reconocerla en el pasaje que se está demarcando. -->
	{#if arquitectura.hipotesis.presentacion.rejilla}
		<div class="mt-4 border-t border-[color:var(--border)] pt-4">
			<h4 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
				Cómo se dibuja
			</h4>
			<div class="mt-2">
				<MetricPositionGrid rejilla={arquitectura.hipotesis.presentacion.rejilla} />
			</div>
		</div>
	{/if}

	<div class="mt-5 grid gap-x-6 gap-y-5 border-t border-[color:var(--border)] pt-4 sm:grid-cols-2">
		{#if arquitectura.hipotesis.presentacion.metro.descripcion}
			<section>
				<h4 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Metro</h4>
				<p class="mt-1 text-sm">{arquitectura.hipotesis.presentacion.metro.descripcion}</p>
			</section>
		{/if}

		{#if arquitectura.hipotesis.presentacion.rima.tipo || arquitectura.hipotesis.presentacion.rima.esquemas.length > 0}
			<section>
				<h4 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Rima</h4>
				{#if arquitectura.hipotesis.presentacion.rima.tipo}
					<p class="mt-1 text-sm">{arquitectura.hipotesis.presentacion.rima.tipo}</p>
				{/if}
				<div class="mt-2 flex flex-wrap gap-1.5">
					{#each arquitectura.hipotesis.presentacion.rima.esquemas as esquema}
						<span class="border border-[color:var(--border)] px-2 py-1 font-mono text-xs" title={esquema.nombre ?? esquema.notacion}>
							{esquema.notacion}
						</span>
					{/each}
				</div>
			</section>
		{/if}

		{#if arquitectura.hipotesis.presentacion.estructura || arquitectura.hipotesis.presentacion.repeticiones.length > 0}
			<section>
				<h4 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Organización</h4>
				{#if arquitectura.hipotesis.presentacion.estructura}
					<p class="mt-1 text-sm">{arquitectura.hipotesis.presentacion.estructura}</p>
				{/if}
				{#each arquitectura.hipotesis.presentacion.repeticiones as repeticion}
					<p class="mt-1 text-xs leading-5 text-[color:var(--muted-foreground)]">{repeticion}</p>
				{/each}
			</section>
		{/if}

		{#if arquitectura.hipotesis.presentacion.rasgos.length > 0}
			<section>
				<h4 class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Rasgos</h4>
				<ul class="mt-1 space-y-1 text-sm">
					{#each arquitectura.hipotesis.presentacion.rasgos as rasgo}
						<li title={rasgo.descripcion ?? undefined}>
							{rasgo.nombre}: {rasgo.valor}
							<span class="text-xs text-[color:var(--muted-foreground)]">({etiquetaModalidad(rasgo.modalidad)})</span>
						</li>
					{/each}
				</ul>
			</section>
		{/if}
	</div>

	{#if otrasArquitecturas.length > 0}
		<p class="mt-4 text-xs leading-5 text-[color:var(--muted-foreground)]">
			<strong class="font-semibold text-[color:var(--foreground)]">Otras arquitecturas de la forma:</strong>
			{otrasArquitecturas.map((item) => item.hipotesis.arquitecturaNombre).join(', ')}.
		</p>
	{/if}

	{#if arquitectura.detalles.some((detalle) => detalle.estado === 'coincide')}
		<p class="mt-3 text-xs leading-5 text-[color:var(--muted-foreground)]">
			<strong class="font-semibold text-[color:var(--foreground)]">Coincide con tus respuestas:</strong>
			{arquitectura.detalles
				.filter((detalle) => detalle.estado === 'coincide')
				.slice(0, 4)
				.map((detalle) => detalle.etiqueta)
				.join(', ')}.
		</p>
	{/if}
</li>
