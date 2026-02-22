<script lang="ts">
	import { renderMarkdown } from '$lib/utils/markdown';
	import type { SequenceModalPayload } from '$lib/types/public-ficha.types';

	const props = $props<{
		open: boolean;
		secuencia: SequenceModalPayload | null;
		index: number;
		total: number;
		canPrev: boolean;
		canNext: boolean;
		onClose: () => void;
		onPrev: () => void;
		onNext: () => void;
	}>();

	$effect(() => {
		if (!props.open) return;
		const handleEscape = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') return;
			props.onClose();
		};
		document.addEventListener('keydown', handleEscape);
		return () => {
			document.removeEventListener('keydown', handleEscape);
		};
	});
</script>

{#if props.open && props.secuencia}
	<div class="fixed inset-0 z-[120]">
		<button
			type="button"
			class="absolute inset-0 bg-black/40"
			aria-label="Cerrar detalle de secuencia"
			onclick={props.onClose}
		></button>

		<div class="absolute inset-x-4 top-6 bottom-6 overflow-y-auto border border-[color:var(--border)] bg-white p-4 md:inset-x-16 md:p-6 lg:inset-x-28">
			<div class="mb-4 flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] pb-3">
				<div>
					<h2 class="text-lg font-semibold">
						Secuencia {props.index + 1} de {props.total}
					</h2>
					<p class="text-sm text-[color:var(--muted-foreground)]">
						Versos {props.secuencia.v_ini}-{props.secuencia.v_fin}
					</p>
				</div>
				<div class="flex items-center gap-2">
					<button
						type="button"
						class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold"
						disabled={!props.canPrev}
						onclick={props.onPrev}
					>
						Anterior
					</button>
					<button
						type="button"
						class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold"
						disabled={!props.canNext}
						onclick={props.onNext}
					>
						Siguiente
					</button>
					<button
						type="button"
						class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-2 py-1 text-xs font-semibold text-white"
						onclick={props.onClose}
					>
						Cerrar
					</button>
				</div>
			</div>

			<div class="grid gap-4 md:grid-cols-2">
				<article class="card p-4">
					<h3 class="mb-2 text-base font-semibold">Datos base</h3>
					<div class="space-y-1 text-sm">
						<p><strong>Estrofa:</strong> {props.secuencia.estrofa_tipo_term}</p>
						<p><strong>Forma base:</strong> {props.secuencia.estrofa_forma_term}</p>
						<p><strong>Nº de versos:</strong> {props.secuencia.n_versos}</p>
						<p><strong>Jornada:</strong> {props.secuencia.jornada_num ?? '--'}</p>
						<p><strong>Cuadro:</strong> {props.secuencia.cuadro_num ?? '--'}</p>
						<p><strong>Inaugura espacio:</strong> {props.secuencia.inaugura_espacio ? 'Sí' : 'No'}</p>
						<p><strong>Versos partidos:</strong> {props.secuencia.versos_partidos ? 'Sí' : 'No'}</p>
					</div>
				</article>

				<article class="card p-4">
					<h3 class="mb-2 text-base font-semibold">Caracterización</h3>
					<div class="space-y-1 text-sm">
						<p><strong>Género de personajes:</strong> {props.secuencia.personajes_genero}</p>
						<p><strong>Donaire:</strong> {props.secuencia.personajes_donaire}</p>
						<p><strong>Sobrenatural:</strong> {props.secuencia.personajes_sobrenatural}</p>
					</div>
				</article>
			</div>

			<article class="card mt-4 p-4">
				<h3 class="mb-2 text-base font-semibold">Variaciones</h3>
				{#if props.secuencia.variaciones.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin variaciones registradas.</p>
				{:else}
					<div class="overflow-x-auto">
						<table class="min-w-full border-collapse text-sm">
							<thead>
								<tr class="border-b border-[color:var(--border)]">
									<th class="px-2 py-2 text-left font-semibold">Tipo</th>
									<th class="px-2 py-2 text-left font-semibold">Versos</th>
									<th class="px-2 py-2 text-left font-semibold">Observaciones</th>
								</tr>
							</thead>
							<tbody>
								{#each props.secuencia.variaciones as variacion (variacion.variacion_id)}
									<tr class="border-b border-[color:var(--border)] align-top">
										<td class="px-2 py-2">{variacion.tipo_variacion_term}</td>
										<td class="px-2 py-2">{variacion.v_ini}-{variacion.v_fin}</td>
										<td class="px-2 py-2">{variacion.observaciones?.trim() || '--'}</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</article>

			<article class="card mt-4 p-4">
				<h3 class="mb-2 text-base font-semibold">Observaciones de secuencia</h3>
				{#if (props.secuencia.observaciones ?? '').trim().length > 0}
					<div class="space-y-2 text-sm">{@html renderMarkdown(props.secuencia.observaciones ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin observaciones públicas.</p>
				{/if}
			</article>
		</div>
	</div>
{/if}
