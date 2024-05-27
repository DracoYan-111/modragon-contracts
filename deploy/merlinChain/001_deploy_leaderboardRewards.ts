import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { keccak256, stringToBytes, encodeFunctionData } from "viem";


const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  /**
        address initialOwner,
        address _signer,
        address _MDBLToken,
        address _eMDBLToken
   */
  const args = [
    deployer,
    deployer,
    deployer,
    deployer
  ];

  let contract = await deploy('LeaderboardRewards', {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    proxy: {
      checkProxyAdmin: false,
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
    deterministicDeployment: keccak256(stringToBytes('LeaderboardRewards_PRD')),
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
func.id = "001_deploy_leaderboardRewards"; // id required to prevent reexecution
func.tags = ["LeaderboardRewards"];
