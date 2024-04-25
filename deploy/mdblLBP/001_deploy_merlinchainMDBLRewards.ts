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
    IERC20 _MDBLAddress, 
    bytes32 _receiveRoot
   */
  const args = [
    deployer,
    "0x8Aed42735027aa6d97023D8196B084eCFbA701af",
    "0xb0b5be6637cbb40bdf9d0528e1ab6100eed4b538f439e54d329c7cc85667f975",//
  ];

  let contract = await deploy('MerlinchainMDBLRewards', {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    proxy: {
      // 取消ProxyAdmin检查
      checkProxyAdmin:false,
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      // 更新合约需要被调用的方法
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
    deterministicDeployment: keccak256(stringToBytes('MerlinchainMDBLRewards_PROD')),
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
func.id = "001_deploy_merlinchainMDBLRewards"; // id required to prevent reexecution
func.tags = ["MerlinchainMDBLRewards"];
