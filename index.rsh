'reach 0.1';

// define enumerations for space of all hands that can be played and game outcomes
const [ isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [ isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

// winner computation
const winner = (handAlice, handBob) => ((handAlice + (4 - handBob )) % 3);

// static assertions 
assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

// Way to sort through several assertions for verification engine, these foralls are tied to asserts above
// TODO: understand this proof (works for all ints?)
forall(UInt, handAlice =>
    forall(UInt, handBob =>
        assert(isOutcome(winner(handAlice, handBob)))));

forall(UInt, (hand) =>
    assert(winner(hand, hand) == DRAW));

// participant interact interface shared by both players
const Player = {
    ...hasRandom,
    getHand: Fun([], UInt), // takes in no params, outputs int
    seeOutcome: Fun([UInt], Null) // params: int, returns Null
};

// compiler first looks at/enters in main export block
export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player, // gives access to all methods in Player
        wager: UInt,
    });
    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null), //this fxn can look at wager value
    });
    init(); // deployment of the Reach program, lets program to start doing things

    // all program logic below

    // Moves step -> local step
    Alice.only(() => { 
        const wager = declassify(interact.wager);
        const _handAlice = interact.getHand(); // _handAlice- secret var
        // salt- one way encryption, this encrypts alices data from Bob
        const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
        const commitAlice = declassify(_commitAlice);
    });

    // publishes data [wager, commitAlice] to consensus network (on blockchain)
    // moves alice step -> consensus step, alice publishes enrypted hand to show she actually played
    Alice.publish(wager, commitAlice)
        .pay(wager);
    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice));
    Bob.only(() => {
        // Bob accepts the wager here
        interact.acceptWager(wager);
        // No encryption here because Bobs hand doesn't get passed to Alice for her to process it in any way
        // No need to wrap Bobs info in a salt
        const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob)
        .pay(wager);
    commit();

    Alice.only(() => {
        const saltAlice = declassify(_saltAlice);
        const handAlice = declassify(_handAlice);
    });
    Alice.publish(saltAlice, handAlice);
    checkCommitment(commitAlice, saltAlice, handAlice); // in consensus step, stored on blockchain

    // compute amounts given to each given rps outcome
    const outcome = winner(handAlice, handBob);
    const [forAlice, forBob] = 
        outcome == A_WINS ? [2, 0] 
        : outcome == B_WINS ? [0, 2] 
        : [1, 1]; // tie
    
    //transfer takes place from the contract to the participants, not from the participants to each other, 
    // because all of the funds reside inside of the contract [in consensus step]
    transfer(forAlice * wager).to(Alice);
    transfer(forBob * wager).to(Bob);
    commit();

    // [LOCAL STEP] have each of the participants send the final outcome to their frontends
    each([Alice, Bob], () => { 
        // local step that each of the participants performs due to using 'each'
        interact.seeOutcome(outcome);
    });
});