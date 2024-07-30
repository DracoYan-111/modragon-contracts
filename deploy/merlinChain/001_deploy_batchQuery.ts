import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';


function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    

	let contract = await deploy('BatchQuery', {
		from: deployer,
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
 }
export default func;
func.id = '001_deploy_batchQuery'; // id required to prevent reexecution
func.tags = ['BatchQuery'];
