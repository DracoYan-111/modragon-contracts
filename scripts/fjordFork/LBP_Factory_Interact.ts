import hre from "hardhat";
import { utils } from "ethers-v5";
import { ethers } from "hardhat";
import { PoolSettingsStruct } from "../../typechain-types/contracts/src/fjordFork/LiquidityBootstrapPoolFactory";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

async function main() {
  // ========== Need to check data ==========
  // 0x9e101C58B10dFf2Ff6e4509D774849c1A296a65a new
  // 0x9b1904202C0EED6104cb92F61e990d384144277C old
  // 0x6E25b942c4536451512C8d3fCFCa390Efb7d1B33 MBTC
  // 0xa1e8312144A51aDc8413082D2703c86E0cAA04f7 MDBL
  const factoryAddress = "0x9e101C58B10dFf2Ff6e4509D774849c1A296a65a";

  const MBTCAddress = "0x6E25b942c4536451512C8d3fCFCa390Efb7d1B33";
  const MDBLAddress = "0xa1e8312144A51aDc8413082D2703c86E0cAA04f7";
  const manager = "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003";
  const startTime = 1711682637;
  const endTime = startTime + (86400 * 10);

  const MDBLAmount = ethers.parseEther("1449000000");
  const MBTCAmount = ethers.parseEther("3");
  // ================================

  console.log("================= Create =================");
  const liquidityBootstrapPoolFactory = await hre.ethers.getContractAt(
    "LiquidityBootstrapPoolFactory",
    factoryAddress,
  );

  const pool: PoolSettingsStruct = {
    asset: MBTCAddress,
    share: MDBLAddress,
    creator: manager,
    virtualAssets: 0,
    virtualShares: 0,
    maxSharePrice: "309485009821345068724781055",
    maxSharesOut: "309485009821345068724781055",
    maxAssetsIn: "309485009821345068724781055",
    weightStart: ethers.parseEther("0.05"),
    weightEnd: ethers.parseEther("0.5"),
    saleStart: startTime,
    saleEnd: endTime,
    vestCliff: 0,
    vestEnd: 0,
    sellingAllowed: true,
    whitelistMerkleRoot:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
  };

  const createPoolTx =
    await liquidityBootstrapPoolFactory.createLiquidityBootstrapPool(
      pool,
      MDBLAmount,
      MBTCAmount,
      utils.solidityKeccak256(["string"], [pool]),
    );

  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${createPoolTx.hash}${RESET}\n`,
  );
  console.log("Waiting until the transaction is confirmed...\n");

  const buyReceipt = await createPoolTx.wait();

  console.log(
    "The transaction returned the following transaction receipt:\n",
    buyReceipt?.logs,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
