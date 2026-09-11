<script lang="ts">
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import PublicSectionRow from '$lib/components/public/PublicSectionRow.svelte';
</script>

<svelte:head>
	<title>Datos, reutilización y ciencia abierta · Versología</title>
	<meta
		name="description"
		content="Información sobre los datos disponibles, su reutilización y las prácticas de ciencia abierta de Versología."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="PROYECTO"
		title="Datos, reutilización y ciencia abierta"
		description="Qué datos están disponibles, cómo reutilizarlos y cómo se abrirán las futuras publicaciones de datos."
	/>

	<div class="mt-12 border-b border-[color:var(--border)]">
		<PublicSectionRow number="01" title="Datos disponibles y alcance actual">
			<p>
				Versología permite consultar en línea las fichas, los metadatos y los resultados de análisis
				generados por el proyecto. Por ahora, estos datos se ofrecen exclusivamente a través de la web:
				todavía no existe una publicación descargable y estable de los conjuntos de datos ni una API de
				consulta.
			</p>
			<p>
				En futuras fases, los datos se depositarán en un repositorio externo con DOI para permitir la cita
				específica de cada ficha, y se facilitará una API para su consulta y reutilización.
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

		<PublicSectionRow number="04" title="Correcciones y contacto">
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
