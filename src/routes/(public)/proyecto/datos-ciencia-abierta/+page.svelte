<script lang="ts">
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import PublicSectionRow from '$lib/components/public/PublicSectionRow.svelte';
</script>

<svelte:head>
	<title>Datos, métodos y ciencia abierta · Versología</title>
	<meta
		name="description"
		content="Información sobre los datos, los métodos, la reutilización y las prácticas de ciencia abierta de Versología."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="PROYECTO"
		title="Datos, métodos y ciencia abierta"
		description="Cómo documentamos el recurso, qué puede reutilizarse y qué información acompañará a sus futuras publicaciones de datos."
	/>

	<div class="mt-12 border-b border-[color:var(--border)]">
		<PublicSectionRow number="01" title="El recurso y sus métodos">
			<p>
				Versología reúne análisis métricos de obras del teatro áureo, perfiles de dramaturgos y
				un catálogo de formas métricas. Las fichas públicas explicitan los datos de identificación
				y el análisis que sostiene cada resultado.
			</p>
			<p>
				El catálogo métrico documenta las categorías empleadas, mientras que las fichas permiten
				seguir su aplicación en las obras publicadas. Esta trazabilidad es el punto de partida
				para interpretar y reutilizar los resultados con contexto.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="02" title="Cita y atribución">
			<p>
				Cita Versología al emplear el recurso y añade la ficha o el análisis concreto cuando sea
				relevante para tu trabajo. Así se reconoce el trabajo editorial y se conserva el vínculo
				entre los resultados reutilizados y su contexto.
			</p>
			<p>
				La página <a
					class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4"
					href="/como-citarnos">Cómo citarnos</a
				> ofrece las referencias del recurso, de un análisis específico y del proyecto de
				investigación en el que se desarrolla.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="03" title="Licencias y reutilización">
			<p>
				Los contenidos propios de Versología se publican bajo licencia
				<a
					class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4"
					href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"
					target="_blank"
					rel="noreferrer noopener">CC BY-NC-SA 4.0</a
				>. Puedes compartirlos y adaptarlos para fines no comerciales, siempre que atribuyas el
				origen, indiques los cambios y distribuyas las adaptaciones bajo la misma licencia.
			</p>
			<p>
				La licencia no sustituye las condiciones de los textos de partida, las imágenes ni otros
				materiales de terceros. Antes de reutilizarlos, consulta su procedencia y las condiciones
				específicas indicadas en la ficha correspondiente.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="04" title="Apertura y futuras publicaciones de datos">
			<p>
				El acceso público se ofrece actualmente a través de las fichas, el catálogo y las
				visualizaciones del sitio. Cuando se publique un conjunto de datos descargable, se
				documentarán su alcance, procedencia, versión, formato, licencia y forma de cita.
			</p>
			<p>
				Esa documentación permitirá distinguir los datos creados por el proyecto de los materiales
				de terceros, y facilitará una reutilización verificable y responsable.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="05" title="Correcciones y contacto">
			<p>
				Si detectas un error, una omisión de procedencia o una duda sobre reutilización, ponte en
				contacto con el equipo. Las observaciones ayudan a mantener la calidad documental del
				recurso.
			</p>
			<p>
				<a
					class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4"
					href="/contacto">Ir a Contacto</a
				>.
			</p>
		</PublicSectionRow>
	</div>
</section>
