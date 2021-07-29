// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// Allows anyone/any token to claim a token if they exist in a merkle root.
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

    struct TokenAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxTokens;
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

    function addTokenAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) external returns (string memory, address);

    function isAddressClaimed(address _user, uint256 _airdropID) external view returns (bool);

    function isTokenClaimed(uint256 _airdropID, uint256 tokenId) external view returns (bool);

    function areTokensClaimed(uint256[] memory _tokenIds, uint256 _airdropID) external view returns (bool[] memory);

    function claimForAddress(
        uint256 _airdropId,
        address _account,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external returns (address, uint256);

    function claimForTokens(
        uint256 _airdropId,
        uint256[] calldata tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata merkleProof
    ) external;

    function checkAddressAirdropDetails(uint256 _airdropID) external view returns (AddressAirdrop memory);

    function checkTokenAirdropDetails(uint256 _airdropID) external view returns (TokenAirdrop memory);

    function setRecevingContract(address _recevingContract) external;
}
