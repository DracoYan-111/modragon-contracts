import {
  signTypedData,
  SignTypedDataVersion,
  TypedMessage,
} from "@metamask/eth-sig-util";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MoDragonContract } from "../../typechain-types"

describe("MoDragonContract", function () {
  let owner: any;
  let account: any;

  const tokenURI = "test test";
  const signe = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  const PRIVATEKRY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

  let moDragonContract: MoDragonContract;

  beforeEach(async function () {
    [owner, account] = await ethers.getSigners();
    let getContractFactory = await ethers.getContractFactory(
      "/contracts/src/modragon/MoDragonContract.sol:MoDragonContract",
    );
    moDragonContract = await getContractFactory.deploy(
      tokenURI,
      owner.address,
      signe
    );

  });
  it("🪪Should be consistent with the set address.", async function () {

    expect(await moDragonContract.owner()).to.equal(owner.address);

  })
  it("🖼️Should be consistent with the set tokenURI.", async function () {

    expect(await moDragonContract.tokenURI(0)).to.equal(tokenURI);

  })
  it("🙅‍♂️Only the owner should be able to pause and unpause", async function () {

    await expect(moDragonContract.connect(account).pause()).to.be.reverted;
    await expect(moDragonContract.connect(account).unpause()).to.be.reverted;
    await expect(moDragonContract.pause()).not.to.be.reverted;
    await expect(moDragonContract.unpause()).not.to.be.reverted;

  });

  it("🙅Only the owner should be able to safeMint", async function () {

    await expect(moDragonContract.connect(account).safeMint(account.address)).to.be.reverted;

    await expect(moDragonContract.safeMint(account.address)).not.to.be.reverted;

  })
  it("🙆‍♂️Should be consistent with the designated verifier.", async function () {

    // TODO Contract information
    const chainId = 1;
    const contractVersion = "V1.0.0";
    const contractName = await moDragonContract.name();
    const verifyingContract = await moDragonContract.getAddress();

    // TODO Signature information
    const user = owner.address;
    const deadline = Math.floor(Date.now() / 1000) + 300;

    // "whitelistMint(address user,uint256 deadline)"
    const message = {
      user: user,
      deadline: deadline,
    };

    const data: TypedMessage<any> = {
      types: {
        EIP712Domain: [
          { name: "name", type: "string" },
          { name: "version", type: "string" },
          { name: "chainId", type: "uint256" },
          { name: "verifyingContract", type: "address" },
        ],
        whitelistMint: [
          { name: "user", type: "address" },
          { name: "deadline", type: "uint256" },
        ],
      },
      domain: {
        name: contractName,
        version: contractVersion,
        chainId: chainId,
        verifyingContract: verifyingContract,
      },
      primaryType: "whitelistMint",
      message,
    };

    // Use SignTypedDataVersion.V4 generate signature
    const signature = signTypedData({
      privateKey: Buffer.from(PRIVATEKRY.slice(2), "hex"),
      data,
      version: SignTypedDataVersion.V4,
    });

    await expect(moDragonContract.whitelistMint(
      deadline,
      signature,
    )).not.to.be.reverted;
  });
});
