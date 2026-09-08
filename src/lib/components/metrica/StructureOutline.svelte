<script lang="ts">
	// Esquema de estructura: jornadas y sus cuadros, REUTILIZABLE.
	//
	// Es el mismo índice que la pestaña de secuencias enseña en el dashboard, traído a la ficha:
	// quien lee una comedia quiere ver de un golpe cómo está partida. **No dice el espacio de cada
	// cuadro** porque no se registra —y no se va a pedir a los editores—: dice dónde cambia, no
	// adónde se cambia.
	import type { StructureOutlineJornada } from './metric-display.types';

	const props = $props<{
		jornadas: StructureOutlineJornada[];
		/** Cuántas secuencias caen en cada cuadro, por si se quiere enseñar. */
		secuenciasPorCuadro?: Record<string, number>;
		totalVersos?: number;
	}>();

	const versos = (v_ini: number, v_fin: number) => v_fin - v_ini + 1;

	/** La anchura relativa, para que se vea cuál es la jornada larga sin leer los números. */
	const ancho = (v_ini: number, v_fin: number) => {
		const total = props.totalVersos ?? 0;
		if (!total) return null;
		return `${Math.max(2, (versos(v_ini, v_fin) / total) * 100)}%`;
	};
</script>

<ol class="structure-outline">
	{#each props.jornadas as jornada (jornada.numero)}
		<li class="structure-outline__jornada">
			<div class="structure-outline__cabecera">
				<span class="structure-outline__titulo">Jornada {jornada.numero}</span>
				<span class="structure-outline__rango">
					vv. {jornada.v_ini}-{jornada.v_fin}
					<span class="structure-outline__cuantos">
						({versos(jornada.v_ini, jornada.v_fin)} vv.)
					</span>
				</span>
			</div>

			{#if ancho(jornada.v_ini, jornada.v_fin)}
				<div
					class="structure-outline__barra"
					style={`width:${ancho(jornada.v_ini, jornada.v_fin)}`}
					aria-hidden="true"
				></div>
			{/if}

			{#if jornada.cuadros.length > 0}
				<ol class="structure-outline__cuadros">
					{#each jornada.cuadros as cuadro (cuadro.numero)}
						<li>
							<span class="structure-outline__cuadro">Cuadro {cuadro.numero}</span>
							<span class="structure-outline__rango">
								vv. {cuadro.v_ini}-{cuadro.v_fin}
								<span class="structure-outline__cuantos">
									({versos(cuadro.v_ini, cuadro.v_fin)} vv.)
								</span>
							</span>
							{#if props.secuenciasPorCuadro?.[`${jornada.numero}-${cuadro.numero}`]}
								<span class="structure-outline__cuantos">
									· {props.secuenciasPorCuadro[`${jornada.numero}-${cuadro.numero}`]} secuencias
								</span>
							{/if}
						</li>
					{/each}
				</ol>
			{:else}
				<p class="structure-outline__vacio">Sin cuadros registrados.</p>
			{/if}
		</li>
	{/each}
</ol>

<style>
	.structure-outline {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		font-size: 0.875rem;
	}

	.structure-outline__cabecera {
		display: flex;
		flex-wrap: wrap;
		align-items: baseline;
		gap: 0.5rem;
	}

	.structure-outline__titulo {
		font-size: 0.8125rem;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}

	.structure-outline__rango {
		color: var(--muted-foreground);
		font-variant-numeric: tabular-nums;
	}

	.structure-outline__cuantos {
		font-size: 0.75rem;
	}

	.structure-outline__barra {
		height: 0.25rem;
		margin: 0.35rem 0 0.5rem;
		background: var(--gray-800, currentColor);
		opacity: 0.25;
	}

	.structure-outline__cuadros {
		display: flex;
		flex-direction: column;
		gap: 0.2rem;
		margin-left: 1rem;
		border-left: 1px solid var(--border);
		padding-left: 0.75rem;
	}

	.structure-outline__cuadro {
		font-weight: 600;
	}

	.structure-outline__vacio {
		margin-left: 1rem;
		color: var(--muted-foreground);
	}
</style>
