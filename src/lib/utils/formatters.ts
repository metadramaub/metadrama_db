import { formatDistanceToNowStrict } from 'date-fns';
import { es } from 'date-fns/locale';

export function formatRelative(value: string | null): string {
	if (!value) {
		return 'sin fecha';
	}
	const date = new Date(value);
	if (Number.isNaN(date.valueOf())) {
		return 'sin fecha';
	}
	return `hace ${formatDistanceToNowStrict(date, { addSuffix: false, locale: es })}`;
}

export function clampPercentage(value: number): number {
	return Math.max(0, Math.min(100, Math.round(value)));
}
