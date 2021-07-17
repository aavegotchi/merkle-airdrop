/* global ethers hre */
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

async function deployDiamond() {
  const accounts = await ethers.getSigners();

  const contractOwner = accounts[0];
  const aavegotchiDiamondAddress = "0x86935F11C86623deC8a25696E1C19a8659CbF95d";
  console.log("Diamond owner is", contractOwner.address);

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();
  console.log("DiamondCutFacet deployed:", diamondCutFacet.address);

  // deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(
    contractOwner.address,
    diamondCutFacet.address,
    aavegotchiDiamondAddress
  );
  await diamond.deployed();
  console.log("Diamond deployed:", diamond.address);

  // deploy DiamondInit
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  console.log("DiamondInit deployed:", diamondInit.address);

  // deploy facets
  console.log("");
  console.log("Deploying facets");
  const FacetNames = ["DiamondLoupeFacet", "MerkleAirdropFacet"];

  const cut = [];

  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy();
    await facet.deployed();
    console.log(`${FacetName} deployed: ${facet.address}`);
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  console.log("");
  console.log("Diamond Cut:", cut);
  const diamondCut = await ethers.getContractAt(
    "contracts/interfaces/IDiamondCut.sol:IDiamondCut",
    diamond.address
  );
  let tx;
  let receipt;
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData("init");
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
  console.log("Diamond cut tx: ", tx.hash);
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  console.log("Completed diamond cut");
  return diamond.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
exports.deployDiamond = deployDiamond;
