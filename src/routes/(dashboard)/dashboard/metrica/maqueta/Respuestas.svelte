<script lang="ts">
	import { agrupar, type EscenarioMaqueta, type PreguntaEscenario } from './escenarios';

	const props: { escenario: EscenarioMaqueta; idea: 'A' | 'E' } = $props();

	const unidadesDe = (pregunta: PreguntaEscenario) => pregunta.porUnidad ?? [];
	const gruposDe = (pregunta: PreguntaEscenario) => agrupar(unidadesDe(pregunta));
	const totalDe = (pregunta: PreguntaEscenario) => unidadesDe(pregunta).length;
	const contestada = (pregunta: PreguntaEscenario) =>
		pregunta.alcance === 'secuencia' ? Boolean(pregunta.valor) : totalDe(pregunta) > 0;
</script>

{#if props.escenario.preguntas.length === 0}
	<div class="border border-[color:var(--border)] bg-white p-4 text-sm text-[color:var(--muted-foreground)]">
		Nada que responder: la norma lo fija todo. Solo hay que marcar dónde empieza y dónde acaba.
	</div>
{:else if props.idea === 'A'}
	<!--
		**A′ · Se responde una vez y se añaden excepciones.**

		Vale igual para una serie que para cuarenta unidades, porque el eje no es la unidad sino la
		pregunta: una respuesta arriba y, si algo se aparta, una línea por lo que se aparta. Lo
		opcional que nadie ha tocado queda en un renglón al pie, sin ocupar sitio.
	-->
	<div class="border border-[color:var(--border)] bg-white">
		<div class="space-y-4 p-4">
			{#each props.escenario.preguntas.filter((pregunta) => !pregunta.opcional || contestada(pregunta)) as pregunta (pregunta.rotulo)}
				{@const grupos = gruposDe(pregunta)}
				<div>
					<span class="mb-1 block text-sm font-medium">
						{pregunta.rotulo}
						{#if pregunta.alcance === 'unidad'}
							<span class="font-normal text-[color:var(--muted-foreground)]">
								· en las {totalDe(pregunta)} unidades</span
							>
						{/if}
					</span>

					{#if pregunta.alcance === 'secuencia'}
						<select class="h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm">
							<option>{pregunta.valor || 'Seleccionar una respuesta'}</option>
							{#each pregunta.opciones ?? [] as opcion (opcion)}<option>{opcion}</option>{/each}
						</select>
					{:else}
						<select class="h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm">
							<option>{grupos[0]?.valor ?? 'Seleccionar una respuesta'}</option>
							{#each pregunta.opciones ?? [] as opcion (opcion)}<option>{opcion}</option>{/each}
						</select>

						{#if grupos.length > 1}
							<div class="mt-2 border-l-2 border-[color:var(--primary)] pl-3 text-sm">
								<p class="mb-1 text-[color:var(--muted-foreground)]">
									{grupos.slice(1).reduce((suma, grupo) => suma + grupo.unidades.length, 0)} de {totalDe(
										pregunta
									)} se apartan:
								</p>
								{#each grupos.slice(1) as grupo (grupo.valor)}
									<p class="leading-6">
										<strong>{grupo.valor}</strong>
										<span class="text-[color:var(--muted-foreground)]">
											· {grupo.unidades.length}
											{grupo.unidades.length === 1 ? 'unidad' : 'unidades'} · {grupo.rangos}</span
										>
										<button type="button" class="link-action ml-1">quitar</button>
									</p>
								{/each}
							</div>
						{/if}
						<button type="button" class="link-action mt-1 text-sm">Añadir una excepción</button>
					{/if}
				</div>
			{/each}
		</div>

		{#if props.escenario.preguntas.some((pregunta) => pregunta.opcional && !contestada(pregunta))}
			<div class="border-t border-[color:var(--border)] bg-[color:var(--gray-50)] px-4 py-2 text-sm">
				<span class="text-[color:var(--muted-foreground)]">
					Esta forma admite además
					{props.escenario.preguntas
						.filter((pregunta) => pregunta.opcional && !contestada(pregunta))
						.map((pregunta) => pregunta.rotulo.toLowerCase())
						.join(', ')}. Ninguno marcado.
				</span>
				<button type="button" class="link-action ml-1">Marcar</button>
			</div>
		{/if}
	</div>
{:else}
	<!--
		**E · Por respuesta, no por unidad.**

		Una tabla por pregunta: qué se ha respondido, en cuántas unidades y dónde. Fuera de la
		quintilla la tabla tiene una fila, y ahí es donde hay que ver si aguanta o si es papeleo.
	-->
	<div class="space-y-3">
		{#each props.escenario.preguntas as pregunta (pregunta.rotulo)}
			{@const grupos = gruposDe(pregunta)}
			<div class="border border-[color:var(--border)] bg-white">
				<p class="border-b border-[color:var(--border)] px-4 py-2 text-sm font-medium">
					{pregunta.rotulo}
					{#if pregunta.opcional}<span
							class="font-normal text-[color:var(--muted-foreground)]">· opcional</span
						>{/if}
				</p>
				{#if pregunta.alcance === 'secuencia'}
					<p class="px-4 py-2 text-sm">
						{#if pregunta.valor}
							<strong>{pregunta.valor}</strong>
							<span class="text-[color:var(--muted-foreground)]">· en toda la secuencia</span>
						{:else}
							<span class="text-[color:var(--muted-foreground)]">Sin responder</span>
						{/if}
						<button type="button" class="link-action ml-1">cambiar</button>
					</p>
				{:else if grupos.length === 0}
					<p class="px-4 py-2 text-sm text-[color:var(--muted-foreground)]">
						Ninguna unidad lo lleva. <button type="button" class="link-action">añadir</button>
					</p>
				{:else}
					<table class="w-full text-sm">
						<thead>
							<tr
								class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]"
							>
								<th class="px-4 py-1.5 font-medium">Respuesta</th>
								<th class="px-4 py-1.5 font-medium">Unidades</th>
								<th class="px-4 py-1.5 font-medium">Dónde</th>
								<th class="px-4 py-1.5"></th>
							</tr>
						</thead>
						<tbody>
							{#each grupos as grupo (grupo.valor)}
								<tr class="border-b border-[color:var(--border)] last:border-0">
									<td class="px-4 py-1.5 font-medium">{grupo.valor}</td>
									<td class="px-4 py-1.5 tabular-nums">{grupo.unidades.length}</td>
									<td class="px-4 py-1.5 text-[color:var(--muted-foreground)]">{grupo.rangos}</td>
									<td class="px-4 py-1.5 text-right">
										<button type="button" class="link-action">ampliar</button>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				{/if}
			</div>
		{/each}
	</div>
{/if}
