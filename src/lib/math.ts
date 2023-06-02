export function average(input: any[]) {
	return input.reduce((a, b) => a + b, 0) / input.size();
}

export function percentile(arr: any[], p: number) {
	if (arr.size() === 0) return 0;

	if (p <= 0) return arr[0];
	if (p >= 1) return arr[arr.size() - 1];

	const index = (arr.size() - 1) * p;
	const lower = math.floor(index);
	const upper = lower + 1;
	const weight = index % 1;

	if (upper >= arr.size()) return arr[lower];
	return arr[lower] * (1 - weight) + arr[upper] * weight;
}
