<script lang="ts">
	import type { EscenarioMaqueta } from './escenarios';

	const props: { escenario: EscenarioMaqueta; idea: 'N1' | 'N2' | 'N3' } = $props();

	const fijas = $derived(props.escenario.norma.filter((fila) => fila.estado === 'fija'));
	const eleccion = $derived(props.escenario.norma.filter((fila) => fila.estado === 'elige'));
	const licencias = $derived(props.escenario.norma.filter((fila) => fila.estado === 'admite'));
</script>

{#if props.idea === 'N1'}
	<!--
		**N1 · Una línea por dimensión, diciendo solo en qué estado está.**

		Lo más cercano al recuadro de hoy, pero sin enumerar lo que el desplegable ya ofrece: si la
		rima se elige, lo que hace falta saber es **que se elige** y con qué criterio, no cuáles son
		las ocho disposiciones.
	-->
	<div class="border border-[color:var(--border)] bg-white text-sm">
		{#each props.escenario.norma as fila (fila.dimension)}
			<div class="flex gap-3 border-b border-[color:var(--border)] px-3 py-1.5 last:border-0">
				<span class="w-44 shrink-0 text-[color:var(--muted-foreground)]">{fila.dimension}</span>
				<span class="min-w-0 flex-1">
					{#if fila.estado === 'elige'}
						<strong>lo eliges tú</strong>
					{:else if fila.estado === 'admite'}
						<span class="text-[color:var(--muted-foreground)]">lo admite, no lo exige</span>
					{:else}
						la norma la fija
					{/if}
					{#if fila.texto}
						<span class="text-[color:var(--muted-foreground)]"> · {fila.texto}</span>
					{/if}
				</span>
			</div>
		{/each}
	</div>
{:else if props.idea === 'N2'}
	<!--
		**N2 · Dos bloques: lo que ya está y lo que decides.**

		Separa por lo único que le importa al editor mientras anota: de qué no tiene que ocuparse y
		de qué sí. Lo fijo se resume en una frase corrida, porque no se consulta renglón a renglón.
	-->
	<div class="space-y-2 border border-[color:var(--border)] bg-white p-3 text-sm">
		<p>
			<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				Ya está fijado
			</span><br />
			<span class="text-[color:var(--muted-foreground)]">
				{fijas.map((fila) => `${fila.dimension.toLowerCase()}: ${fila.texto}`).join(' · ')}
			</span>
		</p>
		{#if eleccion.length > 0}
			<p>
				<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
					Lo decides tú
				</span><br />
				{#each eleccion as fila (fila.dimension)}
					<span class="block">
						<strong>{fila.dimension}</strong>
						{#if fila.texto}<span class="text-[color:var(--muted-foreground)]"> · {fila.texto}</span
							>{/if}
					</span>
				{/each}
			</p>
		{/if}
		{#if licencias.length > 0}
			<p class="text-xs text-[color:var(--muted-foreground)]">
				Admite además: {licencias
					.map((fila) => (fila.texto ? `${fila.dimension.toLowerCase()} (${fila.texto})` : fila.dimension.toLowerCase()))
					.join(', ')}.
			</p>
		{/if}
	</div>
{:else}
	<!--
		**N3 · Arriba una frase; el criterio, pegado a su pregunta.**

		Si la norma solo sirve para saber si eliges bien, su sitio es la pregunta, no un recuadro
		aparte. Arriba queda lo que identifica la forma y un enlace a la ficha para lo demás.
	-->
	<div class="space-y-2">
		<p class="border-l-2 border-[color:var(--border)] pl-3 text-sm">
			{props.escenario.forma}:
			<span class="text-[color:var(--muted-foreground)]">
				{fijas.map((fila) => fila.texto).join(' · ')}
			</span>
			<a class="link-action ml-1" href="/recursos/catalogo-metrico">ver la ficha ↗</a>
		</p>
		<div class="border border-dashed border-[color:var(--border)] p-3 text-sm">
			<p class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				Y en el formulario, cada pregunta llevaría su criterio debajo
			</p>
			{#each eleccion as fila (fila.dimension)}
				<p class="mt-1">
					<strong>{fila.dimension}</strong>
					{#if fila.texto}
						<span class="block text-xs text-[color:var(--muted-foreground)]">{fila.texto}</span>
					{/if}
				</p>
			{/each}
			{#if eleccion.length === 0}
				<p class="mt-1 text-[color:var(--muted-foreground)]">Nada que elegir en esta forma.</p>
			{/if}
		</div>
	</div>
{/if}
