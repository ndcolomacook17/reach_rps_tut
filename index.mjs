import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend);

// these must be order dependent due to future modulo arithmetic for outcome var
const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins!', 'Draw!', 'Alice wins!'];

// constructor for Player implementation
const Player = (Who) => ({
    getHand: () => {
        const hand = Math.floor(Math.random() * 3);
        console.log(`${Who} played ${HAND[hand]}`);
        return hand;
    },
    seeOutcome: (outcome) => {
        console.log(`${Who} saw outcome ${OUTCOME[outcome]}`)
    },
});

await Promise.all([
    ctcAlice.p.Alice({
        ...Player('Alice'), // instantiates implementation 1x for Alice
    }),
    ctcBob.p.Bob({
        ...Player('Bob'), // instantiates implementation 1x for Alice
    }),
]);