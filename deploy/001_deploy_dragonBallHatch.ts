import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { keccak256, stringToBytes, encodeFunctionData } from "viem";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  console.log(deployer)
  /**
    address _initialOwner,
   */
  const args = [
    deployer
  ];

  let contract = await deploy('DragonBallHatch', {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    proxy: {
      //checkProxyAdmin:false,
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      upgradeFunction: {
        methodName: "upgradeToAndCall",
        upgradeArgs: ['{implementation}', '{data}']
      },
      execute: {
        init: {
          methodName: 'initialize',
          args: args,
        },
      },
    },
    deterministicDeployment: keccak256(stringToBytes('DragonBallHatch_PROD')),
  });

  // TODO If you want to cancel "verification", please enable comments
  // console.log(
  //   "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
  // );

  // await delay(30000); // Wait for 30 seconds before verifying the contract

  // const data = encodeFunctionData({
  //   abi: contractData.abi,
  //   functionName: 'initialize',
  //   args: args
  // })

  // await hre.run("verify:verify", {
  //   address: contract.address,
  //   constructorArguments: [contract.address, data],
  // });
};
export default func;
func.id = "001_deploy_dragonBallHatch"; // id required to prevent reexecution
func.tags = ["DragonBallHatch"];
