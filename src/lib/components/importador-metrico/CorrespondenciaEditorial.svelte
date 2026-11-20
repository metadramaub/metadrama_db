<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

	// Aparece cuando una fila llegó sin identificar y quien importa ya le ha puesto forma.
	// Va en un recuadro propio para que no se confunda con las acciones de la secuencia
	// (dividir, unir, añadir datos): esto no cambia la ficha, enseña al importador.
	type Procedencia = { edicion: string | null; obra: string; fila: string; foto: string | null; pagina: number | null };
	let { literal, forma, arquitectura, formaNombre, arquitecturaNombre, procedencia, puedeRegistrar } = $props<{
		literal: string;
		forma: string;
		arquitectura: string | null;
		formaNombre: string;
		arquitecturaNombre: string | null;
		procedencia: Procedencia;
		puedeRegistrar: boolean;
	}>();

	let error = $state('');
	let ocupado = $state(false);
	let registrada = $state('');
	const destino = $derived(`${forma}/${arquitectura ?? ''}`);
	const hecha = $derived(registrada === destino);

	async function registrar() {
		if (!puedeRegistrar) return;
		ocupado = true;
		error = '';
		try {
			const r = await fetch('/api/importador/correspondencias', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ literal, forma, arquitectura, procedencia })
			});
			const d = await r.json().catch(() => ({}));
			if (!r.ok) throw new Error(d.message ?? 'No se pudo registrar.');
			registrada = destino;
		} catch (e) {
			error = e instanceof Error ? e.message : 'No se pudo registrar.';
		} finally {
			ocupado = false;
		}
	}
</script>

<section
	class="space-y-3 rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] p-4 text-sm"
	aria-labelledby="correspondencia-titulo"
>
	<div class="space-y-1">
		<h4 id="correspondencia-titulo" class="text-xs font-semibold uppercase tracking-wide text-[color:var(--muted-foreground)]">
			{puedeRegistrar ? 'Enseñar al importador' : 'Equivalencia para futuras importaciones'}
		</h4>
		<p class="text-[color:var(--muted-foreground)]">
			{#if puedeRegistrar}
				Registra esta identificación para que el importador la proponga en futuras obras.
			{:else}
				Puedes guardar la identificación en esta ficha. Si debe usarse en futuras importaciones,
				pídela por correo a admin o IP e indica el término literal, la edición y el destino propuesto.
			{/if}
		</p>
	</div>

	<p class="flex flex-wrap items-center gap-2" aria-label="Correspondencia que se registraría">
		<span class="rounded border border-[color:var(--border)] bg-white px-2 py-1 italic">«{literal}»</span>
		<span aria-hidden="true" class="text-[color:var(--muted-foreground)]">→</span>
		<span class="rounded border border-[color:var(--border)] bg-white px-2 py-1 font-medium">
			{formaNombre}{#if arquitecturaNombre}<span class="font-normal text-[color:var(--muted-foreground)]"> — {arquitecturaNombre}</span>{/if}
		</span>
	</p>

	{#if puedeRegistrar && hecha}
		<p role="status" class="font-medium text-[color:var(--success)]">
			✓ Registrada. Las próximas importaciones propondrán {formaNombre} para «{literal}».
		</p>
	{:else if puedeRegistrar}
		<Button variant="primary-soft" loading={ocupado} loadingLabel="Registrando…" onclick={registrar}>
			Recordar para próximas importaciones
		</Button>
	{/if}
	{#if error}<p role="alert" class="text-[color:var(--danger)]">{error}</p>{/if}
</section>
