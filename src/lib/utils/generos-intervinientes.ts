export const GENEROS_INTERVINIENTES = [
	{ id: 'masculino', label: 'Masculino' },
	{ id: 'femenino', label: 'Femenino' },
	{ id: 'indeterminado', label: 'Indeterminado' }
];

export function formatGenerosIntervinientes(values: readonly string[] | null | undefined): string {
	if (!values?.length) return 'Pendiente';
	return GENEROS_INTERVINIENTES.filter(({ id }) => values.includes(id))
		.map(({ label }) => label)
		.join(' + ');
}

/** El indicador de la lista sigue midiendo intervención femenina, no respuesta al campo. */
export function indicadorIntervencionFemenina(values: readonly string[] | null | undefined): {
	estado: 'si' | 'no' | 'pendiente';
	titulo: string;
} {
	if (!values?.length) return { estado: 'pendiente', titulo: 'Intervención femenina: sin responder' };
	if (values.includes('femenino')) {
		return {
			estado: 'si',
			titulo: `Intervención femenina: ${values.length === 1 ? 'exclusiva' : 'compartida'}`
		};
	}
	if (values.includes('indeterminado')) {
		return { estado: 'pendiente', titulo: 'Intervención femenina: sin determinar; hay voces de género indeterminado' };
	}
	return { estado: 'no', titulo: 'Sin intervención femenina' };
}
