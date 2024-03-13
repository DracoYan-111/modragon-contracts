import { promises } from "dns";
import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

const userAddress = "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003";
const poolAddress = "0xaea262e75af4fea2628417130ee49df5ed79bc16";
const MBTCAddress = "0x3c6585b5DCA5FDb13D47762E0E1F6A89f21d47F4";
const MDBLAddress = "0x916Ea155AE62f7EC989506e0e257959BFe006c07";
let liquidityBootstrapPool: any;
let MBTC: any;
let MDBL: any;

async function callBuy() {
  const MDBLPrice = await liquidityBootstrapPool.previewAssetsIn(
    ethers.parseEther("1"),
  );
  const buyTx = await liquidityBootstrapPool.swapExactAssetsForShares(
    MDBLPrice,
    0,
    userAddress,
  );
  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${buyTx.hash}${RESET}\n`,
  );
}
async function getContracts() {
  // MBTC = await hre.ethers.getContractAt("TestNFT", MBTCAddress);
  // MDBL = await hre.ethers.getContractAt("TestNFT", MDBLAddress);
  liquidityBootstrapPool = await hre.ethers.getContractAt(
    "LiquidityBootstrapPool",
    poolAddress,
  );
}

async function main() {
  await getContracts();
  // console.log("================= Approve =================");
  // const MBTCapprove = await MBTC.approve(poolAddress, ethers.parseEther("999999999"));
  // console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MBTCapprove.hash}${RESET}\n`);
  // const MDBLapprove = await MDBL.approve(poolAddress, ethers.parseEther("999999999"));
  // console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MDBLapprove.hash}${RESET}\n`);

  // console.log("================= View =================");
  // console.log(
  //   await liquidityBootstrapPool.previewAssetsIn(ethers.parseEther("1")),
  // );
  // console.log(await liquidityBootstrapPool.previewSharesIn(100000));
  // console.log(await liquidityBootstrapPool.previewSharesOut(100000));
  // console.log(await liquidityBootstrapPool.reservesAndWeights());
  // const MDBLPrice = await liquidityBootstrapPool.previewAssetsIn(
  //   ethers.parseEther("5"),
  // );
  // console.log(MDBLPrice);
  // console.log(await liquidityBootstrapPool.args());
  // console.log(await liquidityBootstrapPool.reservesAndWeights());

  for (let i = 0; i < 20; i++) {
    console.log("================= Buy =================");
    await callBuy(); //Promise.all([callBuy, callBuy, callBuy, callBuy]); callBuy()
  }
  // console.log("Waiting until the transaction is confirmed...\n");
  // const buyReceipt = await buyTx.wait();
  // console.log(
  //   "The transaction returned the following transaction receipt:\n",
  //   buyReceipt,
  // );

  //   console.log("================= Sell =================");
  //   const userShares = await liquidityBootstrapPool.purchasedShares(
  //     "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
  //   );
  //   console.log(userShares);

  //   const sellTx = await liquidityBootstrapPool.swapExactSharesForAssets(
  //     userShares,
  //     0,
  //     userAddress,
  //   );
  //   console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${sellTx.hash}${RESET}\n`);
  //   console.log("Waiting until the transaction is confirmed...\n");
  //   const sellReceipt = await sellTx.wait();
  //   console.log(
  //     "The transaction returned the following transaction receipt:\n",
  //     sellReceipt,
  //   );

  // console.log("================= Close =================");
  // const closeTx = await liquidityBootstrapPool.close();
  // console.log(
  //   "The transaction hash is: " +
  //     `${GREEN}https://testnet-scan.merlinchain.io/tx/${closeTx.hash}${RESET}\n`,
  // );
  // console.log("Waiting until the transaction is confirmed...\n");
  // const closeReceipt = await closeTx.wait();
  // console.log(
  //   "The transaction returned the following transaction receipt:\n",
  //   closeReceipt,
  // );

  // console.log("================= Redeem =================");
  // const redeemTx = await liquidityBootstrapPool.redeem(userAddress, false);
  // console.log(
  //   "The transaction hash is: " +
  //     `${GREEN}https://testnet-scan.merlinchain.io/tx/${redeemTx.hash}${RESET}\n`,
  // );
  // console.log("Waiting until the transaction is confirmed...\n");
  // const redeemReceipt = await redeemTx.wait();
  // console.log(
  //   "The transaction returned the following transaction receipt:\n",
  //   redeemReceipt,
  // );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
