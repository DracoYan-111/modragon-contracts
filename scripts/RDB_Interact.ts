import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

const userAddress = "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003";
const contractAddress = "0xD326432566134Eb668Ed5EFE616438335187fBC5";
const BBOXAddress = "0x003a214F228A9755c296F7814B53e9b264ce40a2";
const MBOXAddress = "0xAE8c3B84BeB09d3Fa6b83e77dEF359775cF27599";
let rewardDistribution: any;
let BBOX: any;
let MBOX: any;

async function setTokenAddress(opt: any, address: any) {
    const updateTx = await rewardDistribution.updateTokenAddress(opt, address);
    console.log(
        "The transaction hash is: " +
        `${GREEN}https://testnet-scan.merlinchain.io/tx/${updateTx.hash}${RESET}\n`,
    );
}

// async function callSell() {
//   const userAmout = ethers.parseEther("1");
//   console.log(userAmout);

//   const sellAmout = await liquidityBootstrapPool.previewAssetsOut(userAmout);
//   console.log(sellAmout);

//   const sellTx = await liquidityBootstrapPool.swapExactSharesForAssets(
//     userAmout,
//     sellAmout,
//     userAddress,
//   );
//   console.log(
//     "The transaction hash is: " +
//       `${GREEN}https://testnet-scan.merlinchain.io/tx/${sellTx.hash}${RESET}\n`,
//   );
// }
async function getContracts() {
    // MBTC = await hre.ethers.getContractAt("TestNFT", MBTCAddress);
    // MDBL = await hre.ethers.getContractAt("TestNFT", MDBLAddress);
    rewardDistribution = await hre.ethers.getContractAt(
        "RewardDistribution",
        contractAddress,
    );
}

async function main() {
    await getContracts();
    // console.log("================= Approve =================");
    // const MBTCapprove = await MBTC.approve(poolAddress, ethers.parseEther("999999999"));
    // console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MBTCapprove.hash}${RESET}\n`);
    // const MDBLapprove = await MDBL.approve(poolAddress, ethers.parseEther("999999999"));
    // console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MDBLapprove.hash}${RESET}\n`);

    console.log("================= View =================");

    console.log(await rewardDistribution.isClaimed(1));
    // console.log(await liquidityBootstrapPool.previewSharesOut(100000));
    // console.log(await rewardDistribution.reservesAndWeights());
    // const MDBLPrice = await liquidityBootstrapPool.previewAssetsIn(
    //   ethers.parseEther("5"),
    // );
    // console.log(MDBLPrice);
    // console.log(await liquidityBootstrapPool.args());
    //console.log(await liquidityBootstrapPool.reservesAndWeights());

    //   console.log("================= Set token address =================");
    //   await setTokenAddress(0, BBOXAddress);
    //   await setTokenAddress(1, MBOXAddress);

      console.log("================= Set root =================");
      const updateMerkleRootTx = await rewardDistribution.updateMerkleRoot("0x9e51e7e511c23ac3830b4887aff7f2781b07445b3a8b3ccc1c7f4e886f318e40");
      console.log(
        "The transaction hash is: " +
          `${GREEN}https://testnet-scan.merlinchain.io/tx/${updateMerkleRootTx.hash}${RESET}\n`,
      );

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
    // const closeReceipt = await redeemOpenTx.wait();
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

    // console.log("================= Pause =================");
    // const pauseTx = await liquidityBootstrapPool.togglePause();
    // console.log(
    //   "The transaction hash is: " +
    //     `${GREEN}https://testnet-scan.merlinchain.io/tx/${pauseTx.hash}${RESET}\n`,
    // );
    // console.log("Waiting until the transaction is confirmed...\n");
    // const pauseTxReceipt = await pauseTx.wait();
    // console.log(
    //   "The transaction returned the following transaction receipt:\n",
    //   pauseTxReceipt,
    // );

    // console.log("================= Test =================");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
