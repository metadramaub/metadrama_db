<script lang="ts">
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import PublicSectionRow from '$lib/components/public/PublicSectionRow.svelte';
</script>

<svelte:head>
	<title>Guía · Versología</title>
	<meta
		name="description"
		content="Orientaciones básicas para recorrer Versología e interpretar sus fichas."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="RECURSOS"
		title="Guía"
		description="Orientaciones básicas para recorrer el corpus e interpretar la información de sus fichas."
	/>

	<div class="mt-12 border-b border-[color:var(--border)]">
		<PublicSectionRow number="01" title="Por dónde empezar" contentClass="grid gap-5 sm:grid-cols-2">
				<p>
					<a class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4" href="/obras"
						>Obras</a
					>
					reúne el corpus y da acceso a cada ficha pública.
				</p>
				<p>
					<a class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4" href="/autores"
						>Autores</a
					>
					permite consultar los dramaturgos y sus perfiles métricos.
				</p>
				<p>
					<a
						class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4"
						href="/recursos/catalogo-metrico">Catálogo métrico</a
					>
					documenta las formas empleadas para describir el corpus.
				</p>
				<p>
					<a
						class="font-semibold text-[color:var(--gray-900)] underline underline-offset-4"
						href="/recursos/demarcador">Demarcador</a
					>
					ayuda a identificar una forma a partir de sus rasgos estructurales.
				</p>
		</PublicSectionRow>

		<PublicSectionRow number="02" title="Cómo leer una obra">
				<p>
					Cada ficha combina los datos de identificación y autoría con el análisis métrico de la
					obra.
				</p>
				<p>
					El código de barras métrico representa el orden y la extensión relativa de las formas a
					lo largo del texto. Los apartados de la ficha desarrollan esa secuencia y resumen la
					distribución de las formas documentadas.
				</p>
		</PublicSectionRow>

		<PublicSectionRow number="03" title="Conceptos básicos" contentClass="space-y-5">
			<dl class="space-y-5">
				<div>
					<dt class="font-semibold text-[color:var(--gray-900)]">Forma métrica</dt>
					<dd>Categoría del catálogo utilizada para describir la configuración métrica de un pasaje.</dd>
				</div>
				<div>
					<dt class="font-semibold text-[color:var(--gray-900)]">Secuencia métrica</dt>
					<dd>Tramo consecutivo de una obra al que se asigna una forma y su información asociada.</dd>
				</div>
				<div>
					<dt class="font-semibold text-[color:var(--gray-900)]">Perfil métrico</dt>
					<dd>Visión conjunta de las formas y de su presencia en una obra o en el corpus publicado de un autor.</dd>
				</div>
			</dl>
		</PublicSectionRow>

		<PublicSectionRow number="04" title="Responsabilidad y uso">
				<p>
					«Ficha a cargo de» identifica al editor asignado como responsable del análisis público de
					la obra.
				</p>
				<p>
					Para reconocer el trabajo editorial, consulta
					<a class="font-semibold underline underline-offset-4" href="/como-citarnos">Cómo citarnos</a>.
					Los contenidos se publican con licencia
					<a
						class="font-semibold underline underline-offset-4"
						href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"
						target="_blank"
						rel="noreferrer noopener">CC BY-NC-SA 4.0</a
					>.
				</p>
		</PublicSectionRow>
	</div>
</section>
