/* global ethers hre */

//const { ethers } = require("ethers");
//const { deployDiamond } = require("./deployAirdropDiamond.js");

async function addAirdrops() {
  const AddressDropRoot =
    "0xbb2333c9ec71cbbcd15ec57fafdfb20397310baa340493f5dc815e967f0ebe7a";

  const addressItems = [0, 1, 2, 3, 4, 6];
  const accounts = await ethers.getSigners();

  const contractOwner = accounts[0];
  const ticketContractAddress = "0xA4fF399Aa1BB21aBdd3FC689f46CCE0729d58DEd"; //polygon mainnet
  console.log("Adding with the account", contractOwner.address);

  //deploy the merkleDiamond
  const dropContract = await ethers.getContractAt(
    "MerkleAirdropFacet",
    "0x36498F9Db33e1E38Ff09705b2E1863d0F917728f" //deployed merkle contract
  );

  //add first address airdrop
  await dropContract.addAddressAirdrop(
    "Birthday Party Tickets", //airdrop name
    AddressDropRoot, //merkle root
    ticketContractAddress,
    1129, //total no of people
    addressItems //items to be claimed
  );
}
addAirdrops()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
