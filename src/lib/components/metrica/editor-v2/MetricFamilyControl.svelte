<script lang="ts">
	// El control de una pregunta que se responde para todas las unidades a la vez.
	//
	// Vive aparte porque su interior es el mismo que el de una pregunta suelta —casilla, lista o
	// desplegable según cuántas respuestas haya y si admite quedarse vacía— y tenerlo escrito dos
	// veces ya hizo que divergieran: el bloque de arriba pintaba como lista de un elemento el sí/no
	// que el campo suelto pintaba como casilla.
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import type { ControlDePregunta } from '$lib/metrica/controles-formulario';

	const props: {
		control: ControlDePregunta;
		options: MetricCatalogDomainRow[];
		/** El slug que comparten todas las unidades, o nulo si no coinciden. */
		uniform: string | null;
		/** Cuántas unidades tienen ya respuesta, para distinguir «vacío» de «varían». */
		answered: number;
		/** Agrupa los radios; ha de ser único en la pantalla. */
		name: string;
		onChoose: (slug: string) => void;
	} = $props();

	const first = $derived(props.options[0]);
</script>

{#if props.control === 'casilla'}
	<label class="flex cursor-pointer items-center gap-2 text-sm">
		<input
			type="checkbox"
			checked={props.uniform === String(first?.slug ?? '')}
			onchange={(event) =>
				props.onChoose(event.currentTarget.checked ? String(first?.slug ?? '') : '')}
		/>
		<span>{String(first?.nombre ?? '')}</span>
	</label>
{:else if props.control === 'lista'}
	<div class="w-full space-y-1">
		{#each props.options as option (String(option.opcion_eleccion_id))}
			{@const slug = String(option.slug)}
			<label
				class={`flex cursor-pointer items-start gap-2 border px-3 py-2 text-sm ${
					props.uniform === slug
						? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
						: 'border-[color:var(--border)] bg-white'
				}`}
			>
				<input
					type="radio"
					class="mt-0.5"
					name={props.name}
					checked={props.uniform === slug}
					onchange={() => props.onChoose(slug)}
				/>
				<span>
					{String(option.nombre)}
					{#if option.descripcion}
						<span class="block text-xs text-[color:var(--muted-foreground)]">
							{String(option.descripcion)}
						</span>
					{/if}
				</span>
			</label>
		{/each}
	</div>
	{#if props.uniform === null && props.answered > 0}
		<span class="text-xs text-[color:var(--muted-foreground)]">
			Varían entre unidades; cada una conserva la suya
		</span>
	{/if}
{:else}
	<select
		class="h-10 border border-[color:var(--border)] bg-white px-3 text-sm"
		value={props.uniform ?? ''}
		onchange={(event) => props.onChoose(event.currentTarget.value)}
	>
		<option value="">
			{props.uniform === null && props.answered > 0
				? 'Varían entre unidades'
				: 'Seleccionar respuesta'}
		</option>
		{#each props.options as option (String(option.opcion_eleccion_id))}
			<option value={String(option.slug)}>{String(option.nombre)}</option>
		{/each}
	</select>
{/if}
