/** Evita que el espaciado (space-y), los recortes o las transformaciones de la página afecten al modal. */
export function portal(node: HTMLElement, target: HTMLElement = document.body) {
	target.appendChild(node);

	return {
		destroy() {
			if (node.parentNode === target) {
				target.removeChild(node);
			}
		}
	};
}
