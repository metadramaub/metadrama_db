<script lang="ts">
	import Norma from './Norma.svelte';
	import Respuestas from './Respuestas.svelte';
	import { ESCENARIOS } from './escenarios';

	let escenario = $state(ESCENARIOS[0].id);
	const elegido = $derived(ESCENARIOS.find((caso) => caso.id === escenario) ?? ESCENARIOS[0]);
</script>

<svelte:head><title>Maqueta del formulario · Versología</title></svelte:head>

<section class="mx-auto max-w-5xl space-y-6 p-6">
	<header class="space-y-3">
		<h1 class="text-2xl font-semibold">Cómo preguntar: dos maneras</h1>
		<p class="max-w-3xl text-sm leading-6">
			Los casos salen de medir el corpus, no de elegir formas cómodas. De las 134 secuencias con
			unidad, solo 24 tienen una sola —el <strong>2 % de los versos</strong>—; las de más de diez
			unidades son el 53 % de las secuencias y el <strong>86 % de los versos</strong>, y la mayor
			tiene 118. Ahí es donde el formulario se rompe.
		</p>
		<p class="max-w-3xl text-sm leading-6">
			Cuánto varían lo dicen las once secuencias que el sistema viejo anotó unidad por unidad:
			<strong>nunca son todas distintas</strong>. El máximo del corpus son cuatro esquemas en 43
			unidades, y siempre hay uno dominante. Aun así está abajo el caso que no se ha visto, porque
			lo que hay que saber no es qué pasa de costumbre sino qué pasa el día que aparezca.
		</p>
		<p class="max-w-3xl text-sm text-[color:var(--muted-foreground)]">
			Y no todo son estrofas repetibles: hay series sin unidades, composiciones con partes y ciclos
			y formas que no preguntan nada. Una manera de preguntar que solo funcione en la quintilla no
			sirve. Esto no guarda nada.
		</p>
	</header>

	<div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
		{#each ESCENARIOS as candidato (candidato.id)}
			<button
				type="button"
				class={`border px-3 py-2 text-left text-sm ${
					escenario === candidato.id
						? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
						: 'border-[color:var(--border)] bg-white'
				}`}
				onclick={() => (escenario = candidato.id)}
			>
				<span class="block font-medium">{candidato.nombre}</span>
				<span class="block text-xs text-[color:var(--muted-foreground)]">{candidato.clase}</span>
			</button>
		{/each}
	</div>

	<div class="border-l-2 border-[color:var(--border)] pl-3">
		<p class="text-sm font-medium">{elegido.forma} · {elegido.nombre}</p>
		<p class="text-sm text-[color:var(--muted-foreground)]">{elegido.porque}</p>
		{#if elegido.partes.length > 0}
			<p class="text-xs text-[color:var(--muted-foreground)]">
				Partes: {elegido.partes.join(' · ')}
			</p>
		{/if}
	</div>

	<div class="grid gap-6 lg:grid-cols-2">
		<article class="space-y-2">
			<h2 class="text-base font-semibold">A′ · Una respuesta y sus excepciones</h2>
			<p class="text-xs text-[color:var(--muted-foreground)]">
				Se responde una vez; lo que se aparta se añade y se lee agrupado.
			</p>
			<Respuestas escenario={elegido} idea="A" />
		</article>
		<article class="space-y-2">
			<h2 class="text-base font-semibold">E · Por respuesta, no por unidad</h2>
			<p class="text-xs text-[color:var(--muted-foreground)]">
				Una tabla por pregunta: qué se respondió, en cuántas unidades y dónde.
			</p>
			<Respuestas escenario={elegido} idea="E" />
		</article>
	</div>

	<hr class="border-[color:var(--border)]" />

	<div class="space-y-3">
		<h2 class="text-xl font-semibold">Y cómo enseñar la norma sin meter ruido</h2>
		<p class="max-w-3xl text-sm leading-6">
			El recuadro de hoy enumera lo que el desplegable ya ofrece: pinta las ocho disposiciones de
			la quintilla encima de la pregunta que las ofrece. Si la rima hay que elegirla, lo que hace
			falta saber es <strong>que se elige y con qué criterio</strong>, no cuáles son. Y la rejilla
			verso a verso, que es buena en la ficha pública y en el demarcador, aquí no ayuda a decidir.
		</p>
	</div>

	<div class="grid gap-6 lg:grid-cols-3">
		{#each [['N1', 'Una línea por dimensión'], ['N2', 'Lo que ya está y lo que decides'], ['N3', 'El criterio, pegado a su pregunta']] as [clave, nombre] (clave)}
			<article class="space-y-2">
				<h3 class="text-base font-semibold">{clave} · {nombre}</h3>
				<Norma escenario={elegido} idea={clave as 'N1' | 'N2' | 'N3'} />
			</article>
		{/each}
	</div>
</section>
