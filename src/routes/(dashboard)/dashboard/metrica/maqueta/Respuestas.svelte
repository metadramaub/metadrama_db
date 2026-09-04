<script lang="ts">
	import { agrupar, type EscenarioMaqueta, type PreguntaEscenario } from './escenarios';

	const props: { escenario: EscenarioMaqueta; idea: 'A' | 'E' } = $props();

	const unidadesDe = (pregunta: PreguntaEscenario) => pregunta.porUnidad ?? [];
	const gruposDe = (pregunta: PreguntaEscenario) => agrupar(unidadesDe(pregunta));
	const contestada = (pregunta: PreguntaEscenario) =>
		pregunta.alcance === 'secuencia' ? Boolean(pregunta.valor) : unidadesDe(pregunta).length > 0;

	/**
	 * Cuántas unidades tiene la secuencia, que no es lo mismo que cuántas responden.
	 *
	 * Un rasgo opcional solo guarda las unidades que lo llevan, así que contar sus respuestas daría
	 * «en las 2 unidades» de una tirada de 52. Lo que hay que decir es **2 de 52**.
	 */
	const totalUnidades = $derived(
		Math.max(
			0,
			...props.escenario.preguntas.map((pregunta) => unidadesDe(pregunta).length)
		)
	);

	/** Qué se responde en general, y qué se aparta. */
	function reparto(pregunta: PreguntaEscenario) {
		const grupos = gruposDe(pregunta);
		if (pregunta.opcional) {
			// En un rasgo opcional lo general es que no lo lleve, y lo que se guarda son las
			// excepciones: no hay respuesta mayoritaria que elegir.
			return { general: null, excepciones: grupos };
		}
		return { general: grupos[0] ?? null, excepciones: grupos.slice(1) };
	}

	let listados = $state<Record<string, boolean>>({});
	const listado = (clave: string) => listados[clave] === true;
</script>

{#if props.escenario.preguntas.length === 0}
	<div
		class="border border-[color:var(--border)] bg-white p-4 text-sm text-[color:var(--muted-foreground)]"
	>
		Nada que responder: la norma lo fija todo. Solo hay que marcar dónde empieza y dónde acaba.
	</div>
{:else if props.idea === 'A'}
	<!--
		**A′ · Lo general arriba, las excepciones debajo, y el detalle a un clic.**

		Tres renglones que dicen tres cosas distintas y se leen en ese orden: qué responde la
		secuencia, qué se aparta, y —si hace falta comprobarlo— la lista entera unidad por unidad.
		Vale igual para una serie sin unidades, donde no hay ni excepciones ni lista.
	-->
	<div class="space-y-4 border border-[color:var(--border)] bg-white p-4">
		{#each props.escenario.preguntas as pregunta (pregunta.rotulo)}
			{@const partes = reparto(pregunta)}
			{@const unidades = unidadesDe(pregunta)}
			<div class="space-y-1">
				<span class="block text-sm font-medium">{pregunta.rotulo}</span>

				{#if pregunta.alcance === 'secuencia'}
					<select class="h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm">
						<option>{pregunta.valor || 'Seleccionar una respuesta'}</option>
						{#each pregunta.opciones ?? [] as opcion (opcion)}<option>{opcion}</option>{/each}
					</select>
				{:else}
					<!-- Lo general. El rótulo va pegado al control para que no se lea como una
					     respuesta más de la lista de abajo. -->
					<div class="flex flex-wrap items-center gap-2">
						<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
							{pregunta.opcional ? 'De partida' : 'En todas'}
						</span>
						{#if pregunta.opcional}
							<span class="text-sm">Ninguna unidad lo lleva</span>
						{:else}
							<select class="h-9 min-w-56 border border-[color:var(--border)] px-2 text-sm">
								<option>{partes.general?.valor ?? 'Seleccionar una respuesta'}</option>
								{#each pregunta.opciones ?? [] as opcion (opcion)}<option>{opcion}</option>{/each}
							</select>
						{/if}
						<span class="text-xs text-[color:var(--muted-foreground)]">
							· {totalUnidades}
							{totalUnidades === 1 ? 'unidad' : 'unidades'}
						</span>
					</div>

					<!-- Y lo que se aparta, con la misma forma siempre: cuántas, cuáles y dónde. -->
					<div class="border-l-2 border-[color:var(--primary)] pl-3">
						{#if partes.excepciones.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Sin excepciones. <button type="button" class="link-action">Añadir una</button>
							</p>
						{:else}
							<p class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Salvo {partes.excepciones.reduce(
									(suma, grupo) => suma + grupo.unidades.length,
									0
								)} de {totalUnidades}
							</p>
							{#each partes.excepciones as grupo (grupo.valor)}
								<p class="text-sm leading-6">
									<strong>{grupo.valor}</strong>
									<span class="text-[color:var(--muted-foreground)]">
										· {grupo.unidades.length}
										{grupo.unidades.length === 1 ? 'unidad' : 'unidades'} · {grupo.rangos}</span
									>
									<button type="button" class="link-action ml-1">quitar</button>
								</p>
							{/each}
							<button type="button" class="link-action text-sm">Añadir otra</button>
						{/if}
					</div>

					<!--
						**La lista entera, a un clic.**

						Repetir cuarenta veces «ababa» no sirve para responder, pero sí para revisar de un
						vistazo antes de dar la secuencia por buena. Va plegada y en una rejilla estrecha:
						número, versos y respuesta.
					-->
					{#if unidades.length > 0 || !pregunta.opcional}
						<button
							type="button"
							class="link-action text-xs"
							onclick={() => (listados[pregunta.rotulo] = !listado(pregunta.rotulo))}
						>
							{listado(pregunta.rotulo) ? 'Ocultar' : 'Ver'} las {totalUnidades} unidades
						</button>
						{#if listado(pregunta.rotulo)}
							<div
								class="max-h-56 overflow-y-auto border border-[color:var(--border)] bg-[color:var(--gray-50)] p-2"
							>
								<div class="grid gap-x-4 gap-y-0.5 text-xs sm:grid-cols-2 lg:grid-cols-3">
									{#each Array.from({ length: totalUnidades }, (_, indice) => indice + 1) as numero (numero)}
										{@const unidad = unidades.find((fila) => fila.numero === numero)}
										{@const excepcional =
											unidad !== undefined &&
											(pregunta.opcional || unidad.valor !== partes.general?.valor)}
										<p class={excepcional ? 'font-medium' : 'text-[color:var(--muted-foreground)]'}>
											<span class="tabular-nums">{numero}</span>
											{#if unidad}
												<span class="tabular-nums">· vv. {unidad.vIni}-{unidad.vFin}</span>
												· {unidad.valor}
											{:else}
												· sin marcar
											{/if}
										</p>
									{/each}
								</div>
							</div>
						{/if}
					{/if}
				{/if}
			</div>
		{/each}
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
					{#if pregunta.opcional}<span class="font-normal text-[color:var(--muted-foreground)]"
							>· opcional</span
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
									<td class="px-4 py-1.5 tabular-nums">
										{grupo.unidades.length}{#if pregunta.opcional}<span
												class="text-[color:var(--muted-foreground)]"> de {totalUnidades}</span
											>{/if}
									</td>
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
