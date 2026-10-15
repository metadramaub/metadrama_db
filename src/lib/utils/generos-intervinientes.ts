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
