export default {
	error: (message: string) => error(`[METRIK SDK]: ${message}`),
	warn: (message: string) => warn(`[METRIK SDK]: ${message}`),
	info: (message: string) => print(`[METRIK SDK]: ${message}`),
};
