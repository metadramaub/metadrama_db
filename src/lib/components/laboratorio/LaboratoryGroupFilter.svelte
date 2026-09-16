<script lang="ts">
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import RotateCcw from 'lucide-svelte/icons/rotate-ccw';

	const props = $props<{
		label: string;
		color: string;
		worksCount: number;
		authorItems: { id: string; label: string; description?: string }[];
		selectedAuthors: string[];
		dateFrom: string;
		dateTo: string;
		onAuthorsChange: (ids: string[]) => void;
		onDateFromChange: (value: string) => void;
		onDateToChange: (value: string) => void;
		onReset: () => void;
	}>();

	const filtered = $derived(
		props.selectedAuthors.length > 0 || props.dateFrom.length > 0 || props.dateTo.length > 0
	);
</script>

<section
	class="border border-[color:var(--border)] border-l-4 bg-white px-4 py-4"
	style:border-left-color={props.color}
	aria-label={props.label}
>
	<div class="flex items-start justify-between gap-3">
		<div>
			<h3 class="font-semibold">{props.label}</h3>
			<p class="mt-0.5 text-xs text-[color:var(--muted-foreground)]">
				{props.worksCount} {props.worksCount === 1 ? 'obra' : 'obras'} de la muestra
			</p>
		</div>
		<button
			type="button"
			class="inline-flex h-8 w-8 items-center justify-center rounded-md border border-[color:var(--border)] text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] disabled:opacity-35"
			disabled={!filtered}
			aria-label={`Restablecer ${props.label.toLocaleLowerCase('es')}`}
			title={`Restablecer ${props.label.toLocaleLowerCase('es')}`}
			onclick={props.onReset}
		>
			<RotateCcw class="h-3.5 w-3.5" aria-hidden="true" />
		</button>
	</div>

	<div class="mt-4 grid gap-3 sm:grid-cols-2">
		<label class="block min-w-0 text-xs font-semibold text-[color:var(--muted-foreground)] sm:col-span-2">
			<span>Autoría</span>
			<CheckDropdown
				class="mt-1"
				items={props.authorItems}
				selectedIds={props.selectedAuthors}
				placeholder="Todas las autorías"
				search={true}
				portal={true}
				onChange={props.onAuthorsChange}
			/>
		</label>
		<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
			<span>Desde</span>
			<input
				type="number"
				value={props.dateFrom}
				placeholder="Año"
				class="mt-1 w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-normal text-[color:var(--foreground)]"
				oninput={(event) => props.onDateFromChange(event.currentTarget.value)}
			/>
		</label>
		<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
			<span>Hasta</span>
			<input
				type="number"
				value={props.dateTo}
				placeholder="Año"
				class="mt-1 w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-normal text-[color:var(--foreground)]"
				oninput={(event) => props.onDateToChange(event.currentTarget.value)}
			/>
		</label>
	</div>

	<p class="mt-3 text-xs leading-5 text-[color:var(--muted-foreground)]">
		{filtered ? 'Los filtros se aplican dentro de la muestra activa.' : 'Sin filtros: coincide con toda la muestra activa.'}
	</p>
</section>
