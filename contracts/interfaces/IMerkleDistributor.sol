// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function tokenAddress() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(address _user,uint256 _airdropID) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim( address _account,uint256 _itemId ,uint256 _amount, bytes32[] calldata merkleProof,bytes calldata data) external;
    //admin only,allows the addition of new airdrops
    function addAirdrop(string memory airdropName,bytes32 _merkleRoot,address _tokenAddress,uint256 MAX,uint256[] calldata _tokenIDs) external returns(string memory,address);
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 airdropID,address account, uint256 itemId,uint256 amount);
}