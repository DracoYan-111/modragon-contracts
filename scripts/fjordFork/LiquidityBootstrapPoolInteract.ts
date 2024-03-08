import hre from "hardhat";
import { ethers } from "hardhat";

async function main() {
    const address = "0xd203b1A8bca23F71970116A8059337Cbe4F4344D"; // Specify here your contract address
    const contract = await hre.ethers.getContractAt("LiquidityBootstrapPool", address); // Specify here your contract name


    const MDBLPrice = await contract.previewAssetsIn(ethers.parseEther("1"));

    console.log(MDBLPrice);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});