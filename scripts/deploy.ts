import hre from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  //const [owner, account] = await ethers.getSigners();

  const constructorArgs = ["tokenUri", "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"];
  const contract = await hre.ethers.deployContract("/contracts/src/drawnBringer/DrawnBringerNFT.sol:DrawnBringerNFT", constructorArgs);

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log("Greeter deployed to: " + `${GREEN}${contractAddress}${RESET}\n`);

  // TODO Uncomment if you want to enable the `verify`
  console.log(
    "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
  );
  await delay(30000); // Wait for 30 seconds before verifying the contract

  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArgs,
  });

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
