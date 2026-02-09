import { writable } from 'svelte/store';

export interface ToastMessage {
	id: number;
	type: 'success' | 'error' | 'info';
	message: string;
}

const { subscribe, update } = writable<ToastMessage[]>([]);
let nextId = 1;

export const toastStore = { subscribe };

export function pushToast(type: ToastMessage['type'], message: string, duration = 2500) {
	const id = nextId++;
	update((messages) => [...messages, { id, type, message }]);
	setTimeout(() => dismissToast(id), duration);
}

export function dismissToast(id: number) {
	update((messages) => messages.filter((message) => message.id !== id));
}
