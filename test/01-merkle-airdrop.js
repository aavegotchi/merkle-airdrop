const { expect } = require("chai");
const { ethers } = require("hardhat");
const truffleAsserts = require("truffle-assertions");
const { deployDiamond } = require("../scripts/deployAirdropDiamond.js");

describe("Test merkle", async function () {
  this.timeout(300000000);

  const diamondAddress = "0x86935F11C86623deC8a25696E1C19a8659CbF95d";
  let merkleDiamond;
  const minter = "0x027Ffd3c119567e85998f4E6B9c3d83D5702660c";
  let minterSign = await ethers.getSigner(minter);

  //will be changed according to generated tree
  //gotten from /scripts/encode_final_staging.json and /scripts/user_claimlist.json
  let currentRoot1 =
    "0x976f83a7cbbc0f173c37574ede2dc7ea66b7277c1dee66e3354c1ccfbffc331d";
  const currentRoot2 =
    "0x5c21f52c93fd5b0dd56e8a3a4ef57f42afae71dad9b03b34ac51d0c345d80b0a";

  const recipient1Object = {
    leaf: "0x1f5128a820683f23d2c09ba94161b7b38add2f0a8f1aa0d43c81110045690002",
    proof: [
      "0xe64d0d7e49ad28434c85290ef97d35f66aab6408f87cc19b5991d3e9ac3d0b25",
      "0x87d59cadeb17b5117f73ad826691a7f1a03cea1e617ec7f16937f751aebc397c",
      "0x68e0ceaa65ed249cd00c8e4bfba3317ee908511f8e6307b7cfbb8f25960137d6",
    ],
    itemId: 33,
    amountToClaim: 3,
  };

  let recipient2Object = {
    leaf: "0xe64d0d7e49ad28434c85290ef97d35f66aab6408f87cc19b5991d3e9ac3d0b25",
    proof: [
      "0x1f5128a820683f23d2c09ba94161b7b38add2f0a8f1aa0d43c81110045690002",
      "0x87d59cadeb17b5117f73ad826691a7f1a03cea1e617ec7f16937f751aebc397c",
      "0x68e0ceaa65ed249cd00c8e4bfba3317ee908511f8e6307b7cfbb8f25960137d6",
    ],
    itemId: 34,
    amountToClaim: 5,
  };

  let token2Object = {
    leaf: "0x40b6ce247f661d439f088e812daa742343795754fcbee00a0b80de24025e1017",
    proof: [
      "0x26d6bd4433a63cfd93023a38133b1d90759d06d6e1ce85e368fb70f0780ababe",
      "0x2451f235fed486f070b338f035f1a191f100a4adc313360499d81af28a0a676d",
    ],
    itemId: 33,
    amountToClaim: 1,
  };

  let token1Object = {
    leaf: "0x26d6bd4433a63cfd93023a38133b1d90759d06d6e1ce85e368fb70f0780ababe",
    proof: [
      "0x40b6ce247f661d439f088e812daa742343795754fcbee00a0b80de24025e1017",
      "0x2451f235fed486f070b338f035f1a191f100a4adc313360499d81af28a0a676d",
    ],
    itemId: 34,
    amountToClaim: 1,
  };

  let recipient1 = "0x15290cd9955154de5d18E0Cc1ef375bb7f9F2e26";
  let recipient2 = "0x805b01E7F3Fe127769B249763250222630968b4d";
  let token1 = 3410;
  let token2 = 6845;
  let itemsToMint = [33, 34]; //Stani hair,Stani vest
  let amount = [10, 10];
  //current root

  let airdropContract,
    recipient,
    tokenFacet,
    daoFacet,
    itemsFacet,
    airdropAdd,
    owner,
    airdropContract1,
    airdropContract2;

  before(async function () {
    this.timeout(3000000);
    //deploy airdrop diamond
    merkleDiamond = await deployDiamond();

    tokenFacet = await ethers.getContractAt("AavegotchiFacet", diamondAddress);
    daoFacet = await ethers.getContractAt("DAOFacet", diamondAddress);
    itemsFacet = await ethers.getContractAt("ItemsFacet", diamondAddress);
    owner = await (
      await ethers.getContractAt("OwnershipFacet", diamondAddress)
    ).owner();
  });

  describe("Interact with airdrop facet ", async function () {
    this.timeout(3000000);

    it("should add the first address airdrop correctly", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [minter],
      });

      airdropContract = await ethers.getContractAt(
        "MerkleAirdropFacet",
        merkleDiamond
      );
      //airdropContract=await airdrop.deploy("0x86935F11C86623deC8a25696E1C19a8659CbF95d");
      airdropAdd = airdropContract.address;
      console.log("airdrop contract deployed to:", airdropAdd);
      await airdropContract.addAddressAirdrop(
        "For Stani fans",
        currentRoot1,
        diamondAddress,
        10,
        itemsToMint
      );
      const details = await airdropContract.getAddressAirdropDetails(0);
      //console.log('address airdrop details',details)
      expect(details.name).to.equal("For Stani fans");
      expect(details.airdropID.toString()).to.equal("0");
      expect(details.merkleRoot).to.equal(currentRoot1);
      expect(details.tokenAddress).to.equal(diamondAddress);
      expect(details.maxUsers.toString()).to.equal("10");
      expect(details.itemIDs.toString()).to.equal(itemsToMint.toString());
    });

    it("should add the first token airdrop correctly and return that the tokens have not claimed", async function () {
      await airdropContract.addTokenAirdrop(
        "For Stani Fans",
        currentRoot2,
        diamondAddress,
        7,
        itemsToMint
      );
      const tokenEv = await airdropContract.areTokensClaimed([3410, 6845], 1);
      console.log(tokenEv);
      const details = await airdropContract.getTokenAirdropDetails(1);
      expect(tokenEv[0]).to.equal(false);
      expect(tokenEv[1]).to.equal(false);
      expect(details.name).to.equal("For Stani Fans");
      expect(details.airdropID.toString()).to.equal("1");
      expect(details.merkleRoot).to.equal(currentRoot2);
      expect(details.tokenAddress).to.equal(diamondAddress);
      expect(details.maxTokens.toString()).to.equal("7");
      expect(details.itemIDs.toString()).to.equal(itemsToMint.toString());
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [minter],
      });
    });

    it("should mint two wearable items to the merkle distributor contract", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [owner],
      });
      let ownerSign = await ethers.getSigner(owner);
      let daoOwnerConnect = await daoFacet.connect(ownerSign);
      //add the minter as an itemManager
      await daoOwnerConnect.addItemManagers([minter]);

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [owner],
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [minter],
      });

      let daoMinterConnect = await daoFacet.connect(minterSign);
      await daoMinterConnect.updateItemTypeMaxQuantity(itemsToMint, [100, 100]);
      await daoMinterConnect.mintItems(airdropAdd, itemsToMint, amount);
      const item33balance = await itemsFacet.balanceOf(airdropAdd, 33);
      const item34balance = await itemsFacet.balanceOf(airdropAdd, 34);
      expect(item33balance.toString()).to.equal("10");
      expect(item34balance.toString()).to.equal("10");
    });

    it("should allow the eligible addresses to claim their assigned wearables", async function () {
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [minter],
      });
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [recipient1],
      });
      let rec1sign = await ethers.getSigner(recipient1);
      let rec2sign = await ethers.getSigner(recipient2);
      airdropContract1 = await airdropContract.connect(rec1sign);
      airdropContract2 = await airdropContract.connect(rec2sign);
      await airdropContract1.claimForAddress(
        0,
        recipient1Object.itemId,
        recipient1Object.amountToClaim,
        recipient1Object.proof,
        "0x00"
      );
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [recipient1],
      });
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [recipient2],
      });
      await airdropContract2.claimForAddress(
        0,
        recipient2Object.itemId,
        recipient2Object.amountToClaim,
        recipient2Object.proof,
        "0x00"
      );
      const item33balance = await itemsFacet.balanceOf(recipient1, 33);
      const item34balance = await itemsFacet.balanceOf(recipient2, 34);
      //contract balances
      const Citem33balance = await itemsFacet.balanceOf(airdropAdd, 33);
      const Citem34balance = await itemsFacet.balanceOf(airdropAdd, 34);

      expect(item33balance.toString()).to.equal("3");
      expect(item34balance.toString()).to.equal("5");
      //make sure they are reduced
      expect(Citem33balance.toString()).to.equal("7");
      expect(Citem34balance.toString()).to.equal("5");
    });

    it("should revert while an address tries to claim more than once", async function () {
      await truffleAsserts.reverts(
        airdropContract2.claimForAddress(
          0,
          recipient2Object.itemId,
          recipient2Object.amountToClaim,
          recipient2Object.proof,
          "0x00"
        ),
        "MerkleDistributor: Drop already claimed or address not included."
      );
    });

    it("should allow any address to claim wearables for eligible tokens", async function () {
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [recipient2],
      });
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [recipient1],
      });
      let rec1sign = await ethers.getSigner(recipient1);
      airdropContract1 = await airdropContract.connect(rec1sign);
      const claimFor = await airdropContract1.claimForTokens(
        1,
        [token1, token2],
        [token1Object.itemId, token2Object.itemId],
        [token1Object.amountToClaim, token2Object.amountToClaim],
        [token1Object.proof, token2Object.proof]
      );
      const details = await airdropContract.getTokenAirdropDetails(1);
      //console.log(deets.events)
      //console.log(details)
      const item33balance = await itemsFacet.balanceOfToken(
        diamondAddress,
        token2,
        33
      );
      const item34balance = await itemsFacet.balanceOfToken(
        diamondAddress,
        token1,
        34
      );
      //contract balances
      const Citem33balance = await itemsFacet.balanceOf(airdropAdd, 33);
      const Citem34balance = await itemsFacet.balanceOf(airdropAdd, 34);

      expect(item33balance.toString()).to.equal("1");
      expect(item34balance.toString()).to.equal("1");
      //make sure they are reduced
      expect(Citem33balance.toString()).to.equal("6");
      expect(Citem34balance.toString()).to.equal("4");
    });

    it("balance should remain unchanged without reverting if token(s) have claimed before", async function () {
      const returns = await airdropContract1.claimForTokens(
        1,
        [token1, token2],
        [token1Object.itemId, token2Object.itemId],
        [token1Object.amountToClaim, token2Object.amountToClaim],
        [token1Object.proof, token2Object.proof]
      );
      //	const details=await airdropContract.checkTokenAirdropDetails(1)
      //	await truffleAsserts.reverts(airdropContract1.claimForTokens(1,[token1,token2],[token1Object.itemId,token2Object.itemId],[token1Object.amountToClaim,token2Object.amountToClaim],[token1Object.proof,token2Object.proof]),"MerkleDistributor: Drop already claimed or token not included.")
      const item33balance = await itemsFacet.balanceOfToken(
        diamondAddress,
        token2,
        33
      );
      const item34balance = await itemsFacet.balanceOfToken(
        diamondAddress,
        token1,
        34
      );

      const itemEv = await airdropContract.areTokensClaimed(
        [token1, token2],
        1
      );
      expect(itemEv[0]).to.equal(true);
      expect(itemEv[1]).to.equal(true);
      //contract balances
      const Citem33balance = await itemsFacet.balanceOf(airdropAdd, 33);
      const Citem34balance = await itemsFacet.balanceOf(airdropAdd, 34);

      expect(item33balance.toString()).to.equal("1");
      expect(item34balance.toString()).to.equal("1");
      //make sure they are reduced
      expect(Citem33balance.toString()).to.equal("6");
      expect(Citem34balance.toString()).to.equal("4");
      //const details1=await airdropContract.checkTokenAirdropDetails(1)
      //const details2=await airdropContract.checkAddressAirdropDetails(0)
      //console.log(details1)
      //console.log(details2)
    });
  });
});
