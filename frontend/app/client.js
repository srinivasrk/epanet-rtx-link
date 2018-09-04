import { init } from 'sapper/runtime.js';
import { routes } from './manifest/client.js';
import { manifest } from './manifest/client.js';

init({
	target: document.querySelector('#sapper'),
	manifest
});
