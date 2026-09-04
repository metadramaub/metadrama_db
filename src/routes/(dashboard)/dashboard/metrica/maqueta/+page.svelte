<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

	const { data } = $props();

	type Pregunta = {
		id: string;
		rotulo: string;
		dimension: string;
		alcance: string;
		obligatoria: boolean;
		posicional: boolean;
		opciones: string[];
		seccion: string | null;
	};

	type Caso = {
		forma: string;
		arquitectura: string;
		porque: string;
		descripcion: string;
		norma: { etiqueta: string; valor: string }[];
		partes: string[];
		preguntas: Pregunta[];
	};

	const texto = (fila: MetricCatalogDomainRow, campo: string) =>
		fila[campo] === null || fila[campo] === undefined ? '' : String(fila[campo]);

	/**
	 * Lo que el editor le pide a una arquitectura, leído del catálogo tal cual.
	 *
	 * La maqueta no reutiliza el resumen del editor a propósito: si copiara su lógica, compararíamos
	 * la maqueta con ella misma. Aquí se lee el dato crudo y cada idea decide qué enseñar.
	 */
	function armarCaso(caso: (typeof data.casos)[number]): Caso | null {
		const dominio = data.catalogo.domain;
		const forma = dominio.forms.find((fila) => texto(fila, 'slug') === caso.forma);
		if (!forma) return null;
		const arquitectura = dominio.configurations.find(
			(fila) =>
				texto(fila, 'forma_id') === texto(forma, 'forma_id') &&
				texto(fila, 'slug') === caso.arquitectura
		);
		if (!arquitectura) return null;
		const id = texto(arquitectura, 'arquitectura_id');

		const secciones = dominio.sections.filter((fila) => texto(fila, 'arquitectura_id') === id);
		const grupos = dominio.choiceGroups
			.filter((fila) => texto(fila, 'arquitectura_id') === id && fila.activo !== false)
			.sort((a, b) => Number(a.orden ?? 99) - Number(b.orden ?? 99));

		const preguntas: Pregunta[] = grupos.map((grupo) => {
			const grupoId = texto(grupo, 'grupo_eleccion_id');
			const opciones = dominio.choiceOptions.filter(
				(fila) => texto(fila, 'grupo_eleccion_id') === grupoId
			);
			const seccion = secciones.find(
				(fila) => texto(fila, 'seccion_id') === texto(grupo, 'seccion_id')
			);
			return {
				id: grupoId,
				rotulo: texto(grupo, 'nombre') || texto(grupo, 'slug'),
				dimension: texto(grupo, 'dimension'),
				alcance: texto(grupo, 'alcance'),
				obligatoria: Number(grupo.selecciones_min ?? 0) >= 1,
				posicional: opciones.some((fila) => fila.posicion_unidad !== null),
				opciones: opciones.map((fila) => texto(fila, 'nombre')).filter(Boolean),
				seccion: seccion ? texto(seccion, 'nombre') : null
			};
		});

		const regla = data.catalogo.lengthRules.find(
			(fila) => String(fila.arquitectura_id) === id
		);
		const rasgos = dominio.configurationTraits
			.filter((fila) => texto(fila, 'arquitectura_id') === id)
			.map((fila) => {
				const rasgo = dominio.traits.find(
					(candidato) => texto(candidato, 'rasgo_id') === texto(fila, 'rasgo_id')
				);
				return `${rasgo ? texto(rasgo, 'nombre') : '—'} · ${texto(fila, 'modalidad')}`;
			});

		const silabasBase = dominio.metricOptions.find(
			(fila) =>
				dominio.metricPatterns.some(
					(patron) =>
						texto(patron, 'arquitectura_id') === id &&
						texto(patron, 'esquema_metrico_id') === texto(fila, 'esquema_metrico_id')
				) && texto(fila, 'rol') !== 'quebrado'
		)?.metro_silabas;

		const norma = [
			{ etiqueta: 'Extensión', valor: regla ? String(regla.explicacion ?? '') : 'libre' },
			// La medida se omite si no se resuelve, en vez de decir «Base de — sílabas».
			...(silabasBase ? [{ etiqueta: 'Medida', valor: `Base de ${silabasBase} sílabas` }] : []),
			...(rasgos.length ? [{ etiqueta: 'Rasgos', valor: rasgos.join(' · ') }] : [])
		];

		return {
			forma: texto(forma, 'nombre'),
			arquitectura: texto(arquitectura, 'nombre'),
			porque: caso.porque,
			descripcion: texto(arquitectura, 'descripcion'),
			norma,
			partes: secciones.map((fila) => texto(fila, 'nombre')),
			preguntas
		};
	}

	const casos = $derived(
		data.casos.map((caso) => armarCaso(caso)).filter((caso): caso is Caso => caso !== null)
	);

	let idea = $state<'A' | 'B' | 'C'>('A');
	/** Lo raro, plegado: en la maqueta se abre para poder verlo. */
	let abiertos = $state<Record<string, boolean>>({});
	const abierto = (clave: string) => abiertos[clave] === true;
	const alternar = (clave: string) => (abiertos[clave] = !abiertos[clave]);

	const esRara = (pregunta: Pregunta) => !pregunta.obligatoria;
	const obligatorias = (caso: Caso) => caso.preguntas.filter((pregunta) => !esRara(pregunta));
	const opcionales = (caso: Caso) => caso.preguntas.filter(esRara);
	const resumenOpciones = (pregunta: Pregunta) =>
		pregunta.opciones.length === 0
			? 'se escribe'
			: pregunta.opciones.length <= 3
				? pregunta.opciones.join(' · ')
				: `${pregunta.opciones.length} opciones`;
