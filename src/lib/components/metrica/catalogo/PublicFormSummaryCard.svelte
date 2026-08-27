<script lang="ts">
	import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
	import { renderInlineMarkdown } from '$lib/utils/markdown';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';

	const props = $props<{ form: PublicFormSummary }>();
</script>

<a
	class="group block overflow-hidden border border-[color:var(--border)] bg-white transition duration-200 hover:border-[color:var(--gray-300)] hover:shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
	href="/formas/{props.form.slug}"
>
	<div class="p-5">
		<div class="flex items-start justify-between gap-5">
			<div class="min-w-0">
				<p
					class="text-[0.66rem] font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]"
				>
					{metricStructuralLevelLabel(props.form.nivelEstructural)}
				</p>
				<h2 class="mt-1 font-display text-xl leading-tight">{props.form.nombre}</h2>
				{#if props.form.denominaciones.length > 0}
					<p class="mt-2 text-[0.8rem] leading-5 text-[color:var(--muted-foreground)]">
						<span class="font-medium text-[color:var(--gray-700)]">También</span>
						· {props.form.denominaciones.join(' · ')}
					</p>
				{/if}
			</div>
			<div class="flex shrink-0 items-center gap-3">
				{#if props.form.arquitecturas > 0}
					<span
						class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs text-[color:var(--muted-foreground)]"
					>
						{props.form.arquitecturas}
						{props.form.arquitecturas === 1 ? 'arquitectura' : 'arquitecturas'}
					</span>
				{/if}
				<ArrowRight
					size={17}
					class="text-[color:var(--gray-400)] transition-transform group-hover:translate-x-1 group-hover:text-[color:var(--foreground)]"
					aria-hidden="true"
				/>
			</div>
		</div>

		{#if props.form.definicion}
			<p class="mt-4 w-full text-[0.9375rem] leading-6 text-[color:var(--gray-700)]">
				{@html renderInlineMarkdown(props.form.definicion)}
			</p>
		{/if}
	</div>

	{#if props.form.tradiciones.length > 0 || props.form.tiposRima.length > 0}
		<footer
			class="flex flex-wrap gap-x-7 gap-y-2 border-t border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 py-3 text-xs"
		>
			{#if props.form.tradiciones.length > 0}
				<p>
					<span
						class="mr-2 uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]"
						>Tradición</span
					>
					<span class="font-medium">{props.form.tradiciones.join(' · ')}</span>
				</p>
			{/if}
			{#if props.form.tiposRima.length > 0}
				<p>
					<span
						class="mr-2 uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]"
						>Rima</span
					>
					<span class="font-medium">{props.form.tiposRima.join(' · ')}</span>
				</p>
			{/if}
		</footer>
	{/if}
</a>
