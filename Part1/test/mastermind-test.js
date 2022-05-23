//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const { expect } = require("chai");
const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;

let circuit;
let poseidon;
let pubSol;

/**
 * Convert TypedArray object(like data buffer) into bigint
 * @param buf
 * @returns bigint
 */
const buf2Bigint = (buf) => {
  let bits = 8n;
  if (ArrayBuffer.isView(buf)) bits = BigInt(buf.BYTES_PER_ELEMENT * 8);
  else buf = new Uint8Array(buf);

  let ret = 0n;
  for (const i of buf.values()) {
    const bi = BigInt(i);
    ret = (ret << bits) + bi;
  }
  return ret;
};

describe("Mastermind test", function () {
  before(async function () {
    circuit = await wasm_tester(
      "contracts/circuits/MastermindVariation.circom"
    );
    await circuit.loadConstraints();

    pubSol =
      9105315672649408850949077997065108783232835693602564543549889593451668362951n;
    //console.log(pubSol);
  });

  it("should return true it result is correct", async function () {
    witness = await circuit.calculateWitness(
      {
        pubGuess1: 1,
        pubGuess2: 2,
        pubGuess3: 3,
        pubNumHit: 3,
        pubNumBlow: 0,
        pubSolHash: pubSol,
        privSol1: 1,
        privSol2: 2,
        privSol3: 3,
        privSalt: 69,
      },
      true
    );
  });

  it("should return false it result is incorrect", async function () {
    try {
      witness = await circuit.calculateWitness(
        {
          pubGuess1: 2,
          pubGuess2: 5,
          pubGuess3: 7,
          pubNumHit: 3,
          pubNumBlow: 0,
          pubSolHash: pubSol,
          privSol1: 1,
          privSol2: 2,
          privSol3: 3,
          privSalt: 69,
        },
        false
      );
    } catch (e) {
      expect(e.message).to.contain("line: 74");
    }
  });

  it("should fail if the inputs are not valid", async function () {
    try {
      witness = await circuit.calculateWitness(
        {
          pubGuess1: 0,
          pubGuess2: 2,
          pubGuess3: 11,
          pubNumHit: 3,
          pubNumBlow: 0,
          pubSolHash: pubSol,
          privSol1: 1,
          privSol2: 2,
          privSol3: 3,
          privSalt: 69,
        },
        true
      );
    } catch (e) {
      expect(e.message).to.contain("line: 44");
    }
  });
});
