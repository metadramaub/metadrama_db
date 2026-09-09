<script lang="ts">
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
</script>

<svelte:head>
	<title>Acerca de · Versología</title>
	<meta name="description" content="Información sobre Versología, proyecto de METADRAMA." />
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="PROYECTO"
		title="Acerca de"
		description="Versología es la «Base de datos y herramientas de estilometría estrófica para el verso dramático» desarrollada en el marco de METADRAMA."
	/>

	<section class="mt-12 grid gap-5 border-t border-[color:var(--border)] py-8 md:grid-cols-3 md:py-10">
		<h2 class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
			EL RECURSO
		</h2>
		<p class="text-sm leading-7 text-[color:var(--gray-700)] md:col-span-2">
			El recurso reúne análisis métricos de obras del teatro áureo y permite consultar la
			sucesión de formas estróficas, los perfiles de los dramaturgos y el catálogo utilizado para
			describir el corpus.
		</p>
	</section>
</section>

