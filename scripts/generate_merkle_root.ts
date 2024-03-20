import fs from "fs";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// ============== Building a Tree ==============
const values = require("./airdrop.json");

const tree = StandardMerkleTree.of(values, ["uint256", "address", "uint256[]", "uint256[]"]);

const treeDataWithRoot = {
  root: tree.root,
  tree: tree.dump()
};

// write to file
require("fs").writeFileSync("./tree.json", JSON.stringify(treeDataWithRoot));



// ============== Obtaining a Proof ==============
const trees = StandardMerkleTree.load(JSON.parse(fs.readFileSync("./tree.json", "utf8")).tree);

const checkUserAddress = '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db'
for (const [i, v] of trees.entries()) {
  if (v[1] === checkUserAddress) {
    const proof = trees.getProof(i);
    console.log('Value:', v);
    console.log('Proof:', proof);
  }
}
