/* global ethers hre */

//const { ethers } = require("ethers");
//const { deployDiamond } = require("./deployAirdropDiamond.js");

async function AddAirdrops() {
  const AddressDropRoot =
    "0xe81b116d1a2dc5d823dcaee0b9fabf195dc1ac51680038003c60bf66984115c9";
  const GotchiDropRoots =
    "0x5c21f52c93fd5b0dd56e8a3a4ef57f42afae71dad9b03b34ac51d0c345d80b0a";
  const addressItems = [0, 1, 2, 3, 4, 5, 6];
  const gotchiItems = [1, 3];
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];
  const diamondAddress = "0xA4fF399Aa1BB21aBdd3FC689f46CCE0729d58DEd";
  console.log("Adding with the account", contractOwner.address);

  //deploy the merkleDiamond
  //const airdropDiamond = await deployDiamond();
  const dropContract = await ethers.getContractAt(
    "MerkleAirdropFacet",
    "0x886ABAAEb9De0eE18A163944A6A468158502a11F"
  );

  //add first address airdrop
  await dropContract.addAddressAirdrop(
    "Kovan Address Test",
    AddressDropRoot,
    diamondAddress,
    1128,
    addressItems
  );

  //add first gotchi airdrop
  await dropContract.addGotchiAirdrop(
    "Kovan Gotchi Test",
    GotchiDropRoots,
    diamondAddress,
    6,
    gotchiItems
  );
}

async function claim() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];
  console.log("Adding with the account", contractOwner.address);

  const proof = [
    "0x10ff2fe309d43253981a4391bbed37b31b0e49de4f724a9eaef0d6e89dbbd095",
    "0xe6c48f409aa3bff7df3e9d6a5c8e70148e7d9aebdf5e4334a724c572e70606a7",
    "0x73b428ef67b37190d7819aee3542c3716fadac2bdb103c6c08e2820899e91c24",
    "0xe5019696ef1099db286b13033ef03f44075a5f371542e907c5cd8433be3517dd",
    "0xb82b2b30b1700ff0e7b785bc80697609a76007ba7e91eaa56414a216e0803a66",
    "0xb224bb7e6394a835904f57584035dbc68ebc38844c99477c6d3e5bddfb92c5bc",
    "0xcd357b43e466ee1b27d90a36c528d1e2c4c6f6c04b14cc5b40ee6c8cf459bfe5",
    "0x4b8f046f901a08dfe8c49576d854f6c553b1159cb5339e2f15f50d9a0b2a7f59",
    "0x013910566aef5297aba0ab5988581100701c061919302d5d84920e2327236f3c",
    "0x9d9e160ac37094f06d83960a196c744a07c50040c08c08203693dafd84d2c580",
    "0x15e752e775c6ee5267768e055c5eaee30c4339a79464a5e5a8e62db9c96397c5",
  ];
  const dropContract = await ethers.getContractAt(
    "MerkleAirdropFacet",
    "0x886ABAAEb9De0eE18A163944A6A468158502a11F"
  );

  const tx = await dropContract.claimForAddress(0, 2, 1, proof, "0x00");
  console.log("claiming in:", tx.wait());
}

claim()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
