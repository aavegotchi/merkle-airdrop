// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// Allows anyone/any gotchi to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    struct AddressAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        uint256 maxUsers;
        uint256[] itemIDs;
        uint256 claims;
        address tokenAddress;
    }

    struct GotchiAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxGotchis;
        uint256[] itemIDs;
        uint256 claims;
    }

    function addAddressAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) external returns (string memory, address);

    function addGotchiAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) external returns (string memory, address);

    function isAddressClaimed(address _user, uint256 _airdropID) external view returns (bool);

    function isGotchiClaimed(uint256 _airdropID, uint256 tokenId) external view returns (bool);

    function areGotchisClaimed(uint256[] memory _gotchiIds, uint256 _airdropID) external view returns (bool[] memory);

    function claimForAddress(
        uint256 _airdropId,
        address _account,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external returns (address, uint256);

    function claimForGotchis(
        uint256 _airdropId,
        uint256[] calldata tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata merkleProof
    ) external;

    function checkAddressAirdropDetails(uint256 _airdropID) external view returns (AddressAirdrop memory);

    function checkGotchiAirdropDetails(uint256 _airdropID) external view returns (GotchiAirdrop memory);

    function setRecevingContract(address _recevingContract) external;
}
