import { pushToast } from '$lib/stores/toast';

/**
 * Copia un texto y lo avisa con un toast.
 *
 * El aviso es un toast y no un cambio en el botón: un «Copiado» que sustituye a «Copiar» cambia el
 * ancho del botón y empuja lo que tiene al lado. Sin `navigator.clipboard` (http sin TLS, algún
 * navegador viejo) se copia por el camino antiguo, seleccionando un campo oculto.
 */
export async function copiarAlPortapapeles(texto: string, aviso = 'Cita copiada'): Promise<boolean> {
	try {
		if (navigator.clipboard?.writeText) {
			await navigator.clipboard.writeText(texto);
		} else {
			const campo = document.createElement('textarea');
			campo.value = texto;
			campo.style.position = 'fixed';
			campo.style.opacity = '0';
			document.body.appendChild(campo);
			campo.select();
			document.execCommand('copy');
			campo.remove();
		}
		pushToast('success', aviso);
		return true;
	} catch (error) {
		console.error(error);
		pushToast('error', 'No se pudo copiar. Puedes seleccionar el texto y copiarlo a mano.');
		return false;
	}
}
