import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  let liquidityBootstrapPoolContract = await deploy("LiquidityBootstrapPool", {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
  });

  /// @param _implementation The address of the Liquidity Bootstrap Pool implementation contract.
  /// @param _owner The owner of the factory contract.
  /// @param _feeRecipient The address that will receive platform and referrer fees.
  /// @param _platformFee The platform fee, represented as a fraction with a denominator of 10,000.
  /// @param _referrerFee The referrer fee, represented as a fraction with a denominator of 10,000.
  /// @param _swapFee The referrer fee, represented as a fraction with a denominator of 10,000.
  const args = [
    liquidityBootstrapPoolContract.address,
    deployer,
    deployer,
    0,
    0,
    0,
  ];

  let contract = await deploy("LiquidityBootstrapPoolFactory", {
    from: deployer,
    args,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
  });

  // TODO If you want to cancel "verification", please enable comments
  // console.log(
  //     "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
  //   );

  // await delay(30000); // Wait for 30 seconds before verifying the contract

  // await hre.run("verify:verify", {
  //     address: contract.address,
  //     constructorArguments: args,
  // });
};
export default func;
func.id = "001_deploy_liquidityBootstrapPoolFactory"; // id required to prevent reexecution
func.tags = ["LiquidityBootstrapPoolFactory"];
