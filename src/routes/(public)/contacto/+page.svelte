<script lang="ts">
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import PublicLinkRow from '$lib/components/public/PublicLinkRow.svelte';
</script>

<svelte:head>
	<title>Contacto · Versología</title>
	<meta
		name="description"
		content="Vías de contacto de Versología y acceso al sitio web de METADRAMA."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="VERSOLOGÍA"
		title="Contacto"
		description="Para consultas relacionadas con Versología, sus datos y sus herramientas, puede escribir al equipo o visitar el sitio web de METADRAMA."
	/>

	<div class="mt-12 border-y border-[color:var(--border)]">
		<PublicLinkRow
			label="CORREO ELECTRÓNICO"
			title="metadrama.ub@gmail.com"
			href="mailto:metadrama.ub@gmail.com"
		/>
		<PublicLinkRow
			label="WEB DE METADRAMA"
			title="METADRAMA"
			detail="www.ub.edu/metadrama"
			href="https://www.ub.edu/metadrama/"
			external
			divided
		/>
	</div>
</section>
