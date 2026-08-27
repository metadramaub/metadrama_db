<script lang="ts">
	/**
	 * De dónde viene una secuencia que ya estaba anotada con el vocabulario legado.
	 *
	 * **Es un mensaje, no un formulario.** Enseña el término con el que se anotó en su día y lo que
	 * el catálogo nuevo propondría a partir de él, y **no rellena nada**: la migración se hace a
	 * mano, secuencia a secuencia, con el informe por obra delante y hablando con quien la anotó.
	 * Automatizarla no ahorraría el repaso, porque el catálogo nuevo pide datos que el viejo no
	 * capturaba y faltan en casi todas.
	 *
	 * *Convive con la anotación ya hecha, y eso es deliberado:* sigue apareciendo aunque la secuencia
	 * esté ya anotada de nuevo, porque hasta que se borren las tablas viejas conviene poder ver de
	 * dónde venía sin salir de la pantalla.
	 */
	export type PropuestaDeSecuencia = {
		termino_legado: string | null;
		forma_propuesta: string | null;
		arquitectura_propuesta: string | null;
		via: string | null;
		detalle: string | null;
		heredado_de: string | null;
		motivo_revision: string | null;
		longitud_compatible: boolean | null;
		respuestas: { pregunta: string; respuesta: string }[];
	};

	const props = $props<{
		propuesta: PropuestaDeSecuencia | null;
		cargando?: boolean;
	}>();

	const VIAS: Record<string, string> = {
		directa: 'el término lo nombra',
		rasgo: 'un rasgo del término, con la forma del padre',
		ascendencia: 'heredado del término padre',
		sin_tipo: 'sin término que traducir'
	};
</script>

{#if props.cargando}
	<div
		class="border-l-4 border-[color:var(--border)] bg-[color:var(--muted)] px-4 py-3 text-sm text-[color:var(--muted-foreground)]"
	>
		Buscando de dónde viene esta secuencia…
	</div>
{:else if props.propuesta}
	<div class="border-l-4 border-amber-600 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-950">
		<p class="font-semibold">Esta secuencia ya estaba anotada con el vocabulario antiguo</p>
		<p class="mt-1">
			Se anotó como
			<code class="rounded bg-amber-100 px-1">{props.propuesta.termino_legado ?? 'sin término'}</code
			>.
			{#if props.propuesta.forma_propuesta}
				El catálogo nuevo propondría <strong>{props.propuesta.forma_propuesta}</strong>{#if props.propuesta.arquitectura_propuesta}{' · '}{props.propuesta.arquitectura_propuesta}{/if}
				{#if props.propuesta.via && VIAS[props.propuesta.via]}
					<span class="text-amber-900">({VIAS[props.propuesta.via]})</span>
				{/if}.
			{:else}
				El catálogo nuevo no sabe a qué forma corresponde.
			{/if}
		</p>

		{#if props.propuesta.respuestas.length > 0}
			<p class="mt-2">
				Y respondería:
				{#each props.propuesta.respuestas as respuesta, i (respuesta.pregunta + respuesta.respuesta)}
					{i > 0 ? ' · ' : ''}<span class="whitespace-nowrap"
						>{respuesta.pregunta}: <strong>{respuesta.respuesta}</strong></span
					>
				{/each}
			</p>
		{/if}

		{#if props.propuesta.motivo_revision}
			<p class="mt-2 font-medium">Ojo: {props.propuesta.motivo_revision}</p>
		{:else if props.propuesta.longitud_compatible === false}
			<p class="mt-2 font-medium">
				Ojo: el número de versos no cuadra con unidades completas de esa forma.
			</p>
		{/if}

		<p class="mt-2 text-amber-900">
			<strong>Nada de esto se rellena solo.</strong> Anótala leyendo el pasaje; esto está aquí para
			que veas de dónde venía sin salir de la pantalla. Lo anotado antes no se borra.
		</p>
	</div>
{/if}
