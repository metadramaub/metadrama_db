/** Compatibilidad con la base anterior, que todavía no tiene tipo_ficha. */
export function esFichaBasica(obra: object): boolean {
	return 'tipo_ficha' in obra && obra.tipo_ficha === 'minima';
}
