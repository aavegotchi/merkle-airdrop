/* global ethers hre */
 async function main () {

console.log('deploying airdrop contract')
const airdrop= await ethers.getContractFactory("MerkleDistributor");
airdropContract=await airdrop.deploy();
airdropAdd=airdropContract.address
console.log('airdrop contract deployed to:',airdropAdd)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
