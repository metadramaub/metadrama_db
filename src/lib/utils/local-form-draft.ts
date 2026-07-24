const LOCAL_DRAFT_PREFIX = 'metadrama:form-draft:v1';
const LOCAL_DRAFT_VERSION = 1;

export type LocalFormDraft<T> = {
	version: typeof LOCAL_DRAFT_VERSION;
	savedAt: string;
	value: T;
};

function storageAvailable(): boolean {
	return typeof window !== 'undefined';
}

export function buildLocalDraftKey(parts: string[]): string {
	return [LOCAL_DRAFT_PREFIX, ...parts.map((part) => encodeURIComponent(part))].join(':');
}

export function readLocalDraft<T>(key: string): LocalFormDraft<T> | null {
	if (!storageAvailable()) return null;

	try {
		const raw = window.localStorage.getItem(key);
		if (!raw) return null;
		const parsed = JSON.parse(raw) as Partial<LocalFormDraft<T>>;
		if (
			parsed.version !== LOCAL_DRAFT_VERSION ||
			typeof parsed.savedAt !== 'string' ||
			!('value' in parsed)
		) {
			return null;
		}
		return parsed as LocalFormDraft<T>;
	} catch {
		return null;
	}
}

export function writeLocalDraft<T>(key: string, value: T): void {
	if (!storageAvailable()) return;

	try {
		const draft: LocalFormDraft<T> = {
			version: LOCAL_DRAFT_VERSION,
			savedAt: new Date().toISOString(),
			value
		};
		window.localStorage.setItem(key, JSON.stringify(draft));
	} catch {
		// El formulario sigue protegido por los avisos aunque el almacenamiento local no esté disponible.
	}
}

export function removeLocalDraft(key: string): void {
	if (!storageAvailable()) return;

	try {
		window.localStorage.removeItem(key);
	} catch {
		// Sin acción: localStorage puede estar bloqueado por el navegador.
	}
}

export function createLocalDraftWriter(delayMs = 300) {
	let timer: ReturnType<typeof setTimeout> | null = null;
	let pending: { key: string; value: unknown } | null = null;

	function cancel() {
		if (timer) clearTimeout(timer);
		timer = null;
		pending = null;
	}

	function flush() {
		if (timer) clearTimeout(timer);
		timer = null;
		if (!pending) return;
		writeLocalDraft(pending.key, pending.value);
		pending = null;
	}

	function schedule<T>(key: string, value: T) {
		if (timer) clearTimeout(timer);
		pending = { key, value };
		timer = setTimeout(flush, delayMs);
	}

	return { schedule, flush, cancel };
}
