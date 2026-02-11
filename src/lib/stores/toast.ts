import { writable } from 'svelte/store';

export interface ToastMessage {
	id: number;
	type: 'success' | 'error' | 'info';
	message: string;
	actionLabel?: string;
	onAction?: () => void;
}

const { subscribe, update } = writable<ToastMessage[]>([]);
let nextId = 1;

export const toastStore = { subscribe };

export function pushToast(
	type: ToastMessage['type'],
	message: string,
	duration = 2500,
	options?: { actionLabel?: string; onAction?: () => void }
) {
	const id = nextId++;
	update((messages) => [
		...messages,
		{
			id,
			type,
			message,
			actionLabel: options?.actionLabel,
			onAction: options?.onAction
		}
	]);
	setTimeout(() => dismissToast(id), duration);
}

export function runToastAction(id: number) {
	let callback: (() => void) | undefined;
	update((messages) => {
		const item = messages.find((message) => message.id === id);
		callback = item?.onAction;
		return messages.filter((message) => message.id !== id);
	});
	callback?.();
}

export function dismissToast(id: number) {
	update((messages) => messages.filter((message) => message.id !== id));
}
