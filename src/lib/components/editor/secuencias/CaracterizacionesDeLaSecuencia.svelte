<script lang="ts">
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import NullableBooleanChoice from '$lib/components/ui/nullable-boolean-choice.svelte';

	/**
	 * Lo que caracteriza a la secuencia entera y vive en su propia fila.
	 *
	 * Son dos bloques que se leen como uno: **quién habla** —si intervienen personajes femeninos,
	 * figuras de donaire o personajes sobrenaturales— y **qué le pasa al pasaje** —versos partidos,
	 * si inaugura espacio, si el metro cambia por evocación—.
	 *
	 * **No guarda nada.** A diferencia de las caracterizaciones por rango, estos campos van en el
	 * `save()` de la secuencia junto con su rango, así que el componente solo enseña los valores y
	 * avisa de cada cambio. Quien lo monta sigue siendo el dueño del formulario, que es lo que
	 * permite que el aviso de «cambios sin guardar» siga contando lo que contaba.
	 *
	 * *Los tres campos de intervención admiten quedarse en blanco a propósito*: «pendiente» no es lo
	 * mismo que «no interviene», y la checklist de revisión distingue las dos cosas.
	 */
	type IntervencionValue = 'sin_intervencion' | 'exclusiva' | 'compartida';

	export type CaracterizacionesValues = {
		intervencion_personajes_femeninos: IntervencionValue | null;
		intervencion_figuras_donaire: IntervencionValue | null;
		intervencion_personajes_sobrenaturales: IntervencionValue | null;
		versos_partidos: boolean | null;
		inaugura_espacio: boolean | null;
		evocacion_metrica: boolean | null;
		evocacion_metrica_texto: string;
	};

	const props = $props<{
		valores: CaracterizacionesValues;
		readOnly?: boolean;
		/** Se avisa campo a campo; el formulario entero lo gobierna quien monta esto. */
		alCambiar: (cambio: Partial<CaracterizacionesValues>) => void;
	}>();

	const INTERVENCION_AYUDA =
		'Indica si en esta secuencia métrica interviene verbalmente un personaje de este tipo. El dato se refiere al habla dentro de la secuencia, no a la presencia escénica.';

	const opcionesDeIntervencion = [
		{ id: 'sin_intervencion', label: 'Sin intervención' },
		{ id: 'exclusiva', label: 'Intervención exclusiva' },
		{ id: 'compartida', label: 'Intervención compartida' }
	];

	const camposDeIntervencion = [
		{ clave: 'intervencion_personajes_femeninos', etiqueta: 'Personajes femeninos' },
		{ clave: 'intervencion_figuras_donaire', etiqueta: 'Figuras de donaire' },
		{ clave: 'intervencion_personajes_sobrenaturales', etiqueta: 'Personajes sobrenaturales' }
	] as const;
</script>

<section class="bg-white p-4">
	<h4 class="form-section-title">
		<span class="form-label-with-help">
			Intervención de personajes
			<FieldHelpTooltip
				text={INTERVENCION_AYUDA}
				label="Ayuda sobre la intervención de personajes"
			/>
		</span>
	</h4>
	<div class="grid gap-3 sm:grid-cols-2">
		{#each camposDeIntervencion as campo (campo.clave)}
			<label class="form-field">
				<span class="form-label">{campo.etiqueta}</span>
				<CheckDropdown
					multiple={false}
					search={false}
					allowSingleClear
					placeholder="Pendiente — seleccionar"
					items={opcionesDeIntervencion}
					disabled={props.readOnly}
					selectedIds={props.valores[campo.clave] ? [props.valores[campo.clave] as string] : []}
					onChange={(ids: string[]) =>
						props.alCambiar({
							[campo.clave]: (ids[0] as IntervencionValue | undefined) ?? null
						})}
				/>
			</label>
		{/each}
	</div>
</section>

<section class="bg-white p-4">
	<h4 class="form-section-title">Otras caracterizaciones</h4>
	<div class="grid gap-3 sm:grid-cols-2">
		<div class="grid grid-cols-2 gap-3 sm:col-span-2">
			<div class="form-field min-w-0">
				<span class="form-label">
					<span class="form-label-with-help">
						Versos partidos
						<FieldHelpTooltip
							text="Selecciona 'Sí' si en esta secuencia hay versos repartidos entre intervenciones de distintos personajes."
							label="Ayuda sobre el campo Versos partidos"
						/>
					</span>
				</span>
				<NullableBooleanChoice
					value={props.valores.versos_partidos}
					ariaLabel="Versos partidos"
					disabled={props.readOnly}
					onChange={(value: boolean | null) => props.alCambiar({ versos_partidos: value })}
				/>
			</div>

			<div class="form-field min-w-0">
				<span class="form-label">
					<span class="form-label-with-help">
						Inaugura espacio
						<FieldHelpTooltip
							text="Selecciona 'Sí' si coincide (de forma evidente) el inicio de esta secuencia con el cambio de espacio escénico."
							label="Ayuda sobre el campo Inaugura espacio"
						/>
					</span>
				</span>
				<NullableBooleanChoice
					value={props.valores.inaugura_espacio}
					ariaLabel="Inaugura espacio"
					disabled={props.readOnly}
					onChange={(value: boolean | null) => props.alCambiar({ inaugura_espacio: value })}
				/>
			</div>
		</div>
		<div class="form-field sm:col-span-2">
			<span class="form-label">
				<span class="form-label-with-help">
					Evocación métrica
					<FieldHelpTooltip
						text="Selecciona 'Sí' cuando el cambio de metro se deba a que un personaje adopta, imita o reproduce la voz de otro personaje."
						label="Ayuda sobre el campo Evocación métrica"
					/>
				</span>
			</span>
			<!--
				Decir que no hay evocación borra su explicación. Si no, quedaría un texto describiendo
				algo que la secuencia ya no declara, y el guardado lo enviaría igual.
			-->
			<NullableBooleanChoice
				value={props.valores.evocacion_metrica}
				ariaLabel="Evocación métrica"
				disabled={props.readOnly}
				onChange={(value: boolean | null) =>
					props.alCambiar({
						evocacion_metrica: value,
						evocacion_metrica_texto:
							value === true ? props.valores.evocacion_metrica_texto : ''
					})}
			/>
		</div>
		{#if props.valores.evocacion_metrica}
			<label class="form-field sm:col-span-2">
				<span class="form-label">Explicación de la evocación métrica</span>
				<MarkdownEditorLite
					rows={3}
					class="mt-1"
					minHeightClass="min-h-24"
					value={props.valores.evocacion_metrica_texto}
					disabled={props.readOnly}
					onChange={(siguiente: string) =>
						props.alCambiar({ evocacion_metrica_texto: siguiente })}
				/>
			</label>
		{/if}
	</div>
</section>
