import { promises } from "dns";
import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

const userAddress = "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003";
//0xDD3c55F135891da82Ae8Fcd6A845618fc075eA11 今天7.30
//0x43Aa91e0008dC9B15CCc2CB9447e2111bc3Af447 48小时
const poolAddress = "0x632C64e633330D2aBe7A4BcF7eE11daB380F127C";
const MBTCAddress = "0x3c6585b5DCA5FDb13D47762E0E1F6A89f21d47F4";
const MDBLAddress = "0x916Ea155AE62f7EC989506e0e257959BFe006c07";
let liquidityBootstrapPool: any;
let MBTC: any;
let MDBL: any;

async function callBuy() {
  console.log(await liquidityBootstrapPool.totalPurchased());

  const buyTx = await liquidityBootstrapPool.swapExactAssetsForShares(
    ethers.parseEther("0.5"),
    0,
    userAddress,
  );
  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${buyTx.hash}${RESET}\n`,
  );
}

async function callSell() {
  const userAmout = ethers.parseEther("1");
  console.log(userAmout);

  const sellAmout = await liquidityBootstrapPool.previewAssetsOut(userAmout);
  console.log(sellAmout);

  const sellTx = await liquidityBootstrapPool.swapExactSharesForAssets(
    userAmout,
    sellAmout,
    userAddress,
  );
  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${sellTx.hash}${RESET}\n`,
  );
}
async function getContracts() {
  MBTC = await hre.ethers.getContractAt("TestNFT", MBTCAddress);
  MDBL = await hre.ethers.getContractAt("TestNFT", MDBLAddress);
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
  // for (let i = 0; i < 30; i++) {
  //   console.log(await liquidityBootstrapPool.args());
  // }

  // console.log(await liquidityBootstrapPool.previewSharesOut(100000));
  // console.log(await liquidityBootstrapPool.reservesAndWeights());
  // const MDBLPrice = await liquidityBootstrapPool.previewAssetsIn(
  //   ethers.parseEther("5"),
  // );
  // console.log(MDBLPrice);
  // console.log(await liquidityBootstrapPool.args());
  //console.log(await liquidityBootstrapPool.reservesAndWeights());

  // console.log("================= Buy =================");
  // for (let i = 0; i < 5; i++) {
  //   console.log(
  //     await liquidityBootstrapPool.totalReferred());
  //   await callBuy();
  // }

  // console.log("================= Sell =================");
  // for (let i = 0; i < 1; i++) {
  //   await callSell();
  // }

  // console.log("================= Close =================");

  // console.log(await liquidityBootstrapPool.closed());
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

  // console.log("================= RedeemOpen =================");

  // console.log(await liquidityBootstrapPool.redeemOpen());
  // const redeemOpenTx = await liquidityBootstrapPool.toggleRedeemOpen();
  // console.log(
  //   "The transaction hash is: " +
  //     `${GREEN}https://testnet-scan.merlinchain.io/tx/${redeemOpenTx.hash}${RESET}\n`,
  // );
  // console.log("Waiting until the transaction is confirmed...\n");
  // const redeemOpenReceipt = await redeemOpenTx.wait();
  // console.log(
  //   "The transaction returned the following transaction receipt:\n",
  //   redeemOpenReceipt,
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

  console.log("================= Pause =================");
  const pauseTx = await liquidityBootstrapPool.togglePause();
  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${pauseTx.hash}${RESET}\n`,
  );
  console.log("Waiting until the transaction is confirmed...\n");
  const pauseTxReceipt = await pauseTx.wait();
  console.log(
    "The transaction returned the following transaction receipt:\n",
    pauseTxReceipt,
  );

  // console.log("================= Test =================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
