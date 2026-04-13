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
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Vase.',
	'Desembózase.',
	'Éntrase la Sombra.',
	'Vase retirando Roldán hacia atrás y sube por la montaña como por fuerza de oculta virtud.',
	'Bajan los dos de la montaña.',
	'Canta Clori en la montaña y sale cogiendo flores.',
	'Entra Angélica alborotada.',
	'Crujidos de cadenas, ayes y suspiros dentro.',
	'Descúbrese la boca de la sierpe.',
	'Malgesí, vestido como diré, sale por la boca de la sierpe.',
	'Sale la Sospecha, con una tunicela de varias colores.',
	'Éntranse las sombras.',
	'Parece a este instante el carro de fuego, de los leones de la montaña, y en él la diosa Venus.',
	'Suena música de chirimías. Sale la nube, y en ella, el dios Cupido, vestido y con alas, flecha y arco desarmado.',
	'Vuélvese la tramoya.',
	'Vuélvese la tramoya.',
	'Vuélvese la tramoya.',
	'Vuélvese la tramoya.',
	'Éntrase Angélica huyendo.',
	'Vanse los Sátiros.',
	'Éntranse todos.',
	'Éntranse todos.',
	'Éntranse todos.',
	'Éntranse todos.',
	'Éntranse todos.',
	'Entra un Paje.',
	'Échase a dormir.',
	'Sale por lo hueco del teatro Castilla, con un león en la una mano, y en la otra un castillo.',
	'Suenan chirimías, y dase fin a la comedia.',
	'Salen don Diego, de estudiante, y don Juan, de noche',
	'Sale don Diego con un cordel',
	'Siéntase a escribir',
	'Sale don Juan con la espada desnuda',
	'Sale Andrés con un papel',
	'Salen doña Clara, con manto, y Lucía',
	'Salen el Marqués y Enrico con manteo y sotana y bonete',
	'Dale un golpe Zamudio, y señala donde le da',
	'Sale Lucía con manto y una canastilla cubierta y una bota',
	'Vanse los tres',
	'Toma Zamudio la bota, y al levantarla para beber se la toman de dentro de la peña',
	'Silban dentro',
	'Hácele en la boca a la estatua una señal, como letra, con el dedo',
	'Cierra doña Clara el cajón',
	'Abrázase con ella para forzalla',
	'Éntranse peleando',
	'Vanse. Sale don García, con prisiones',
	'Quítale las prisiones',
	'Vase el Preso primero. Sale un Preso segundo',
	'El Alcaide saca un libro lleno de pólvora; pónelo sobre un agujero pequeño del teatro',
	'Dan fuego al libro por debajo del teatro',
	'Arrodillándose',
	'Suenan cajas y clarines y sale Eneas con espada desnuda',
	'Escóndese y aparecen en lo alto entre las llamas Anquises, Creúsa y Ascanio',
	'Sale Marino de donde estaba escondido',
	'Vuelve a salir Eneas de la misma manera que antes',
	'Déjale en el suelo',
	'Vanse los dos',
	'Vanse los dos',
	'Vanse los dos',
	'Vanse los dos',
	'Cajas y clarines',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Dentro',
	'Quítale el retrato',
	'Sale un hombre con una daga desnuda',
	'Sale una mujer',
	'Lávanse las manos',
	'Levántase Dido apartando la mesa',
	'Sale Marino con trapos en la cabeza, como que está herido',
	'Sacan las espadas',
	'Riñen',
	'Riñen',
	'Riñen',
	'Tocan una caja',
	'Suena un clarín lejos',
	'Vuelve a llorar',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Vanse, y dase fin a la jornada',
	'Sale Dido vestida de gala',
	'Tocan al arma dentro',
	'Vuelve a dormirse. Cantan',
	'Vuelven a tocar al arma',
	'Ciérrase el tronco'
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
