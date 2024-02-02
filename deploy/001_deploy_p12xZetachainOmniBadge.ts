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
  const durationData: number = votingDurationDays;

  const startTimeData: number = votingStartTime << 64;

  return startTimeData | durationData;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  // 2024-02-02 00:00:01 
  // 9999 days
  let voteStartTimeAndDurationDays = storeData(1706803201, 9999);

  console.log(deployer)
  /**
   *  _voteStartTimeAndDurationDays,
   *  _systemContractAddress,
   *  _tokenUri,
   *  _initialOwner,
   *  _payQuantity
   */
  const args = [
    voteStartTimeAndDurationDays, // 2024-02-02 00:00:01  9999days
    "0x91d18e54DAf4F677cB28167158d6dd21F6aB3921", //Zeta chain systemContractAddress
    "https://cdn1.p12.games/collabs/zetachain/P12_Zetachain_OmniBadge.png",
    deployer,
    "100000000000000000" // 0.1ETH
  ];

  let contract = await deploy("P12xZetachainOmniBadge", {
    from: deployer,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    proxy: {
      // Cancel ProxyAdmin check
      checkProxyAdmin: false,
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
      // Methods that need to be called to update the contract
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
    // eip-155 disabled
    // deterministicDeployment: keccak256(
    //   stringToBytes("P12xZetachainOmniBadge_PROD"),
    // ),
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
