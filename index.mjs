import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

// Nested fxn defs here create ability to bet on rps, tokenizing our app
const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

// these must be order dependent due to future modulo arithmetic for outcome var
const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins!', 'Draw!', 'Alice wins!'];

// constructor for Player implementation
const Player = (Who) => ({
    ...stdlib.hasRandom,
    getHand: () => {
        const hand = Math.floor(Math.random() * 3);
        console.log(`${Who} played ${HAND[hand]}`);
        return hand;
    },
    seeOutcome: (outcome) => {
        console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
    },
});

// FE part
await Promise.all([
    ctcAlice.p.Alice({
        // Alice, bob inheriting Player interface
        ...Player('Alice'), 
        wager: stdlib.parseCurrency(5), // wager def, 5 units of the network token
    }),
    ctcBob.p.Bob({
        ...Player('Bob'), // instantiates implementation 1x for Alice
        // immediately accepting wager by returning
        acceptWager: (amt) => {
            console.log(`Bob accepts the wager of ${fmt(amt)}.`);
        },
    }),
]);

// gets balances post A + B wager interaction
const afterAlice = await getBalance(accAlice);
const afterBob = await getBalance(accBob);

// Summary of wager dynamics
console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went fro ${beforeBob} to ${afterBob}.`);
