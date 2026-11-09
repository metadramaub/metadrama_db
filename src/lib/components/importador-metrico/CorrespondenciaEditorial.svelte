<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

	// Aparece cuando una fila llegó sin identificar y quien importa ya le ha puesto forma.
	type Procedencia = { edicion: string | null; obra: string; fila: string; foto: string | null; pagina: number | null };
	let { literal, forma, arquitectura, formaNombre, arquitecturaNombre, procedencia } = $props<{
		literal: string;
		forma: string;
		arquitectura: string | null;
		formaNombre: string;
		arquitecturaNombre: string | null;
		procedencia: Procedencia;
	}>();

	let mensaje = $state('');
	let ocupado = $state(false);
	let registrada = $state('');
	const destino = $derived(`${forma}/${arquitectura ?? ''}`);

	async function registrar() {
		ocupado = true;
		mensaje = '';
		try {
			const r = await fetch('/api/importador/correspondencias', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ literal, forma, arquitectura, procedencia })
			});
			const d = await r.json().catch(() => ({}));
			if (!r.ok) throw new Error(d.message ?? 'No se pudo registrar.');
			registrada = destino;
			mensaje = 'Registrada. Se propondrá cuando este término vuelva a llegar sin identificar.';
		} catch (e) {
			mensaje = e instanceof Error ? e.message : 'No se pudo registrar.';
		} finally {
			ocupado = false;
		}
	}
</script>

<div class="space-y-2 border-t border-[color:var(--border)] pt-3 text-sm">
	<p>
		«{literal}» llegó sin identificar. Si esta identificación vale siempre para ese término, regístrala:
		el importador la propondrá en las próximas obras.
	</p>
	<Button variant="secondary" disabled={ocupado || registrada === destino} onclick={registrar}>
		Identificar siempre «{literal}» como {formaNombre}{arquitecturaNombre ? ' · ' + arquitecturaNombre : ''}
	</Button>
	{#if mensaje}<p role="status">{mensaje}</p>{/if}
</div>
