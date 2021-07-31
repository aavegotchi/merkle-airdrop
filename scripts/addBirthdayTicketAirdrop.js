/* global ethers hre */

//const { ethers } = require("ethers");
//const { deployDiamond } = require("./deployAirdropDiamond.js");

async function addAirdrops() {
  const AddressDropRoot =
    "0xbb2333c9ec71cbbcd15ec57fafdfb20397310baa340493f5dc815e967f0ebe7a";

  const testing = ["hardhat", "localhost"].includes(hre.network.name);

  const gasPrice = 2000000000;

  const addressItems = [0, 1, 2, 3, 4, 6];
  const accounts = await ethers.getSigners();

  let contractOwner = accounts[0];

  console.log("Adding with the account", contractOwner.address);

  const diamondAddress = "0x75C8866f47293636F1C32eCBcD9168857dBEfc56";

  const ownerContract = await ethers.getContractAt(
    "OwnershipFacet",
    diamondAddress
  );

  const owner = await ownerContract.owner();

  let ticketContractAddress;

  console.log("owner:", owner);

  if (testing) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [owner],
    });
    contractOwner = await ethers.getSigner(owner);

    ticketContractAddress = "0xA4fF399Aa1BB21aBdd3FC689f46CCE0729d58DEd";
  } else {
    //polygon mainnet
    ticketContractAddress = "0xA02d547512Bb90002807499F05495Fe9C4C3943f";
  }

  //deploy the merkleDiamond
  const dropContract = await ethers.getContractAt(
    "MerkleAirdropFacet",
    diamondAddress, //deployed merkle contract
    contractOwner
  );

  /*
  //add first address airdrop
  await dropContract.addAddressAirdrop(
    "Birthday Party Tickets", //airdrop name
    AddressDropRoot, //merkle root
    ticketContractAddress,
    1129, //total no of people
    addressItems, //items to be claimed
    { gasPrice: gasPrice }
  );
  */

  const airdrops = await dropContract.getAddressAirdropDetails("0");
  console.log("details:", airdrops);
}
addAirdrops()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
