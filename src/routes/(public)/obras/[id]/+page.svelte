<script lang="ts">
	import { renderMarkdown } from '$lib/utils/markdown';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
</script>

<section>
	<a class="text-sm underline-offset-2 hover:underline" href="/obras">Volver al catalogo</a>
	<h1 class="mt-2 font-display text-3xl text-[color:var(--gray-900)]">{data.obra.titulo}</h1>
	<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
		{(data.obra.autoria ?? []).length > 0 ? (data.obra.autoria ?? []).join(', ') : 'Autoria no indicada'}
	</p>

	{#if data.canSeeAllPublished && !data.obra.visible_publico}
		<div class="card mt-4 border border-[color:var(--border)] p-3 text-sm text-[color:var(--muted-foreground)]">
			Esta obra esta publicada en flujo editorial, pero no visible sin login.
		</div>
	{/if}

	<div class="card mt-6 grid gap-3 p-4 text-sm">
		<p><strong>Fechas tradicionales:</strong> {data.obra.fecha_inicio_trad ?? '--'} - {data.obra.fecha_fin_trad ?? '--'}</p>
		<p><strong>Fechas Metadrama:</strong> {data.obra.fecha_inicio_metadrama ?? '--'} - {data.obra.fecha_fin_metadrama ?? '--'}</p>
		<div>
			<p><strong>Fuente de fecha:</strong></p>
			{#if (data.obra.fuente_fecha ?? '').trim().length > 0}
				<div class="mt-1 text-sm">{@html renderMarkdown(data.obra.fuente_fecha ?? '')}</div>
			{:else}
				<p>Sin dato</p>
			{/if}
		</div>
		<p><strong>Visible sin login:</strong> {data.obra.visible_publico ? 'Si' : 'No'}</p>
		{#if (data.obra.variantes_titulo ?? []).length > 0}
			<p><strong>Variantes de titulo:</strong> {(data.obra.variantes_titulo ?? []).join(' | ')}</p>
		{/if}
	</div>

	<div class="card mt-4 p-4">
		<h2 class="text-lg font-semibold">Edicion base utilizada</h2>
		{#if (data.obra.edicion ?? '').trim().length > 0}
			<div class="mt-2 text-sm">{@html renderMarkdown(data.obra.edicion ?? '')}</div>
		{:else}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Sin dato.</p>
		{/if}
	</div>

	<div class="card mt-6 p-4">
		<h2 class="text-lg font-semibold">Analisis editorial</h2>
		{#if (data.obra.analisis_editor ?? '').trim().length > 0}
			<p class="mt-2 whitespace-pre-wrap text-sm">{data.obra.analisis_editor}</p>
		{:else}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Sin analisis publicado.</p>
		{/if}
	</div>

	<div class="card mt-4 p-4">
		<h2 class="text-lg font-semibold">Bibliografia</h2>
		{#if (data.obra.bibliografia ?? '').trim().length > 0}
			<p class="mt-2 whitespace-pre-wrap text-sm">{data.obra.bibliografia}</p>
		{:else}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Sin bibliografia publicada.</p>
		{/if}
	</div>
</section>
