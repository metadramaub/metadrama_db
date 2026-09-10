<script lang="ts">
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import NullableBooleanChoice from '$lib/components/ui/nullable-boolean-choice.svelte';

	/**
	 * Lo que caracteriza a la secuencia entera y vive en su propia fila.
	 *
	 * Son dos bloques que se leen como uno: **quién habla** —si intervienen personajes femeninos,
	 * figuras de donaire o personajes sobrenaturales— y **qué le pasa al pasaje** —versos partidos,
	 * si inaugura espacio—.
	 *
	 * *La evocación métrica se fue de aquí el 7 de septiembre de 2026*: es un fenómeno enunciativo,
	 * como el canto y la prosa, y se anota por rango con ellos.
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
		evento_sobrenatural: boolean | null;
	};

	/**
	 * Lo que la obra tiene marcado que no hay, para no volver a preguntarlo aquí.
	 *
	 * Marcado, la secuencia lo enseña respondido y bloqueado, y el rótulo dice de dónde viene. Sin
	 * marcar, pregunta como siempre: que nadie lo haya mirado todavía no es una ausencia, y una obra
	 * a medias tiene que poder anotarse igual.
	 */
	type LoQueNoHay = {
		donaire: boolean;
		personajesSobrenaturales: boolean;
		eventosSobrenaturales: boolean;
	};

	const props = $props<{
		valores: CaracterizacionesValues;
		loQueNoHay: LoQueNoHay;
		readOnly?: boolean;
		/** Se avisa campo a campo; el formulario entero lo gobierna quien monta esto. */
		alCambiar: (cambio: Partial<CaracterizacionesValues>) => void;
	}>();

	const INTERVENCION_AYUDA =
		'Indica si en esta secuencia métrica interviene verbalmente un personaje de este tipo. El dato se refiere al habla dentro de la secuencia, no a la presencia escénica. Cuando la obra declara que no los hay, la respuesta viene dada y se cambia en «Datos de la obra».';

	const opcionesDeIntervencion = [
		{ id: 'sin_intervencion', label: 'Sin intervención' },
		{ id: 'exclusiva', label: 'Intervención exclusiva' },
		{ id: 'compartida', label: 'Intervención compartida' }
	];

	/**
	 * Que la pregunta venga cerrada se dice en el rótulo, no en un renglón aparte.
	 *
	 * Un aviso debajo del campo era ambiguo con dos preguntas —no decía a cuál de las dos se
	 * refería— y se salía de sitio junto a los botones del evento. En el rótulo va pegado a lo que
	 * describe, ocupa una línea que ya existe, y el dónde se cambia vive en la ayuda de la sección.
	 */
	const NOTA_NEGADO = 'declarado para toda la obra';

	// Los personajes femeninos se dan por presentes en toda obra del corpus, así que su pregunta no
	// se puede cerrar desde arriba: no lleva declaración.
	const camposDeIntervencion = [
		{ clave: 'intervencion_personajes_femeninos', etiqueta: 'Personajes femeninos', declaracion: null },
		{ clave: 'intervencion_figuras_donaire', etiqueta: 'Figuras de donaire', declaracion: 'donaire' },
		{
			clave: 'intervencion_personajes_sobrenaturales',
			etiqueta: 'Personajes sobrenaturales',
			declaracion: 'personajesSobrenaturales'
		}
	] as const;

	function negadoEnLaObra(declaracion: keyof LoQueNoHay | null) {
		return declaracion !== null && props.loQueNoHay[declaracion] === true;
	}

	/**
	 * Lo que enseña un control cerrado es la respuesta, no «pendiente».
	 *
	 * Al declarar la obra que no los hay, la base responde por sus secuencias —lo hace un
	 * disparador—, pero esta pantalla puede tener todavía en memoria la fila de antes. Enseñar
	 * «Pendiente» encima de una respuesta que ya existe es mentir sobre lo que hay guardado.
	 */
	function intervencionMostrada(campo: (typeof camposDeIntervencion)[number]) {
		if (negadoEnLaObra(campo.declaracion)) return 'sin_intervencion';
		return props.valores[campo.clave];
	}
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
				<span class="form-label">
					{campo.etiqueta}{#if negadoEnLaObra(campo.declaracion)}<span
							class="text-[color:var(--muted-foreground)] font-normal"> · {NOTA_NEGADO}</span
						>{/if}
				</span>
				<CheckDropdown
					multiple={false}
					search={false}
					allowSingleClear
					placeholder="Pendiente — seleccionar"
					items={opcionesDeIntervencion}
					disabled={props.readOnly || negadoEnLaObra(campo.declaracion)}
					selectedIds={intervencionMostrada(campo) ? [intervencionMostrada(campo) as string] : []}
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
							text="Selecciona 'Sí' si en esta secuencia hay versos partidos entre intervenciones de distintos personajes."
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
					Evento sobrenatural{#if negadoEnLaObra('eventosSobrenaturales')}<span
							class="text-[color:var(--muted-foreground)] font-normal"> · {NOTA_NEGADO}</span
						>{/if}
					<FieldHelpTooltip
						text="Selecciona 'Sí' si en esta secuencia ocurre un milagro, una aparición o una transformación. Ocurre aunque no hable ningún personaje sobrenatural. Cuando la obra declara que no los hay, la respuesta viene dada y se cambia en «Datos de la obra»."
						label="Ayuda sobre el campo Evento sobrenatural"
					/>
				</span>
			</span>
			<NullableBooleanChoice
				value={negadoEnLaObra('eventosSobrenaturales') ? false : props.valores.evento_sobrenatural}
				ariaLabel="Evento sobrenatural"
				disabled={props.readOnly || negadoEnLaObra('eventosSobrenaturales')}
				onChange={(value: boolean | null) => props.alCambiar({ evento_sobrenatural: value })}
			/>
		</div>
	</div>
</section>
