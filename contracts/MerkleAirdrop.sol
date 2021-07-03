// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is ERC1155Holder {
    struct Airdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxUsers;
        uint256[] tokenIDs;
    }

    address public owner;
    uint256 public airdropCounter;
    mapping(uint256 => Airdrop) public Airdrops;
    mapping(address => mapping(uint256 => bool)) public claimed;

    modifier onlyUnclaimed(address user, uint256 _airdropID) {
        require(claimed[user][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }

    event AirdropCreated(string name, uint256 id, address tokenAddress);
    event Claimed(uint256 airdropID, address account, uint256 itemId, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function addAirdrop(
        string memory airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 MAX,
        uint256[] calldata _tokenIDs
    ) public returns (string memory, address) {
        require(msg.sender == owner, "You are not the contract owner");
        Airdrop storage drop = Airdrops[airdropCounter];
        drop.name = airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxUsers = MAX;
        drop.tokenIDs = _tokenIDs;
        emit AirdropCreated(airdropName, airdropCounter, _tokenAddress);
        airdropCounter++;
        return (airdropName, _tokenAddress);
    }

    function isClaimed(address _user, uint256 _airdropID) public view returns (bool) {
        return claimed[_user][_airdropID];
    }

    function _setClaimed(address _user, uint256 _airdropID) private {
        claimed[_user][_airdropID] = true;
    }

    function claim(
        uint256 airdropId,
        address _account,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external onlyUnclaimed(_account, airdropId) {
        if (airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        Airdrop storage drop = Airdrops[airdropId];
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_account, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");
        // Mark it claimed and send the token.
        _setClaimed(_account, airdropId);
        IERC1155(token).safeTransferFrom(address(this), _account, _itemId, _amount, data);
        this.onERC1155Received(msg.sender, msg.sender, _itemId, _amount, data);
        //only emit when successful
        emit Claimed(airdropId, _account, _itemId, _amount);
    }

    function checkAirdropDetails(uint256 _airdropID) public view returns (Airdrop memory) {
        return Airdrops[_airdropID];
    }
}
