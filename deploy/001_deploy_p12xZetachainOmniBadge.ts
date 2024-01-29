import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { keccak256, stringToBytes, encodeFunctionData } from "viem";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function storeData(
  votingStartTime: number,
  votingDurationDays: number,
): number {
  // 将votingDurationDays放在最低的64位
  const durationData: number = votingDurationDays;

  // 将votingStartTime左移64位，为votingDurationDays留出空间
  const startTimeData: number = votingStartTime << 64;

  // 通过按位或操作(|)将两个值合并到一个uint256中
  return startTimeData | durationData;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  // 2024-01-30 00:00:01
  // 99 days
  let voteStartTimeAndDurationDays = storeData(1706544001, 99);

  console.log(deployer)
  /**
   *  _voteStartTimeAndDurationDays,
   *  _systemContractAddress,
   *  _tokenUri,
   *  _initialOwner,
   *  _payQuantity
   */
  const args = [
    voteStartTimeAndDurationDays,
    "0x803470638940Ec595B40397cbAa597439DE55907",
    "test token uri",
    deployer,
    "100000000000000000" // 0.1ETH
  ];

  let contract = await deploy("P12xZetachainOmniBadge", {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    proxy: {
      // 取消ProxyAdmin检查
      checkProxyAdmin: false,
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      // 更新合约需要被调用的方法
      upgradeFunction: {
        methodName: "upgradeToAndCall",
        upgradeArgs: ["{implementation}", "{data}"],
      },
      execute: {
        init: {
          methodName: "initialize",
          args: args,
        },
      },
    },
    deterministicDeployment: keccak256(
      stringToBytes("P12xZetachainOmniBadge_PROD"),
    ),
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
func.id = "001_deploy_p12xZetachainOmniBadge"; // id required to prevent reexecution
func.tags = ["P12xZetachainOmniBadge"];
