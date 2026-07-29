<script lang="ts">
	const scopeRows = [
		{
			value: 'Estrofa',
			meaning: 'El patrón se completa y vuelve a empezar en cada estrofa.',
			example: 'Redondilla: abba.'
		},
		{
			value: 'Serie',
			meaning: 'El patrón gobierna una tirada no estrófica de extensión abierta.',
			example: 'Romance: -a-a-a…'
		},
		{
			value: 'Sección',
			meaning: 'El patrón solo corresponde a una parte interna de una forma compuesta.',
			example: 'La mudanza o la vuelta de un villancico.'
		},
		{
			value: 'Composición',
			meaning: 'La regla relaciona o abarca la composición completa.',
			example: 'La arquitectura global de un soneto o una sextina.'
		}
	];

	const rigidityRows = [
		{ value: 'Fijo', meaning: 'La configuración exige ese patrón.' },
		{ value: 'Preferente', meaning: 'Es el patrón prototípico, pero existen alternativas normales.' },
		{ value: 'Admitido', meaning: 'Es una posibilidad documentada, no la norma dominante.' },
		{ value: 'Libre', meaning: 'La forma exige rima, pero no una distribución fija de sus clases.' },
		{ value: 'No aplicable', meaning: 'La configuración no se caracteriza mediante un patrón de rima.' }
	];

	const fieldGroups = [
		{
			title: 'Estados de revisión',
			rows: [
				['Borrador', 'Todavía se está formalizando.'],
				['Revisada', 'La información ha sido comprobada, pero aún puede requerir una decisión final.'],
				['Aprobada', 'Puede tratarse como dato estable del catálogo.'],
				['Retirada', 'Se conserva por trazabilidad, pero ya no debe utilizarse.']
			]
		},
		{
			title: 'Posiciones métricas',
			rows: [
				['Alternativa', 'Separa dos secuencias completas posibles dentro del mismo patrón.'],
				['Posición', 'Lugar del verso dentro de la secuencia; aquí el orden sí es semántico.'],
				['Medida o modelo', 'Número de sílabas o verso compuesto previamente formalizado.'],
				['Opcional', 'La posición puede faltar sin que deje de cumplirse la configuración.'],
				['Grupo de repetición', 'Identifica el ciclo que vuelve a comenzar cuando la secuencia es repetible.']
			]
		},
		{
			title: 'Posiciones y enlaces de rima',
			rows: [
				['Bloque', 'Unidad repetida o sección a la que pertenece la posición.'],
				['Posición', 'Verso concreto dentro del bloque.'],
				['Ubicación', 'Rima al final o en el interior del verso.'],
				['Clase de rima', 'Letra abstracta que enlaza posiciones; no son las vocales concretas de una asonancia.'],
				['Verso suelto', 'Esa posición no participa en la rima final del patrón.'],
				['Desplazamiento de bloque', 'Permite enlazar una posición con el bloque anterior o siguiente.'],
				['Obligatorio', 'El enlace forma parte de la norma, no de una realización ocasional.']
			]
		},
		{
			title: 'Secciones y repeticiones',
			rows: [
				['Sección superior', 'Parte que contiene a otra parte interna.'],
				['Tipo y nombre', 'Función estructural controlada y denominación legible: cabeza, mudanza, vuelta, remate…'],
				['Repeticiones mínimas y máximas', 'Cuántas veces puede aparecer la sección; vacío significa que no se fija.'],
				['Versos mínimos y máximos', 'Extensión propia de esa sección.'],
				['Patrón asociado', 'Metro o rima que solo gobierna esa sección.'],
				['Regla de repetición', 'Qué elemento reaparece y cómo: palabra final, verso, estribillo o sección.']
			]
		},
		{
			title: 'Familias, tradiciones y relaciones',
			rows: [
				['Familia principal', 'Agrupación preferida para presentar una forma que pertenece a varias familias. Es opcional.'],
				['Origen', 'La forma nace dentro de esa tradición según la bibliografía.'],
				['Adaptación', 'La tradición transforma un modelo procedente de otra.'],
				['Difusión', 'La tradición transmite o extiende la forma.'],
				['Uso', 'La forma está documentada en la tradición sin afirmar origen ni dependencia.'],
				['Subtipo de', 'La identidad añade una restricción estable a otra identidad más general.'],
				['Variante histórica de', 'Es una realización históricamente diferenciada de otra forma.'],
				['Derivada de', 'Existe dependencia genética o formal documentada.'],
				['Equivalente de', 'Dos nombres catalogados describen la misma identidad; normalmente convendrá fusionarlos y usar un alias.'],
				['Relacionada/contrasta con', 'Relación explícita útil para consulta, pero sin herencia estructural.']
			]
		},
		{
			title: 'Alias, rasgos y fuentes',
			rows: [
				['Alias equivalente', 'Otro nombre plenamente intercambiable.'],
				['Variante gráfica', 'Diferencia solo ortográfica.'],
				['Nombre histórico', 'Denominación localizada en una época o fuente.'],
				['Abreviatura', 'Forma abreviada del nombre.'],
				['Rasgo definitorio', 'Debe cumplirse para esa configuración.'],
				['Rasgo habitual', 'Es frecuente, pero no obligatorio.'],
				['Rasgo admitido', 'Está documentado como posibilidad.'],
				['Rasgo destacable', 'Puede anotarse cuando resulta analíticamente relevante.'],
				['Afirmación de fuente', 'Vincula una proposición bibliográfica concreta con la forma, configuración, patrón o rasgo que respalda.']
			]
		}
	];
