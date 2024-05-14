import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { keccak256, stringToBytes, encodeFunctionData } from "viem";


const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  /**
   *address initialOwner_
   *IERC721 _erc721Address
   */
  const args = [
    0x3e8B6e286f78B13C35E11d567935c3aFEECb9003,
    0x84AfCd5406365368A41e269CD6467CD1B8D96F13,
  ];

  let contract = await deploy('BatchBurnERC721', {
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
    deterministicDeployment: keccak256(stringToBytes('BatchBurnERC721_PRUD')),
  });
  // // TODO If you want to cancel "verification", please enable comments
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
func.id = "001_deploy_batchBurnERC721"; // id required to prevent reexecution
func.tags = ["BatchBurnERC721"];
