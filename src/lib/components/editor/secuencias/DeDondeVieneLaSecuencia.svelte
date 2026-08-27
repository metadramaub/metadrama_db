<script lang="ts">
	/**
	 * De dónde viene una secuencia que ya estaba anotada con el vocabulario legado.
	 *
	 * **Dos líneas: lo que decía el sistema antiguo y lo que propondría el nuevo.** No rellena nada
	 * ni pretende hacerlo: la migración se hace a mano, secuencia a secuencia, con el informe por
	 * obra delante y hablando con quien la anotó. Esto solo evita ir al `.md` para lo más consultado.
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

	const nueva = $derived.by(() => {
		const p = props.propuesta;
		if (!p) return '';
		if (!p.forma_propuesta) return 'sin correspondencia en el catálogo nuevo';
		const nombre = [p.forma_propuesta, p.arquitectura_propuesta].filter(Boolean).join(' · ');
		const respuestas = p.respuestas
			.map((r: { pregunta: string; respuesta: string }) => `${r.pregunta}: ${r.respuesta}`)
			.join(' · ');
		return respuestas ? `${nombre} — ${respuestas}` : nombre;
	});

	/** Lo único que se dice además, y solo cuando hay algo que decir. */
	const aviso = $derived.by(() => {
		const p = props.propuesta;
		if (!p) return '';
		if (p.motivo_revision) return p.motivo_revision;
		if (p.longitud_compatible === false) {
			return 'El número de versos no cuadra con unidades completas de esa forma.';
		}
		return '';
	});
</script>

{#if props.cargando}
	<p class="border-l-4 border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
		Buscando de dónde viene esta secuencia…
	</p>
{:else if props.propuesta}
	<div class="border-l-4 border-amber-600 bg-amber-50 px-3 py-2 text-xs leading-5 text-amber-950">
		<p>
			<span class="font-semibold">Sistema antiguo:</span>
			<code class="rounded bg-amber-100 px-1">{props.propuesta.termino_legado ?? '—'}</code>
		</p>
		<p><span class="font-semibold">Propuesta nueva:</span> {nueva}</p>
		{#if aviso}
			<p class="mt-1 font-medium">{aviso}</p>
		{/if}
	</div>
{/if}
