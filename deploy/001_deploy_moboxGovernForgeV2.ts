import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, stringToBytes, encodeFunctionData } from 'viem';
import * as contractData from '../artifacts/contracts/src/MoboxGovernForge/MoboxGovernForgeV2.sol/MoboxGovernForgeV2.json';

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  /**
   * burn amount,
   * initial Owner,
   * mobox token address
   */
  const args = [
    "2000000000000000000000",
    deployer,
    "0x3203c9E46cA618C8C1cE5dC67e7e9D75f5da2377"
  ];

  let contract = await deploy('MoboxGovernForgeV2', {
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
    deterministicDeployment: keccak256(stringToBytes('MoboxGovernForgeV2_PROD')),
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
}
export default func;
func.id = '001_deploy_moboxGovernForgeV2'; // id required to prevent reexecution
func.tags = ['MoboxGovernForgeV2'];
1000000000000001000//1000000001000//1000000000001000//1000000000001000
//0x5E7Eb57B163b78e93608E773e0F4a88A55d7C28F
{
  "url": "https://modragon-api.mobox.app/modragonGovern/snapshotData",
  "type": "api-get"
}