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
				Versología reúne análisis métricos de obras del teatro áureo, perfiles de dramaturgos y recursos
				sobre métrica como un catálogo de formas y un demarcador. Las fichas públicas explicitan los datos 
				de identificación de cada una así como el origen de los datos. 
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="02" title="Cita y atribución">
			<p>
				Cita Versología al emplear el recurso y añade la ficha concreta cuando utilices un dato o un análisis
				concreto para tu trabajo. Así se reconoce el trabajo del equipo y se conserva el vínculo
				entre los resultados reutilizados y su contexto de origen.
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
				La licencia no sustituye las condiciones de los textos de partida (no difundidos por el proyecto), 
				las imágenes ni otros posibles materiales de terceros. Antes de reutilizarlos, consulta su procedencia y las condiciones
				específicas indicadas en cada caso.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="04" title="Apertura y futuras publicaciones de datos">
			<p>
				El acceso público se ofrece actualmente a través de las fichas, el catálogo y las
				visualizaciones de datos ofrecidas por el sitio. Cuando se publique un conjunto de datos descargable, se
				documentarán su alcance, procedencia, versión, formato, licencia y forma de cita específicos.
			</p>
		</PublicSectionRow>

		<PublicSectionRow number="05" title="Correcciones y contacto">
			<p>
				Si detectas un error, una omisión de procedencia o una duda sobre reutilización, ponte en
				contacto con el equipo.
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
