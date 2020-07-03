import { Joystick } from 'love.joystick';

export interface PlayerConfig {
	controls: { [key: string]: string[] };
	pairs?: { [key: string]: string[] };
	joystick?: Joystick;
	deadzone?: number;
	squareDeadzone?: boolean;
}

export interface Player {
	config: PlayerConfig;
	update: () => void;
	/** @tupleReturn */
	getRaw: (name: string) => [number, number];
	/** @tupleReturn */
	get: (name: string) => [number, number];
	down: (name: string) => boolean;
	pressed: (name: string) => boolean;
	released: (name: string) => boolean;
	getActiveDevice: () => 'kbm' | 'joy' | 'none';
}

export function newPlayer(this: void, options: PlayerConfig): Player;