</script>

<svelte:head><title>Maqueta del formulario · Versología</title></svelte:head>

<section class="mx-auto max-w-5xl space-y-6 p-6">
	<header class="space-y-2">
		<h1 class="text-2xl font-semibold">Cómo preguntar: tres maquetas</h1>
		<p class="max-w-3xl text-sm leading-6">
			Los cuatro casos salen de medir el catálogo, no de elegir formas bonitas. De las
			<strong>91 arquitecturas activas</strong>, 18 no preguntan nada, 51 preguntan una o dos cosas
			sin partes y 22 tienen partes o pasan de dos preguntas. Si una maqueta funciona aquí,
			funciona en el resto; y si rompe algo, rompe aquí.
		</p>
		<p class="text-sm text-[color:var(--muted-foreground)]">
			Esto no guarda nada: dibuja el catálogo de verdad para poder compararlas.
		</p>
	</header>

	<div class="flex flex-wrap gap-2 border-y border-[color:var(--border)] py-3">
		{#each [['A', 'Decidir arriba, lo raro plegado'], ['B', 'Una frase que se completa'], ['C', 'Norma en dos líneas, excepciones detrás']] as [clave, nombre] (clave)}
			<button
				type="button"
				class={`border px-3 py-1.5 text-sm ${
					idea === clave
						? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
						: 'border-[color:var(--border)] bg-white'
				}`}
				onclick={() => (idea = clave as 'A' | 'B' | 'C')}
			>
				{clave} · {nombre}
			</button>
		{/each}
	</div>

	{#each casos as caso (caso.forma + caso.arquitectura)}
		<article class="space-y-3">
			<div class="flex flex-wrap items-baseline justify-between gap-2">
				<h2 class="text-lg font-semibold">{caso.forma} · {caso.arquitectura}</h2>
				<p class="text-xs text-[color:var(--muted-foreground)]">{caso.porque}</p>
			</div>

			{#if idea === 'A'}
				<!--
					**A · Decidir arriba, lo raro plegado.**

					Lo que hay que responder sí o sí va primero y sin ceremonia. Todo lo opcional —el
					quiebro, la asonancia, el final acentual— baja a un solo renglón plegado, porque lo
					normal es que no se toque. La norma se consulta, no se lee de arriba abajo.
				-->
				<div class="border border-[color:var(--border)] bg-white">
					<div class="space-y-3 p-4">
						{#each obligatorias(caso) as pregunta (pregunta.id)}
							<label class="block">
								<!-- El rótulo derivado ya trae la parte delante: «Primera quintilla · Esquema de rima». -->
								<span class="mb-1 block text-sm font-medium">{pregunta.rotulo}</span>
								<select class="h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm">
									<option>Seleccionar una respuesta</option>
									{#each pregunta.opciones as opcion (opcion)}<option>{opcion}</option>{/each}
								</select>
							</label>
						{/each}
						{#if obligatorias(caso).length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Nada que responder: la norma lo fija todo.
							</p>
						{/if}
					</div>
					{#if opcionales(caso).length > 0}
						<div class="border-t border-[color:var(--border)] bg-[color:var(--gray-50)] px-4 py-2">
							<button
								type="button"
								class="flex w-full items-baseline justify-between gap-3 text-left text-sm"
								onclick={() => alternar(caso.forma + 'A')}
							>
								<span>
									<span class="font-medium">Rasgos que esta forma admite</span>
									<span class="text-[color:var(--muted-foreground)]">
										· {opcionales(caso)
											.map((pregunta) => pregunta.rotulo.toLowerCase())
											.join(', ')} · ninguno marcado</span
									>
								</span>
								<span class="link-action">{abierto(caso.forma + 'A') ? 'Cerrar' : 'Abrir'}</span>
							</button>
							{#if abierto(caso.forma + 'A')}
								<div class="space-y-2 pt-3">
									{#each opcionales(caso) as pregunta (pregunta.id)}
										<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
											<p class="font-medium">{pregunta.rotulo}</p>
											<p class="text-xs text-[color:var(--muted-foreground)]">
												{pregunta.posicional
													? 'se marca en qué versos'
													: resumenOpciones(pregunta)}
											</p>
										</div>
									{/each}
								</div>
							{/if}
						</div>
					{/if}
				</div>
			{:else if idea === 'B'}
				<!--
					**B · Una frase que se completa.**

					La secuencia se lee como una oración y los desplegables son sus huecos. Es lo más
					compacto posible; lo que hay que mirar aquí es si aguanta la copla real, que tiene
					partes y tres preguntas.
				-->
				<div class="border border-[color:var(--border)] bg-white p-4">
					<p class="flex flex-wrap items-center gap-x-2 gap-y-2 text-sm leading-8">
						<span class="font-medium">{caso.forma}</span>
						<span class="text-[color:var(--muted-foreground)]">{caso.arquitectura.toLowerCase()},</span>
						{#each caso.preguntas as pregunta, indice (pregunta.id)}
							{#if indice > 0}<span class="text-[color:var(--muted-foreground)]">y</span>{/if}
							<select
								class={`h-8 border px-2 text-sm ${
									pregunta.obligatoria
										? 'border-[color:var(--primary)]'
										: 'border-[color:var(--border)] text-[color:var(--muted-foreground)]'
								}`}
							>
								<option>
									{pregunta.obligatoria ? pregunta.rotulo.toLowerCase() : `sin ${pregunta.rotulo.toLowerCase()}`}
								</option>
								{#each pregunta.opciones as opcion (opcion)}<option>{opcion}</option>{/each}
							</select>
						{/each}
						{#if caso.preguntas.length === 0}
							<span class="text-[color:var(--muted-foreground)]">sin nada que elegir.</span>
						{/if}
					</p>
				</div>
			{:else}
				<!--
					**C · Norma en dos líneas, excepciones detrás.**

					Lo más cercano a lo de ahora: se conserva el recuadro de la norma, pero resumido a lo
					que cabe en dos renglones, y el verso a verso se esconde hasta que haga falta.
				-->
				<div class="border border-[color:var(--border)] bg-white">
					<div class="border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-4 py-2 text-xs">
						{#each caso.norma as dato (dato.etiqueta)}
							<span class="mr-4">
								<span class="text-[color:var(--muted-foreground)]">{dato.etiqueta}:</span>
								{dato.valor}
							</span>
						{/each}
						{#if caso.partes.length > 0}
							<span class="mr-4">
								<span class="text-[color:var(--muted-foreground)]">Partes:</span>
								{caso.partes.join(' + ')}
							</span>
						{/if}
					</div>
					<div class="space-y-3 p-4">
						{#each caso.preguntas as pregunta (pregunta.id)}
							<div class="flex flex-wrap items-baseline gap-3">
								<span class="min-w-40 text-sm font-medium">
									{pregunta.rotulo}
									{#if !pregunta.obligatoria}<span
											class="text-xs font-normal text-[color:var(--muted-foreground)]"
										>opcional</span
										>{/if}
								</span>
								{#if pregunta.posicional}
									<span class="text-sm text-[color:var(--muted-foreground)]">
										Ninguno · <span class="link-action">marcar</span>
									</span>
								{:else}
									<select class="h-9 border border-[color:var(--border)] px-2 text-sm">
										<option>Seleccionar</option>
										{#each pregunta.opciones as opcion (opcion)}<option>{opcion}</option>{/each}
									</select>
								{/if}
							</div>
						{/each}
						{#if caso.partes.length > 0}
							<button
								type="button"
								class="link-action text-sm"
								onclick={() => alternar(caso.forma + 'C')}
							>
								{abierto(caso.forma + 'C') ? 'Ocultar' : 'Ver'} la secuencia verso a verso
							</button>
							{#if abierto(caso.forma + 'C')}
								<div class="border border-dashed border-[color:var(--border)] p-3 text-sm text-[color:var(--muted-foreground)]">
									{caso.partes.join(' · ')} — aquí iría la rejilla, solo cuando se pide.
								</div>
							{/if}
						{/if}
					</div>
				</div>
			{/if}
		</article>
	{/each}
</section>
