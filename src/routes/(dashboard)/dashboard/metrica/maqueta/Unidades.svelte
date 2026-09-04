<script lang="ts">
	import { agrupar, describirRangos, type EscenarioMaqueta } from './escenarios';

	const props: { escenario: EscenarioMaqueta; idea: 'A' | 'D' | 'E' } = $props();

	const grupos = $derived(agrupar(props.escenario.unidades));
	const mayoritario = $derived(grupos[0]);
	const excepciones = $derived(grupos.slice(1));
	const conQuebrado = $derived(props.escenario.unidades.filter((unidad) => unidad.quebrado !== null));
	const total = $derived(props.escenario.unidades.length);

	/** Un color por respuesta, para que la tira enseñe el patrón sin leer nada. */
	const paleta = ['#1f2937', '#b45309', '#0e7490', '#7c3aed', '#be123c', '#15803d', '#a16207', '#4338ca'];
	const colorDe = (respuesta: string) => {
		const indice = grupos.findIndex((grupo) => grupo.respuesta === respuesta);
		return paleta[indice % paleta.length];
	};

	let abierto = $state(false);
</script>

{#if props.idea === 'A'}
	<!--
		**A′ · Se responde una vez y se añaden excepciones.**

		La maqueta A llevada al caso real. La respuesta se da en conjunto, y lo que se aparta no se
		corrige recorriendo unidades: se añade como excepción y se lee agrupado. Con 52 unidades y
		tres esquemas, la pantalla tiene tres renglones, no 52.
	-->
	<div class="border border-[color:var(--border)] bg-white">
		<div class="space-y-3 p-4">
			<label class="block">
				<span class="mb-1 block text-sm font-medium">
					Esquema de rima
					<span class="font-normal text-[color:var(--muted-foreground)]">
						· en las {total}
						{total === 1 ? 'unidad' : 'unidades'}
					</span>
				</span>
				<select class="h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm">
					<option>{mayoritario.respuesta}</option>
				</select>
			</label>

			{#if excepciones.length > 0}
				<div class="border-l-2 border-[color:var(--primary)] pl-3 text-sm">
					<p class="mb-1 text-[color:var(--muted-foreground)]">
						{excepciones.reduce((suma, grupo) => suma + grupo.unidades.length, 0)} de {total}
						se apartan:
					</p>
					{#each excepciones as grupo (grupo.respuesta)}
						<p class="leading-6">
							<strong>{grupo.respuesta}</strong>
							<span class="text-[color:var(--muted-foreground)]">
								· {grupo.unidades.length}
								{grupo.unidades.length === 1 ? 'unidad' : 'unidades'} · {grupo.rangos}</span
							>
							<button type="button" class="link-action ml-1">quitar</button>
						</p>
					{/each}
				</div>
			{:else}
				<p class="text-sm text-[color:var(--muted-foreground)]">
					Todas responden lo mismo.
				</p>
			{/if}
			<button type="button" class="link-action text-sm">Añadir una excepción</button>
		</div>

		<div class="border-t border-[color:var(--border)] bg-[color:var(--gray-50)] px-4 py-2 text-sm">
			<span class="font-medium">Pie quebrado</span>
			<span class="text-[color:var(--muted-foreground)]">
				·
				{#if conQuebrado.length === 0}
					ninguna unidad lo lleva
				{:else}
					{conQuebrado.length} de {total} · {describirRangos(conQuebrado)}
				{/if}
			</span>
			<button type="button" class="link-action ml-1">Marcar</button>
		</div>
	</div>
{:else if props.idea === 'D'}
	<!--
		**D · La tira.**

		Una celda por unidad, del color de su respuesta. Es la única que enseña **la forma** de la
		variación: si las excepciones están juntas, repartidas o al final. Con 118 unidades sigue
		cabiendo en dos renglones.
	-->
	<div class="border border-[color:var(--border)] bg-white p-4">
		<div class="mb-2 flex flex-wrap gap-x-4 gap-y-1 text-xs">
			{#each grupos as grupo (grupo.respuesta)}
				<span class="flex items-center gap-1">
					<span class="inline-block" style={`background:${colorDe(grupo.respuesta)};height:0.75rem;width:0.75rem`}></span>
					{grupo.respuesta}
					<span class="text-[color:var(--muted-foreground)]">({grupo.unidades.length})</span>
				</span>
			{/each}
		</div>
		<div class="flex flex-wrap gap-[2px]">
			{#each props.escenario.unidades as unidad (unidad.numero)}
				<span
					class="relative block h-6 w-4"
					style={`background:${colorDe(unidad.respuesta)};height:1.5rem;width:1rem`}
					title={`Unidad ${unidad.numero} · vv. ${unidad.vIni}-${unidad.vFin} · ${unidad.respuesta}`}
				>
					{#if unidad.quebrado !== null}
						<span
							class="absolute bottom-0 left-0 right-0 h-1.5 bg-white"
							title="lleva quebrado"
						></span>
					{/if}
				</span>
			{/each}
		</div>
		<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
			Cada celda es una unidad; la banda blanca de abajo marca las que llevan quebrado. Se pincha
			lo que se aparta.
		</p>
	</div>
{:else}
	<!--
		**E · Por respuesta, no por unidad.**

		Invierte el eje: la pantalla lista lo respondido y cada respuesta dice dónde está. Añadir es
		«esta respuesta también en…», no recorrer la tirada.
	-->
	<div class="border border-[color:var(--border)] bg-white">
		<table class="w-full text-sm">
			<thead>
				<tr class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]">
					<th class="px-4 py-2 font-medium">Respuesta</th>
					<th class="px-4 py-2 font-medium">Unidades</th>
					<th class="px-4 py-2 font-medium">Dónde</th>
					<th class="px-4 py-2"></th>
				</tr>
			</thead>
			<tbody>
				{#each grupos as grupo (grupo.respuesta)}
					<tr class="border-b border-[color:var(--border)]">
						<td class="px-4 py-2 font-medium">{grupo.respuesta}</td>
						<td class="px-4 py-2 tabular-nums">{grupo.unidades.length}</td>
						<td class="px-4 py-2 text-[color:var(--muted-foreground)]">{grupo.rangos}</td>
						<td class="px-4 py-2 text-right"><button type="button" class="link-action">ampliar</button></td>
					</tr>
				{/each}
				{#if conQuebrado.length > 0}
					<tr class="border-b border-[color:var(--border)]">
						<td class="px-4 py-2 font-medium">con pie quebrado</td>
						<td class="px-4 py-2 tabular-nums">{conQuebrado.length}</td>
						<td class="px-4 py-2 text-[color:var(--muted-foreground)]">{describirRangos(conQuebrado)}</td>
						<td class="px-4 py-2 text-right"><button type="button" class="link-action">ampliar</button></td>
					</tr>
				{/if}
			</tbody>
		</table>
		<div class="border-t border-[color:var(--border)] px-4 py-2">
			<button type="button" class="link-action text-sm">Añadir otra respuesta</button>
		</div>
	</div>
{/if}

<details class="mt-2 text-xs" bind:open={abierto}>
	<summary class="cursor-pointer text-[color:var(--muted-foreground)]">
		Ver las {total} unidades como las pinta el editor de hoy
	</summary>
	<div class="mt-2 max-h-64 space-y-1 overflow-y-auto border border-dashed border-[color:var(--border)] p-2">
		{#each props.escenario.unidades as unidad (unidad.numero)}
			<p class="border border-[color:var(--border)] bg-white px-2 py-1">
				{props.escenario.forma}
				{unidad.numero} · vv. {unidad.vIni}–{unidad.vFin} · esquema {unidad.respuesta}{#if unidad.quebrado !== null}
					· quebrado en el verso {unidad.quebrado}{/if}
			</p>
		{/each}
	</div>
</details>
