'reach 0.1'; //indicates this is a reach program, top of every program

// compiler first looks at/enters in main export block
export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        // logic for Alice's interact interface here
    });
    const Bob = Participant('Bob', {
        // logic for Bob's interact interface here
    });
    init(); // deployment of the Reach program, lets program to start doing things
    // program logic here

});