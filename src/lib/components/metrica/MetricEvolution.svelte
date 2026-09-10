<script lang="ts">
	// **Cómo cambia la obra de una jornada a otra**, en dos preguntas: si las secuencias se alargan
	// o se acortan, y si el repertorio se concentra o se diversifica.
	//
	// La diversidad es el **número efectivo de formas**, el mismo `exp(H)` con el que `/obras`
	// ordena el corpus. Se reutiliza a propósito: si una medida ordena obras entre sí, dentro de una
	// obra tiene que querer decir lo mismo. Un 2,0 se comporta como dos formas a medias, aunque la
	// jornada nombre cinco.
	//
	// **Barras en tabla y no un gráfico con ejes.** Son tres puntos y dos magnitudes de unidades
	// distintas —versos y formas equivalentes—: un doble eje aquí insinúa una correlación que nadie
	// ha medido. Cada columna se escala contra su propio máximo, que es lo único comparable.
	type Punto = {
		jornada: number;
		secuencias: number;
		versos: number;
		longitudMedia: number;
		formasDistintas: number;
		numeroEfectivo: number;
	};

	type Lectura = {
		longitud: 'sube' | 'baja' | 'se mantiene';
		diversidad: 'sube' | 'baja' | 'se mantiene';
	} | null;

	const props = $props<{ puntos: Punto[]; lectura: Lectura }>();

	const maxLongitud = $derived(Math.max(1, ...props.puntos.map((p: Punto) => p.longitudMedia)));
	const maxDiversidad = $derived(Math.max(1, ...props.puntos.map((p: Punto) => p.numeroEfectivo)));

	const FRASE_LONGITUD = {
		sube: 'las secuencias se alargan',
		baja: 'las secuencias se acortan',
		'se mantiene': 'las secuencias mantienen su largo'
	};
	const FRASE_DIVERSIDAD = {
		sube: 'el repertorio se diversifica',
		baja: 'el repertorio se concentra',
		'se mantiene': 'el repertorio no cambia de amplitud'
	};

	const romano = (n: number) => ['', 'I', 'II', 'III', 'IV', 'V'][n] ?? String(n);
</script>

<section class="space-y-3" aria-labelledby="metric-evolution-title">
	<div>
		<h2 id="metric-evolution-title" class="text-lg font-semibold">Cómo cambia a lo largo de la obra</h2>
		<!-- Una línea que dice qué pregunta contesta, no cómo está dibujado. -->
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Si las tiradas se alargan o se acortan al avanzar, y si el repertorio de formas se abre o se
			cierra.
		</p>
	</div>

	{#if props.lectura}
		<p class="border-l-2 border-[color:var(--gray-800)] bg-[color:var(--gray-50)] px-3 py-2 text-sm">
			De la primera jornada a la última, <strong>{FRASE_LONGITUD[props.lectura.longitud]}</strong>
			y <strong>{FRASE_DIVERSIDAD[props.lectura.diversidad]}</strong>.
		</p>
	{/if}

	<div class="overflow-x-auto">
		<table class="w-full min-w-[34rem] border-collapse text-sm">
			<thead>
				<tr class="border-b border-[color:var(--border)] text-left">
					<th scope="col" class="py-2 pr-3 font-semibold">Jornada</th>
					<th scope="col" class="py-2 pr-3 font-semibold">Secuencias</th>
					<th scope="col" class="py-2 pr-3 font-semibold">Longitud media</th>
					<th scope="col" class="py-2 pr-3 font-semibold">Formas</th>
					<th scope="col" class="py-2 font-semibold">Diversidad</th>
				</tr>
			</thead>
			<tbody>
				{#each props.puntos as punto (punto.jornada)}
					<tr class="border-b border-[color:var(--border)]">
						<th scope="row" class="py-2 pr-3 text-left font-semibold">{romano(punto.jornada)}</th>
						<td class="py-2 pr-3 tabular-nums">{punto.secuencias}</td>
						<td class="py-2 pr-3">
							<div class="flex items-center gap-2">
								<span class="w-16 tabular-nums">{punto.longitudMedia} vv.</span>
								<span class="h-2 flex-1 bg-[color:var(--gray-100)]">
									<span
										class="block h-2 bg-[color:var(--gray-800)]"
										style={`width: ${(punto.longitudMedia / maxLongitud) * 100}%`}
									></span>
								</span>
							</div>
						</td>
						<td class="py-2 pr-3 tabular-nums">{punto.formasDistintas}</td>
						<td class="py-2">
							<div class="flex items-center gap-2">
								<span class="w-12 tabular-nums">
									{punto.numeroEfectivo.toLocaleString('es', { maximumFractionDigits: 2 })}
								</span>
								<span class="h-2 flex-1 bg-[color:var(--gray-100)]">
									<span
										class="block h-2 bg-[color:var(--primary)]"
										style={`width: ${(punto.numeroEfectivo / maxDiversidad) * 100}%`}
									></span>
								</span>
							</div>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	<!--
		Dicho en la pantalla y no solo en el código: tres jornadas son tres puntos, y de tres puntos
		no sale una tendencia que sostener. Quien lo lea tiene que saberlo.
	-->
	<p class="text-xs text-[color:var(--muted-foreground)]">
		<strong>Diversidad</strong> es el número efectivo de formas: cuántas formas equivaldrían al
		reparto de esta jornada si todas pesaran lo mismo. Es la misma medida con la que se ordena el
		catálogo de obras. Con tres jornadas la lectura describe esta obra; no afirma una tendencia.
	</p>
</section>
