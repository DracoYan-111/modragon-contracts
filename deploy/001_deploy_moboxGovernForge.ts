import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';


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
         "1000000000000000",
         deployer,
         "0x01FD87cB74265a0a9Af6a62afB2FEf8C9646f515"
        ];

	let contract = await deploy('MoboxGovernForge', {
		from: deployer,
		args,
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});
    
    // TODO If you want to cancel "verification", please enable comments
    console.log(
        "Waiting 30 seconds before beginning the contract verification to allow the block explorer to index the contract...\n",
      );

    await delay(30000); // Wait for 30 seconds before verifying the contract

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: args,
    });
 }
export default func;
func.id = '001_deploy_moboxGovernForge'; // id required to prevent reexecution
func.tags = ['MoboxGovernForge'];
