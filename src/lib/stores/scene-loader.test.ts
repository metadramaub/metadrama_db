import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { get } from 'svelte/store';
import {
	SCENE_LOADER_LINES,
	endSceneLoad,
	prefersReducedMotion,
	resetSceneLoaderForTests,
	runInternalSceneTransition,
	sceneLoaderStore,
	startSceneLoad
} from './scene-loader';

describe('scene-loader store', () => {
	let originalMatchMedia: typeof globalThis.matchMedia | undefined;

	beforeEach(() => {
		originalMatchMedia = globalThis.matchMedia;
		vi.useFakeTimers();
		resetSceneLoaderForTests();
	});

	afterEach(() => {
		resetSceneLoaderForTests();
		vi.runOnlyPendingTimers();
		vi.useRealTimers();
		if (originalMatchMedia) {
			globalThis.matchMedia = originalMatchMedia;
		} else {
			delete (globalThis as { matchMedia?: typeof globalThis.matchMedia }).matchMedia;
		}
	});

	it('does not become visible when route navigation ends before delay', () => {
		const token = startSceneLoad('route', { delayMs: 150 });
		expect(get(sceneLoaderStore).visible).toBe(false);

		vi.advanceTimersByTime(149);
		expect(get(sceneLoaderStore).visible).toBe(false);

		endSceneLoad(token);
		vi.advanceTimersByTime(5);
		expect(get(sceneLoaderStore)).toEqual({
			visible: false,
			message: 'Vanse.',
			source: null
		});
	});

	it('becomes visible when route navigation exceeds delay', () => {
		const token = startSceneLoad('route', { delayMs: 150 });

		vi.advanceTimersByTime(151);
		const state = get(sceneLoaderStore);
		expect(state.visible).toBe(true);
		expect(state.source).toBe('route');
		expect(SCENE_LOADER_LINES).toContain(state.message);

		endSceneLoad(token);
		expect(get(sceneLoaderStore).visible).toBe(false);
	});

	it('shows immediate loading during internal transitions', async () => {
		const promise = runInternalSceneTransition(async () => {
			const state = get(sceneLoaderStore);
			expect(state.visible).toBe(true);
			expect(state.source).toBe('internal');
			expect(SCENE_LOADER_LINES).toContain(state.message);
			await Promise.resolve();
			return 'ok';
		});

		expect(get(sceneLoaderStore).visible).toBe(true);
		await expect(promise).resolves.toBe('ok');
		expect(get(sceneLoaderStore).visible).toBe(false);
	});

	it('keeps loader visible until all concurrent tokens finish', () => {
		const routeToken = startSceneLoad('route', { delayMs: 150, message: 'Cambiando pagina...' });
		const internalToken = startSceneLoad('internal', { message: 'Abriendo panel...' });

		expect(get(sceneLoaderStore)).toEqual({
			visible: true,
			message: 'Abriendo panel...',
			source: 'internal'
		});

		endSceneLoad(internalToken);
		expect(get(sceneLoaderStore).visible).toBe(false);

		vi.advanceTimersByTime(151);
		expect(get(sceneLoaderStore)).toEqual({
			visible: true,
			message: 'Cambiando pagina...',
			source: 'route'
		});

		const secondInternalToken = startSceneLoad('internal', { message: 'Vase.' });
		expect(get(sceneLoaderStore).source).toBe('internal');

		endSceneLoad(routeToken);
		expect(get(sceneLoaderStore).visible).toBe(true);
		expect(get(sceneLoaderStore).source).toBe('internal');

		endSceneLoad(secondInternalToken);
		expect(get(sceneLoaderStore).visible).toBe(false);
	});

	it('handles reduced-motion preference checks safely', () => {
		delete (globalThis as { matchMedia?: typeof globalThis.matchMedia }).matchMedia;
		expect(prefersReducedMotion()).toBe(false);

		const token = startSceneLoad('internal');
		const state = get(sceneLoaderStore);
		expect(state.visible).toBe(true);
		expect(SCENE_LOADER_LINES).toContain(state.message);
		endSceneLoad(token);
		expect(get(sceneLoaderStore).visible).toBe(false);

		globalThis.matchMedia = vi.fn().mockReturnValue({ matches: true } as MediaQueryList);
		expect(prefersReducedMotion()).toBe(true);
	});
});
