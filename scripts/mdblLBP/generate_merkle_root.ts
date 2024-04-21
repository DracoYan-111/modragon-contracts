import fs from "fs";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// ============== Building a Tree ==============
const values = require("./merlinRewardMerkleData.json");

const tree = StandardMerkleTree.of(values, ["uint256", "address", "uint256"]);

const treeDataWithRoot = {
  root: tree.root,
  tree: tree.dump()
};

// write to file
require("fs").writeFileSync("./tree.json", JSON.stringify(treeDataWithRoot));



// ============== Obtaining a Proof ==============
const trees = StandardMerkleTree.load(JSON.parse(fs.readFileSync("./tree.json", "utf8")).tree);

const checkUserAddress = '0x005d4441d0fb3624DaaA372b5bfBF5eD348e49dB'
for (const [i, v] of trees.entries()) {
  if (v[1] === checkUserAddress) {
    const proof = trees.getProof(i);
    console.log('Value:', v);
    console.log('Proof:', proof);
  }
}
