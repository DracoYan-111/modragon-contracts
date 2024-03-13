import { ethers } from "ethers-v5";
import { MerkleTree } from "merkletreejs";

const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

const inputs = [
  {
    address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    quantity: [1, 2, 3, 4],
  },
  {
    address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    quantity: [5, 6, 7],
  },
  {
    address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    quantity: [8, 9],
  },
];


const leaves = inputs.map((x) =>
  ethers.utils.solidityKeccak256(
    ["address", "uint256[]"],
    [x.address, x.quantity],
  ),
);

// create a Merkle Tree using keccak256 hash function
const tree = new MerkleTree(leaves, ethers.utils.keccak256, { sort: true });

// get the root
const root = tree.getHexRoot();
const proofs = leaves.map((leaf) => tree.getHexProof(leaf));

console.log(`Merkle Root:${GREEN}${root}${RESET}\n`);
console.log(proofs);
