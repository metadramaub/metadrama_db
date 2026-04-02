<script lang="ts">
	import type { SequenceModalPayload } from '$lib/types/public-ficha.types';
	import { renderMarkdown } from '$lib/utils/markdown';
	import type {
		ResolvedSequenceStructure,
		SequenceStructureTramo
	} from '$lib/utils/sequence-structure';

	type SequenceModalStructure = ResolvedSequenceStructure<SequenceModalPayload>;

	const props = $props<{
		open: boolean;
		secuencia: SequenceModalPayload | null;
		structure: SequenceModalStructure | null;
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

	function formatJornadaLabel() {
		if (props.structure) return props.structure.jornada.label;
		if (props.secuencia?.jornada_num !== null && props.secuencia?.jornada_num !== undefined) {
			return `Jornada ${props.secuencia.jornada_num}`;
		}
		return '--';
	}

	function formatCuadroLabel(cuadroNum: number | null) {
		return cuadroNum === null ? 'Sin cuadro' : `Cuadro ${cuadroNum}`;
	}

	function formatCuadroSummary() {
		if (props.structure) {
			if (!props.structure.spansMultipleCuadros) {
				return props.structure.startingCuadro.label;
			}

			const firstTramo = props.structure.tramos[0];
			const secondTramo = props.structure.tramos[1];
			if (firstTramo && secondTramo) {
				return `${formatCuadroLabel(firstTramo.cuadroNum)} hasta v${firstTramo.vFin}; desde v${secondTramo.vIni}, ${formatCuadroLabel(secondTramo.cuadroNum)}`;
			}

			return `${props.structure.startingCuadro.label} -> ${props.structure.endingCuadro.label}`;
		}

		if (props.secuencia?.cuadro_num !== null && props.secuencia?.cuadro_num !== undefined) {
			return formatCuadroLabel(props.secuencia.cuadro_num);
		}

		return '--';
	}

	function formatTramoLabel(tramo: SequenceStructureTramo) {
		return `${formatCuadroLabel(tramo.cuadroNum)} - vv. ${tramo.vIni}-${tramo.vFin}`;
	}
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
						<p><strong>N de versos:</strong> {props.secuencia.n_versos}</p>
						<p><strong>Jornada:</strong> {formatJornadaLabel()}</p>
						<p><strong>Cuadro:</strong> {formatCuadroSummary()}</p>
						{#if props.structure?.tramos && props.structure.tramos.length > 1}
							<div class="flex flex-wrap gap-2 pt-1">
								{#each props.structure.tramos as tramo}
									<span class="rounded-full border border-sky-200 bg-sky-50 px-2 py-1 text-xs font-medium text-sky-900">
										{formatTramoLabel(tramo)}
									</span>
								{/each}
							</div>
						{/if}
						<p><strong>Inaugura espacio:</strong> {props.secuencia.inaugura_espacio ? 'Si' : 'No'}</p>
						<p><strong>Versos partidos:</strong> {props.secuencia.versos_partidos ? 'Si' : 'No'}</p>
					</div>
				</article>

				<article class="card p-4">
					<h3 class="mb-2 text-base font-semibold">Caracterizacion</h3>
					<div class="space-y-1 text-sm">
						<p><strong>Personaje femenino:</strong> {props.secuencia.personaje_femenino}</p>
						<p><strong>Donaire:</strong> {props.secuencia.personajes_donaire}</p>
						<p><strong>Sobrenatural:</strong> {props.secuencia.personajes_sobrenatural}</p>
					</div>
				</article>
			</div>

			<article class="card mt-4 p-4">
				<h3 class="mb-2 text-base font-semibold">Caracterizaciones por rango</h3>
				{#if props.secuencia.caracterizaciones_rango.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">
						Sin caracterizaciones por rango registradas.
					</p>
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
								{#each props.secuencia.caracterizaciones_rango as caracterizacion (caracterizacion.caracterizacion_rango_id)}
									<tr class="border-b border-[color:var(--border)] align-top">
										<td class="px-2 py-2">{caracterizacion.tipo_caracterizacion_rango_term}</td>
										<td class="px-2 py-2">{caracterizacion.v_ini}-{caracterizacion.v_fin}</td>
										<td class="px-2 py-2">{caracterizacion.observaciones?.trim() || '--'}</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</article>

			<article class="card mt-4 p-4">
				<h3 class="mb-2 text-base font-semibold">Sinopsis argumental</h3>
				{#if (props.secuencia.sinopsis ?? '').trim().length > 0}
					<div class="space-y-2 text-sm">{@html renderMarkdown(props.secuencia.sinopsis ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin sinopsis argumental publicada.</p>
				{/if}
			</article>
		</div>
	</div>
{/if}
