import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

async function main() {
  const address = "0xd203b1A8bca23F71970116A8059337Cbe4F4344D"; // Specify here your contract address
  const liquidityBootstrapPool = await hre.ethers.getContractAt(
    "LiquidityBootstrapPool",
    address,
  ); // Specify here your contract name

  const MDBLPrice = await liquidityBootstrapPool.previewAssetsIn(
    ethers.parseEther("1"),
  );
  console.log(MDBLPrice);

  console.log("================= Buy =================");

  const buyTx = await liquidityBootstrapPool.swapExactAssetsForShares(
    MDBLPrice,
    0,
    "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
  );
  console.log("The transaction hash is: " + `${GREEN}${buyTx.hash}${RESET}\n`);
  console.log("Waiting until the transaction is confirmed...\n");
  const buyReceipt = await buyTx.wait();
  console.log(
    "The transaction returned the following transaction receipt:\n",
    buyReceipt,
  );
  console.log("================= Sell =================");

  const userShares = await liquidityBootstrapPool.purchasedShares(
    "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
  );
  console.log(userShares);

  const sellTx = await liquidityBootstrapPool.swapExactSharesForAssets(
    userShares,
    0,
    "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
  );
  console.log("The transaction hash is: " + `${GREEN}${sellTx.hash}${RESET}\n`);
  console.log("Waiting until the transaction is confirmed...\n");
  const sellReceipt = await sellTx.wait();
  console.log(
    "The transaction returned the following transaction receipt:\n",
    sellReceipt,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
