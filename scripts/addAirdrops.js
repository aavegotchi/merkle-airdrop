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

AddAirdrops()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