</script>

<div class="space-y-8">
	<header class="max-w-4xl">
		<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
			Guía de decisión
		</p>
		<h2 class="mt-1 text-2xl font-semibold">Cómo se describe una forma métrica</h2>
		<p class="mt-3 text-sm leading-6 text-[color:var(--muted-foreground)]">
			El catálogo separa la identidad de una forma de sus realizaciones posibles. No hay que
			rellenar todos los campos: solo se declara aquello que define, caracteriza o documenta una
			configuración. En una secuencia concreta se eligen las alternativas admitidas que sean
			analíticamente útiles; solo lo que queda fuera de ellas se registra como desviación.
		</p>
	</header>

	<section class="grid gap-4 lg:grid-cols-4">
		{#each [
			['1', 'Forma', 'La identidad reconocible y seleccionable: romance, lira, soneto.'],
			['2', 'Configuración', 'Una norma o alternativa interna que no necesita convertirse en otra forma.'],
			['3', 'Patrones', 'Metro, rima, secciones y repeticiones que formalizan esa configuración.'],
			['4', 'Registro editorial', 'El editor elige forma, alternativas observadas y, solo cuando existen, desviaciones.']
		] as item}
			<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
				<p class="text-xs font-semibold uppercase tracking-wide text-[color:var(--muted-foreground)]">{item[0]}</p>
				<h3 class="mt-1 font-semibold">{item[1]}</h3>
				<p class="mt-2 text-sm leading-6">{item[2]}</p>
			</div>
		{/each}
	</section>

	<section class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
		<h3 class="text-lg font-semibold">Qué genera una pregunta para el editor</h3>
		<p class="max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			Una posibilidad formalizada no obliga por sí sola a añadir un campo. Se crea un grupo de
			elección cuando existen varias realizaciones admitidas y distinguirlas aporta información al
			corpus. Cada respuesta sigue apuntando a un metro, patrón, sección, repetición o valor de
			rasgo normalizado.
		</p>
		<div class="grid gap-4 text-sm leading-6 lg:grid-cols-3">
			<div>
				<h4 class="font-medium">Resultado único</h4>
				<p class="mt-1 text-[color:var(--muted-foreground)]">
					Se deriva de la configuración y no se pregunta.
				</p>
			</div>
			<div>
				<h4 class="font-medium">Alternativas admitidas</h4>
				<p class="mt-1 text-[color:var(--muted-foreground)]">
					El editor elige una o varias, una vez por secuencia o en cada unidad interna.
				</p>
			</div>
			<div>
				<h4 class="font-medium">Fuera de las alternativas</h4>
				<p class="mt-1 text-[color:var(--muted-foreground)]">
					Se registra como desviación localizada, no como una respuesta adicional.
				</p>
			</div>
		</div>
		<p class="border-l-2 border-[color:var(--primary)] pl-3 text-sm">
			<strong>Realización efectiva:</strong> forma + configuración + elecciones admitidas +
			unidades realizadas + desviaciones registradas.
		</p>
	</section>

	<section class="grid gap-6 xl:grid-cols-2">
		<div class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
			<div>
				<h3 class="text-lg font-semibold">Forma</h3>
				<p class="mt-1 text-sm leading-6 text-[color:var(--muted-foreground)]">
					Responde a «¿qué identidad métrica es esta?».
				</p>
			</div>
			<dl class="space-y-3 text-sm leading-6">
				<div>
					<dt class="font-medium">Nivel estructural</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						<em>Verso</em>, <em>estrofa</em>, <em>serie</em>, <em>composición</em> o
						<em>compuesta</em>. «Compuesta» indica que posee secciones internas con funciones distintas.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Seleccionable por el editor</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						La identidad puede asignarse a una secuencia. Una familia o un mero patrón no deben ser seleccionables.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Categoría residual</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Salida como «irregular» o «verso suelto» para casos sin identificación suficiente; no compite como forma canónica.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Activa</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Puede utilizarse. Desactivar conserva el registro y su historia sin ofrecerlo.
					</dd>
				</div>
			</dl>
		</div>

		<div class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
			<div>
				<h3 class="text-lg font-semibold">Configuración</h3>
				<p class="mt-1 text-sm leading-6 text-[color:var(--muted-foreground)]">
					Reúne una combinación coherente de rasgos de la forma.
				</p>
			</div>
			<dl class="space-y-3 text-sm leading-6">
				<div>
					<dt class="font-medium">Prototípica (opcional)</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Se marca solo si una alternativa representa claramente el modelo de referencia. Una forma puede no tener ninguna.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Slug de configuración</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Describe establemente la alternativa, por ejemplo <code>octosilabico_asonante</code>.
						No debe llamarse <code>principal</code>, porque la condición de prototípica puede cambiar.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Grado</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						<em>Fija</em>: única norma; <em>canónica</em>: modelo reconocido;
						<em>admitida</em>: alternativa normal; <em>rara</em>: documentada pero infrecuente;
						<em>irregular documentada</em>: excepción establecida por las fuentes.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Interviene en el demarcador</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Sus rasgos pueden identificar o descartar la forma mediante preguntas observables.
					</dd>
				</div>
				<div>
					<dt class="font-medium">Número fijo de versos</dt>
					<dd class="text-[color:var(--muted-foreground)]">
						Solo se ofrece para estrofas y composiciones simples. En versos, series y formas
						compuestas se deriva del nivel, de la estructura y de las repeticiones.
					</dd>
				</div>
			</dl>
		</div>
	</section>

	<section class="space-y-4">
		<div>
			<h3 class="text-lg font-semibold">Ámbito de un patrón</h3>
			<p class="mt-1 max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
				Indica dónde empieza, termina o se reinicia una regla. «Unidad genérica» fue un valor de
				importación provisional: no debe elegirse al formalizar una forma; los registros que lo
				conservan están pendientes de revisión.
			</p>
		</div>
		<div class="overflow-x-auto border border-[color:var(--border)]">
			<table class="w-full min-w-[42rem] border-collapse text-left text-sm">
				<thead class="bg-[color:var(--muted)]">
					<tr>
						<th class="px-4 py-3 font-semibold">Valor</th>
						<th class="px-4 py-3 font-semibold">Qué significa</th>
						<th class="px-4 py-3 font-semibold">Ejemplo</th>
					</tr>
				</thead>
				<tbody>
					{#each scopeRows as row}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-4 py-3 font-medium">{row.value}</td>
							<td class="px-4 py-3 leading-6">{row.meaning}</td>
							<td class="px-4 py-3 leading-6 text-[color:var(--muted-foreground)]">{row.example}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</section>

	<section class="grid gap-6 xl:grid-cols-2">
		<div class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
			<h3 class="text-lg font-semibold">Patrón métrico</h3>
			<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
				El nombre breve distingue patrones dentro de una misma configuración; la descripción
				explica su funcionamiento. La medida se enlaza de forma normalizada en cada posición:
				por eso un patrón de cinco octosílabos contiene cinco posiciones que apuntan al mismo
				metro. La interfaz puede resumirlo como «5 × octosílabo».
			</p>
			<dl class="space-y-3 text-sm leading-6">
				<div><dt class="font-medium">Secuencia fija</dt><dd class="text-[color:var(--muted-foreground)]">Cada posición tiene una medida concreta.</dd></div>
				<div><dt class="font-medium">Secuencia repetible</dt><dd class="text-[color:var(--muted-foreground)]">Un ciclo ordenado se repite a lo largo de una serie.</dd></div>
				<div><dt class="font-medium">Conjunto permitido</dt><dd class="text-[color:var(--muted-foreground)]">Se admiten varias medidas, pero su orden no define la forma.</dd></div>
				<div><dt class="font-medium">Abierta</dt><dd class="text-[color:var(--muted-foreground)]">La medida no sigue una secuencia cerrada formalizable.</dd></div>
			</dl>
			<p class="border-l-4 border-[color:var(--primary)] bg-[color:var(--muted)] p-3 text-sm leading-6">
				El número total pertenece a la configuración cuando la unidad es fija. En una secuencia
				métrica posicional, la longitud del patrón se deriva de sus posiciones. Si solo se aplica
				a una parte de la forma, la extensión de esa parte se declara en su sección.
			</p>
			<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
				Una sección fija se edita con un solo número; técnicamente se guarda como un intervalo
				cuyos extremos coinciden. El intervalo solo se despliega cuando existe variación real.
			</p>
		</div>

		<div class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
			<h3 class="text-lg font-semibold">Patrón de rima</h3>
			<p class="text-sm leading-6 text-[color:var(--muted-foreground)]">
				En el esquema, una misma letra indica una misma clase de rima; letras distintas, rimas
				distintas; el guion representa verso suelto y la elipsis una continuación indefinida. Las
				mayúsculas y minúsculas pueden conservar la convención de arte mayor y menor. El esquema
				es una etiqueta legible: la lógica se guarda mediante el comportamiento y las posiciones.
			</p>
			<p class="border-l-4 border-[color:var(--primary)] bg-[color:var(--muted)] p-3 font-mono text-sm">
				Romance: -a-a-a…
			</p>
			<dl class="space-y-3 border-b border-[color:var(--border)] pb-4 text-sm leading-6">
				<div><dt class="font-medium">Secuencia fija</dt><dd class="text-[color:var(--muted-foreground)]">Las posiciones descritas se realizan una sola vez.</dd></div>
				<div><dt class="font-medium">Secuencia repetible</dt><dd class="text-[color:var(--muted-foreground)]">Las posiciones forman un ciclo que vuelve a comenzar. En el romance: verso suelto + verso con clase a.</dd></div>
				<div><dt class="font-medium">Reglas combinatorias</dt><dd class="text-[color:var(--muted-foreground)]">No existe un único orden, pero sí restricciones que deben cumplirse.</dd></div>
				<div><dt class="font-medium">Distribución libre</dt><dd class="text-[color:var(--muted-foreground)]">La forma no fija la colocación de las clases de rima.</dd></div>
			</dl>
			<dl class="space-y-3 text-sm leading-6">
				{#each rigidityRows as row}
					<div><dt class="font-medium">{row.value}</dt><dd class="text-[color:var(--muted-foreground)]">{row.meaning}</dd></div>
				{/each}
			</dl>
		</div>
	</section>

	<section class="space-y-4 border border-[color:var(--border)] bg-[color:var(--card)] p-5">
		<h3 class="text-lg font-semibold">Organización, nombres y evidencia</h3>
		<div class="grid gap-5 text-sm leading-6 lg:grid-cols-3">
			<div><h4 class="font-medium">Familias</h4><p class="mt-1 text-[color:var(--muted-foreground)]">Agrupan identidades estructuralmente emparentadas. No transmiten por sí solas metro, rima ni una relación de subtipo.</p></div>
			<div><h4 class="font-medium">Tradiciones</h4><p class="mt-1 text-[color:var(--muted-foreground)]">Registran origen, adaptación, difusión o uso solo cuando existe apoyo bibliográfico. «Española», «italiana» o «provenzal» no se asignan automáticamente.</p></div>
			<div><h4 class="font-medium">Relaciones y alias</h4><p class="mt-1 text-[color:var(--muted-foreground)]">Los alias son otros nombres de la misma forma. Las relaciones entre formas deben expresar una afirmación concreta y revisable, no una similitud calculada.</p></div>
		</div>
	</section>

	<section class="space-y-4">
		<div>
			<h3 class="text-lg font-semibold">Referencia de campos y valores</h3>
			<p class="mt-1 text-sm leading-6 text-[color:var(--muted-foreground)]">
				Consulta estos bloques cuando una decisión no sea evidente. Si ninguna definición encaja,
				no conviene forzar un valor: puede indicar que el modelo necesita una corrección.
			</p>
		</div>
		<div class="space-y-2">
			{#each fieldGroups as group}
				<details class="border border-[color:var(--border)] bg-[color:var(--card)]">
					<summary class="cursor-pointer px-4 py-3 font-medium">{group.title}</summary>
					<dl class="grid gap-x-6 gap-y-4 border-t border-[color:var(--border)] p-4 text-sm leading-6 md:grid-cols-2">
						{#each group.rows as row}
							<div>
								<dt class="font-medium">{row[0]}</dt>
								<dd class="text-[color:var(--muted-foreground)]">{row[1]}</dd>
							</div>
						{/each}
					</dl>
				</details>
			{/each}
		</div>
	</section>

	<section class="border-l-4 border-sky-500 bg-sky-50 p-5 text-sm leading-6 text-sky-950">
		<h3 class="font-semibold">Cuándo importa el orden</h3>
		<p class="mt-1">
			Solo se introduce orden cuando altera la estructura: sucesión de medidas, posiciones de
			rima, partes internas o permutaciones. Las formas, familias, tradiciones, valores de un
			conjunto y relaciones se muestran por nombre; su orden técnico no forma parte de la
			descripción métrica.
		</p>
	</section>
</div>
