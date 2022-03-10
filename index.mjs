import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend);

await Promise.all([
    ctcAlice.p.Alice({
        // implement Alice's interact obj here
    }),
    ctcBob.p.Bob({
        // implement Bob's interact obj here
    }),
]);