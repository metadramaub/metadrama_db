<script lang="ts">
	let {
		label,
		title,
		detail,
		href,
		external = false,
		divided = false
	} = $props<{
		label: string;
		title: string;
		detail?: string;
		href: string;
		external?: boolean;
		divided?: boolean;
	}>();
</script>

<a
	{href}
	target={external ? '_blank' : undefined}
	rel={external ? 'noreferrer noopener' : undefined}
	class:border-t={divided}
	class="group grid gap-5 border-[color:var(--border)] py-7 transition-colors hover:bg-white md:grid-cols-3 md:items-center md:px-6 md:py-9"
>
	<p class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">{label}</p>
	<div class="flex flex-wrap items-center justify-between gap-4 md:col-span-2 md:flex-nowrap">
		<div>
			<h2 class="font-display break-all text-2xl text-[color:var(--gray-900)] md:text-3xl">
				{title}
			</h2>
			{#if detail}
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{detail}</p>
			{/if}
		</div>
		<span
			class="inline-block text-xl text-[color:var(--primary)] transition-transform group-hover:translate-x-1"
			aria-hidden="true">{external ? '↗' : '→'}</span
		>
	</div>
</a>
