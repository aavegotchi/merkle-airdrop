/* global ethers hre */

//const { ethers } = require("ethers");
//const { deployDiamond } = require("./deployAirdropDiamond.js");

async function addAirdrops() {
  const GotchiDropRoot =
    "0x4d3ac8f2ec6a54695c16e6e48eb43436aa95fa5781136e26804f8224fcf83cdd";

  const testing = ["hardhat", "localhost"].includes(hre.network.name);

  const gasPrice = 2000000000;

  const bgItem = [210];
  const accounts = await ethers.getSigners();

  let contractOwner = accounts[0];

  console.log("Adding with the account", contractOwner.address);

  const diamondAddress = "0x75C8866f47293636F1C32eCBcD9168857dBEfc56";

  const ownerContract = await ethers.getContractAt(
    "OwnershipFacet",
    diamondAddress
  );

  const owner = await ownerContract.owner();

  let bgContractAddress;

  console.log("owner:", owner);

  if (testing) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [owner],
    });
    contractOwner = await ethers.getSigner(owner);

    bgContractAddress = "0xA4fF399Aa1BB21aBdd3FC689f46CCE0729d58DEd";
  } else {
    //polygon mainnet
    bgContractAddress = "0xA02d547512Bb90002807499F05495Fe9C4C3943f";
  }

  //merkleDropfacet
  const dropContract = await ethers.getContractAt(
    "MerkleAirdropFacet",
    diamondAddress, //deployed merkle contract
    contractOwner
  );

  //add first gotchi airdrop
  await dropContract.addTokenAirdrop(
    "H1 Background Airdrops", //airdrop name
    GotchiDropRoot, //merkle root
    bgContractAddress,
    10000, //total no of gotchis
    bgItem, //items to be claimed
    { gasPrice: gasPrice }
  );

  const airdrops = await dropContract.getTokenAirdropDetails("1");
  console.log("details:", airdrops);
}
addAirdrops()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
