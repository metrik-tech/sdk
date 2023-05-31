export function error(message: string) {
	error(`[METRIK SDK]: ${message}`);
}

export function warn(message: string) {
	warn(`[METRIK SDK]: ${message}`);
}

export function info(message: string) {
	print(`[METRIK SDK]: ${message}`);
}
