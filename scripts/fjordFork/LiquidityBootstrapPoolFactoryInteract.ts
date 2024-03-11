import hre from "hardhat";
import { ethers } from "hardhat";
import { PoolSettingsStruct } from "../../typechain-types/contracts/src/fjordFork/LiquidityBootstrapPoolFactory";

// Colour codes for terminal prints
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";

async function main() {
  const address = "0x0bE448bF9f50690DDAb1a6A7D9A6D937dC2DA19c";
  const liquidityBootstrapPoolFactory = await hre.ethers.getContractAt(
    "LiquidityBootstrapPoolFactory",
    address,
  );

  console.log("================= Create =================");

  const pool: PoolSettingsStruct = {
    asset: "0x3c6585b5DCA5FDb13D47762E0E1F6A89f21d47F4",
    share: "0x916Ea155AE62f7EC989506e0e257959BFe006c07",
    creator: "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
    virtualAssets: 0,
    virtualShares: Date.parse(new Date().toString()) / 1000 + 86400 * 5,
    maxSharePrice: "309485009821345068724781055",
    maxSharesOut: "309485009821345068724781055",
    maxAssetsIn: "309485009821345068724781055",
    weightStart: ethers.parseEther("0.05"),
    weightEnd: ethers.parseEther("0.5"),
    saleStart: Date.parse(new Date().toString()) / 1000 + 2000,
    saleEnd: Date.parse(new Date().toString()) / 1000 + 86400 * 5,
    vestCliff: 0,
    vestEnd: 0,
    sellingAllowed: true,
    whitelistMerkleRoot:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
  };

  const createPoolTx =
    await liquidityBootstrapPoolFactory.createLiquidityBootstrapPool(
      pool,
      ethers.parseEther("2100000000"),
      ethers.parseEther("3"),
      "0x5683725624587456346234573542634567300000000000000000000000000000",
    );
    
  console.log(
    "The transaction hash is: " +
      `${GREEN}https://testnet-scan.merlinchain.io/tx/${createPoolTx.hash}${RESET}\n`,
  );
  console.log("Waiting until the transaction is confirmed...\n");
  const buyReceipt = await createPoolTx.wait();
  console.log(
    "The transaction returned the following transaction receipt:\n",
    buyReceipt,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
