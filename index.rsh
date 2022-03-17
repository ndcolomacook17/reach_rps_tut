'reach 0.1'; //indicates this is a reach program, top of every program

// participant interact interface shared by both players
const Player = {
    getHand: Fun([], UInt), // UInt -> unsigned int, returns num
    seeOutcome: Fun([UInt], Null), // receives num
};

// compiler first looks at/enters in main export block
export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player
    });
    const Bob = Participant('Bob', {
        ...Player
    });
    init(); // deployment of the Reach program, lets program to start doing things

    // all program logic below

    // backend for Alice interacts with its frontend, gets Alice's hand, and publishes it
    Alice.only(() => { // only alice performs this
        // declassify use -> all information from frontends is secret until it is explicitly made public
        const handAlice = declassify(interact.getHand()); // handAlice known only to alice
    });
    Alice.publish(handAlice); // publishes handAlice val to consensus network, codes in a "consensus step" after this
    // commits consensus network state, returns to "local step" -> where indiv participants can act alone
    commit();

    Bob.only(() => {
        const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob);

    // computes the outcome of the game before committing
    const outcome = (handAlice + (4 - handBob)) % 3;
    commit();

    // have each of the participants send the final outcome to their frontends
    each([Alice, Bob], () => { // local step that each of the participants performs due to using 'each'
        interact.seeOutcome(outcome);
    });
});