const METRIC_COLOR_PALETTE = [
	'#c65f34',
	'#da8a42',
	'#b84a2c',
	'#e19a5b',
	'#a43f25',
	'#3a77a9',
	'#2d6797',
	'#25537c',
	'#4a8ebd',
	'#5ca2cf'
];

export function colorForMetricKey(key: string): string {
	if (!key) return '#9ca3af';
	let hash = 0;
	for (let i = 0; i < key.length; i += 1) {
		hash = (hash * 31 + key.charCodeAt(i)) | 0;
	}
	return METRIC_COLOR_PALETTE[Math.abs(hash) % METRIC_COLOR_PALETTE.length] ?? '#9ca3af';
}
