pragma circom 2.0.0;
// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindVariation() {
    //implementation of Bagels
    signal input pubGuess1;
    signal input pubGuess2;
    signal input pubGuess3;
    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolHash;

    signal input privSol1;
    signal input privSol2;
    signal input privSol3;
    signal input privSalt;

    signal output solHashOut;

    var guess[3] = [pubGuess1, pubGuess2, pubGuess3];
    var sol[3] = [privSol1, privSol2, privSol3];
    var j;
    component lessThan[6];
    component greaterThan[6];

    for(j=0; j<3; j++) {
        // both guess and solution digits must be between 1 and 10
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 11;
        lessThan[j].out === 1;
        lessThan[j+3] = LessThan(4);
        lessThan[j+3].in[0] <== sol[j];
        lessThan[j+3].in[1] <== 11;
        lessThan[j+3].out === 1;
        
        // both guess and solution digits must not be 0: no blanks!
        greaterThan[j] = GreaterThan(4);
        greaterThan[j].in[0] <== guess[j];
        greaterThan[j].in[1] <== 0;
        greaterThan[j].out === 1;
        greaterThan[j+3] = GreaterThan(4);
        greaterThan[j+3].in[0] <== sol[j];
        greaterThan[j+3].in[1] <== 0;
        greaterThan[j+3].out === 1;
    }

    // now we can count hit and blows
    var k;
    var hit = 0;
    var blow = 0;
    component equalHB[9];

    for (j=0; j<3; j++) {
        for (k=0; k<3; k++) {
            equalHB[3*j+k] = IsEqual();
            equalHB[3*j+k].in[0] <== sol[j];
            equalHB[3*j+k].in[1] <== guess[k];
            if (j == k) {
                hit += equalHB[3*j+k].out;
            } else {
                blow += equalHB[3*j+k].out;
            }
        }
    }

    // constraint for hits
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // constraint for blows
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolHash
    component poseidon = Poseidon(4);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSol1;
    poseidon.inputs[2] <== privSol2;
    poseidon.inputs[3] <== privSol3;

    solHashOut <== poseidon.out;
    pubSolHash === solHashOut;
}

component main {public [pubGuess1, pubGuess2, pubGuess3, pubNumBlow, pubNumHit, pubSolHash]} = MastermindVariation();