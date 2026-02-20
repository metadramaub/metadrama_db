import { writable } from 'svelte/store';

export type SceneLoadSource = 'route' | 'internal';
export type SceneLoadToken = number;

export interface SceneLoaderState {
	visible: boolean;
	message: string;
	source: SceneLoadSource | null;
}

export interface StartSceneLoadOptions {
	delayMs?: number;
	message?: string;
}

export const SCENE_LOADER_LINES = [
	'Vanse.',
	'Vanse los otros.',
	'Salgan Lesbia y otros,',
	'Sale Marino, con la cara tiznada.',
	'Tocan al arma y vanse.',
	'Vase.',
	'(Dentro.)',
	'Sale una mujer.'
] as const;
const DEFAULT_MESSAGE = SCENE_LOADER_LINES[0];

interface SceneLoadEntry {
	id: SceneLoadToken;
	source: SceneLoadSource;
	message: string;
	useDefaultMessage: boolean;
	visible: boolean;
	timer: ReturnType<typeof setTimeout> | null;
}

const initialState: SceneLoaderState = {
	visible: false,
	message: DEFAULT_MESSAGE,
	source: null
};

const sceneLoaderWritable = writable<SceneLoaderState>(initialState);
const entries = new Map<SceneLoadToken, SceneLoadEntry>();
let nextToken = 1;
let lastSceneLineIndex = -1;

export const sceneLoaderStore = {
	subscribe: sceneLoaderWritable.subscribe
};

function resolveCustomMessage(message: string | undefined): string | null {
	const normalized = message?.trim();
	return normalized && normalized.length > 0 ? normalized : null;
}

function getRandomSceneLine(): string {
	const totalLines = SCENE_LOADER_LINES.length;

	for (let attempt = 0; attempt < 8; attempt += 1) {
		const candidate = Math.floor(Math.random() * totalLines);
		if (candidate === lastSceneLineIndex) continue;
		lastSceneLineIndex = candidate;
		return SCENE_LOADER_LINES[candidate] ?? DEFAULT_MESSAGE;
	}

	const fallback = (lastSceneLineIndex + 1) % totalLines;
	lastSceneLineIndex = fallback;
	return SCENE_LOADER_LINES[fallback] ?? DEFAULT_MESSAGE;
}

function recomputeSceneLoaderState() {
	const visibleEntries = [...entries.values()].filter((entry) => entry.visible);

	if (visibleEntries.length === 0) {
		sceneLoaderWritable.set(initialState);
		return;
	}

	const activeEntry = visibleEntries.reduce((latest, current) =>
		current.id > latest.id ? current : latest
	);

	sceneLoaderWritable.set({
		visible: true,
		message: activeEntry.message,
		source: activeEntry.source
	});
}

export function startSceneLoad(
	source: SceneLoadSource,
	options: StartSceneLoadOptions = {}
): SceneLoadToken {
	const token = nextToken++;
	const delayMs = Math.max(0, options.delayMs ?? 0);
	const customMessage = resolveCustomMessage(options.message);
	const useDefaultMessage = customMessage === null;
	const entry: SceneLoadEntry = {
		id: token,
		source,
		message: customMessage ?? (delayMs === 0 ? getRandomSceneLine() : DEFAULT_MESSAGE),
		useDefaultMessage,
		visible: delayMs === 0,
		timer: null
	};

	if (delayMs > 0) {
		entry.timer = setTimeout(() => {
			const existing = entries.get(token);
			if (!existing) return;
			if (existing.useDefaultMessage) {
				existing.message = getRandomSceneLine();
			}
			existing.visible = true;
			existing.timer = null;
			recomputeSceneLoaderState();
		}, delayMs);
	}

	entries.set(token, entry);
	recomputeSceneLoaderState();

	return token;
}

export function endSceneLoad(token: SceneLoadToken | null | undefined) {
	if (typeof token !== 'number') return;
	const entry = entries.get(token);
	if (!entry) return;

	if (entry.timer) {
		clearTimeout(entry.timer);
	}

	entries.delete(token);
	recomputeSceneLoaderState();
}

export async function runInternalSceneTransition<T>(
	task: () => T | Promise<T>,
	message?: string
): Promise<T> {
	const token = startSceneLoad('internal', { message, delayMs: 0 });
	try {
		return await task();
	} finally {
		endSceneLoad(token);
	}
}

export function prefersReducedMotion(): boolean {
	if (typeof globalThis === 'undefined' || typeof globalThis.matchMedia !== 'function') {
		return false;
	}
	try {
		return globalThis.matchMedia('(prefers-reduced-motion: reduce)').matches;
	} catch {
		return false;
	}
}

// Test-only helper to guarantee isolation across specs.
export function resetSceneLoaderForTests() {
	for (const entry of entries.values()) {
		if (entry.timer) {
			clearTimeout(entry.timer);
		}
	}
	entries.clear();
	nextToken = 1;
	lastSceneLineIndex = -1;
	sceneLoaderWritable.set(initialState);
}
