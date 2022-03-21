import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

// helper fxn for displaying currency amounts (up to 4 decimal places)
const fmt = (x) => stdlib.formatCurrency(x, 4);
// get balance of participant, display it with fmt
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
// get balance before game starts for both Alice and Bob
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

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
        console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
    },
});

await Promise.all([
    ctcAlice.p.Alice({
        ...Player('Alice'), // splices Player interface into Alice's interface
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

// gets balances post A + B interactions
const afterAlice = await getBalance(accAlice);
const afterBob = await getBalance(accBob);

// Summary of waver dynamics
console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went fro ${beforeBob} to ${afterBob}.`);
