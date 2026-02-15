<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

	const props = $props<{
		categoria: string;
		total: number;
		rootCount: number;
		childCount: number;
		isProtected: boolean;
		editable: boolean;
		href: string;
	}>();
</script>

<article class="card flex flex-col gap-3 p-4">
	<div class="flex items-start justify-between gap-2">
		<h2 class="font-display text-lg text-[color:var(--gray-900)]">{props.categoria}</h2>
		{#if props.isProtected}
			<span class="border border-[color:var(--warning)] bg-[color:var(--muted)] px-2 py-1 text-[10px] font-semibold tracking-[0.06em]">
				PROTEGIDA
			</span>
		{/if}
	</div>

	<div class="grid grid-cols-3 gap-2 text-xs text-[color:var(--muted-foreground)]">
		<div class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-2">
			<div class="text-[10px] uppercase tracking-[0.06em]">Total</div>
			<div class="mt-1 text-sm font-semibold text-[color:var(--foreground)]">{props.total}</div>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-2">
			<div class="text-[10px] uppercase tracking-[0.06em]">Raices</div>
			<div class="mt-1 text-sm font-semibold text-[color:var(--foreground)]">{props.rootCount}</div>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-2">
			<div class="text-[10px] uppercase tracking-[0.06em]">Hijos</div>
			<div class="mt-1 text-sm font-semibold text-[color:var(--foreground)]">{props.childCount}</div>
		</div>
	</div>

	<div class="mt-auto flex items-center justify-between text-xs">
		<span class={props.editable ? 'text-[color:var(--success)]' : 'text-[color:var(--muted-foreground)]'}>
			{props.editable ? 'Editable' : 'Solo lectura'}
		</span>
		<a href={props.href}>
			<Button variant="secondary">Entrar</Button>
		</a>
	</div>
</article>
