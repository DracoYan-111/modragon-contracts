import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const [owner, account] = await ethers.getSigners();

  const constructorArgs = ["tokenUri", owner.address, account.address];
  const contract = await hre.ethers.deployContract("/contracts/src/modragon/MoDragonContract.sol:MoDragonContract", constructorArgs);

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log("Greeter deployed to: " + `${GREEN}${contractAddress}${RESET}\n`);

  // TODO Uncomment if you want to enable the `verify`
  // console.log(
  //   "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
  // );
  // await delay(30000); // Wait for 30 seconds before verifying the contract

  // await hre.run("verify:verify", {
  //   address: contractAddress,
  //   constructorArguments: constructorArgs,
  // });

  // TODO Uncomment if you want to enable the `tenderly` extension
  // await hre.tenderly.verify({
  //   name: "Greeter",
  //   address: contractAddress,
  // });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
