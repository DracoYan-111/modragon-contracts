import {
  signTypedData,
  SignTypedDataVersion,
  TypedDataUtils,
  TypedMessage,
} from "@metamask/eth-sig-util";
import { expect } from "chai";
import { ethers } from "hardhat";
import { DrawnBringerNFT } from "../../typechain-types"

describe("DrawnBringerNFT", function () {
  let owner: any;
  let account: any;

  const tokenURI = "test test";
  const newTokenUri = "new new new new";
  const signe = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  const PRIVATEKRY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

  let drawnBringerNFT: DrawnBringerNFT;

  beforeEach(async function () {
    [owner, account] = await ethers.getSigners();
    let getContractFactory = await ethers.getContractFactory(
      "/contracts/src/drawnBringer/DrawnBringerNFT.sol:DrawnBringerNFT",
    );
    drawnBringerNFT = (await (ethers as any).getContractFactory.deploy(
      tokenURI,
      owner.address,
      signe
    )
    );
  });
  describe('🟰Equal', function () {
    it("🪪Should be consistent with the set address.", async function () {

      expect(await drawnBringerNFT.owner()).to.equal(owner.address);

    })
    it("🖼️Should be consistent with the set tokenURI.", async function () {

      expect(await drawnBringerNFT.tokenURI(0)).to.equal(tokenURI);

    })
  })
  describe('🃏Reverted and not reverted', function () {
    it("🙅‍♂️Only the owner should be able to pause and unpause", async function () {

      await expect(drawnBringerNFT.connect(account).pause()).to.be.reverted;
      await expect(drawnBringerNFT.connect(account).unpause()).to.be.reverted;
      await expect(drawnBringerNFT.pause()).not.to.be.reverted;
      await expect(drawnBringerNFT.unpause()).not.to.be.reverted;

    });
    it("🙅‍♂️Only the owner should be able to set new signers", async function () {

      await expect(drawnBringerNFT.connect(account).updateSigners(owner.address)).to.be.reverted;
      await expect(drawnBringerNFT.updateSigners(owner.address)).not.to.be.reverted;

    });
    it("🙅‍♂️Only the owner should be able to set new tokenUri", async function () {

      await expect(drawnBringerNFT.connect(account).updateTokenUri(newTokenUri)).to.be.reverted;
      await expect(drawnBringerNFT.updateTokenUri(newTokenUri)).not.to.be.reverted;

    });
  })
  describe('✅Verifier', function () {
    it("🙆‍♂️Should be consistent with the designated verifier.", async function () {

      // TODO Contract information
      const chainId = 1;
      const contractVersion = "V1.0.0";
      const contractName = await drawnBringerNFT.name();
      const verifyingContract = await drawnBringerNFT.getAddress();

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
      let signature = signTypedData({
        privateKey: Buffer.from(PRIVATEKRY.slice(2), "hex"),
        data,
        version: SignTypedDataVersion.V4,
      });

      // Generate r vs for calling method
      signature = ethers.concat([
        ethers.dataSlice(signature, 0, 64),
        ethers.dataSlice(signature, 64, 65)
      ]);
      const { r, yParityAndS: vs } = ethers.Signature.from(signature);
      await expect(drawnBringerNFT.whitelistMint(
        deadline,
        r,
        vs
      )).not.to.be.reverted;

      expect(await drawnBringerNFT.userReceive(owner.address)).to.be.true
    });
  })
});
