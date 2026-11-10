/** Compatibilidad con la base anterior, que todavía no tiene tipo_ficha. */
export function esFichaBasica(obra: object): boolean {
	return 'tipo_ficha' in obra && (obra.tipo_ficha === 'basica' || obra.tipo_ficha === 'minima');
}

export function esObraSinFicha(obra: object): boolean {
	return 'tipo_ficha' in obra && obra.tipo_ficha === 'sin_ficha';
}

export function requiereInicioCompleta(obra: object): boolean {
	return 'tipo_ficha' in obra && obra.tipo_ficha === 'completa'
		&& 'procedencia_registro' in obra && obra.procedencia_registro === 'nuevo'
		&& 'inicio_elaboracion' in obra && !obra.inicio_elaboracion;
}
