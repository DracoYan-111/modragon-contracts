import hre from "hardhat";
import { ethers } from "hardhat";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

const userAddress = "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003";
const contractAddress = "0x37Ce49600B3c2EFDAb159aA2F229f70c10711CaF";
const BBOXAddress = "0xB2edf746382d433Af3f03761f0E31597d2A8d82b";
const MBOXAddress = "0xED6826316a80097eEa9bcC7dD0B6fc9028B2d26d";
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
    BBOX = await hre.ethers.getContractAt("TestNFT", BBOXAddress);
    MBOX = await hre.ethers.getContractAt("TestNFT", MBOXAddress);
    rewardDistribution = await hre.ethers.getContractAt(
        "RewardDistribution",
        contractAddress,
    );
}

async function main() {
    await getContracts();
    // console.log("================= Mint =================");
    // for (let i = 0; i < 4; ++i) {
    //     const MBTCapprove = await BBOX.batchSafeMint(contractAddress, 100);
    //     console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MBTCapprove.hash}${RESET}\n`);

    //     const MDBLapprove = await MBOX.batchSafeMint(contractAddress, 100);
    //     console.log("The transaction hash is: " + `${GREEN}https://testnet-scan.merlinchain.io/tx/${MDBLapprove.hash}${RESET}\n`);

    // }

    // console.log("================= View =================");

    // console.log(await rewardDistribution.isClaimed(1));
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
    const updateMerkleRootTx = await rewardDistribution.updateMerkleRoot("0xcd823f04eda1d6350794d1962457ec929ad14a447078ec88a8d64a2924a7f7c5");
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
