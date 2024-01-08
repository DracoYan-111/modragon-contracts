import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';


function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    /**
     * token Uri,
     * initial Owner,
     * signer Address
     */
    const args = [
         "https://cdn-dragonverseneo.mobox.app/nft/dawnbringer.json",
         "0x94fa09E866d24B930aCb23029B6B5Fe2b12c267c",
         "0x34A7C7c9b0023F19563de77D8f7cBFB05fD33B33"
        ];

	let contract = await deploy('DrawnBringerNFT', {
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
func.id = '001_deploy_drawnBringerNFT'; // id required to prevent reexecution
func.tags = ['DrawnBringerNFT'];
