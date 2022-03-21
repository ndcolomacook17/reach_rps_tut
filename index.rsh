'reach 0.1'; //indicates this is a reach program, top of every program

// participant interact interface shared by both players
const Player = {
    getHand: Fun([], UInt), // UInt -> unsigned int, returns num
    seeOutcome: Fun([UInt], Null), // receives num
};

// compiler first looks at/enters in main export block
export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player,
        wager: UInt, //Int val
    });
    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null), //this fxn can look at wager value
    });
    init(); // deployment of the Reach program, lets program to start doing things

    // all program logic below

    // backend for Alice interacts with its frontend, gets Alice's hand, and publishes it
    Alice.only(() => { // only alice performs this
        // declassify use -> all information from frontends is secret until it is explicitly made public
        const wager = declassify(interact.wager);
        const handAlice = declassify(interact.getHand()); // handAlice known only to alice
    });

    // consensus network needs to be able to verify that the amount of network tokens included in Alice's publication 
    // (wager) match some computation available (.pay) to consensus network
    Alice.publish(wager, handAlice)
        .pay(wager);
    commit();

    Bob.only(() => {
        // Bob accepts the wager here
        interact.acceptWager(wager);
        const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob)
        .pay(wager);

    // computes the outcome of the game before committing
    const outcome = (handAlice + (4 - handBob)) % 3;
    // compute amounts given to each given rps outcome
    const [forAlice, forBob] = 
        outcome == 2 ? [2, 0] 
        : outcome == 0 ? [0, 2] 
        : [1, 1]; // tie
    
    // transfer takes place from the contract to the participants, not from the participants to each other, 
    // because all of the funds reside inside of the contract
    transfer(forAlice * wager).to(Alice);
    transfer(forBob * wager).to(Bob);
    commit();

    // have each of the participants send the final outcome to their frontends
    each([Alice, Bob], () => { // local step that each of the participants performs due to using 'each'
        interact.seeOutcome(outcome);
    });
});