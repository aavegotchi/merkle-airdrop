// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";
import {ItemsTransferFacet} from "./ItemsTransferFacet.sol";

contract MerkleDistributor is ERC1155Holder {
    struct addressAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        uint256 maxUsers;
        uint256[] itemIDs;
        uint256 claims;
        address tokenAddress;
    }

    struct gotchiAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxGotchis;
        uint256[] itemIDs;
        uint256 claims;
    }

    //used this to prevent stack too deep
    struct gotchiClaimDetails {
        uint256 tokenId;
        uint256 amount;
        uint256 itemId;
        address tokenContract;
        bytes32[] proof;
        bytes32 _node;
    }

    address sender = address(this);
    address public owner;
    uint256 public airdropCounter;
    address receivingContract = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;

    mapping(uint256 => addressAirdrop) public addressAirdrops;
    mapping(uint256 => gotchiAirdrop) public gotchiAirdrops;
    mapping(address => mapping(uint256 => bool)) public addressClaims;
    mapping(uint256 => mapping(uint256 => bool)) public gotchiClaims;

    modifier onlyUnclaimedAddress(address user, uint256 _airdropID) {
        require(addressClaims[user][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }

    modifier onlyUnclaimedGotchi(uint256 tokenID, uint256 _airdropID) {
        require(gotchiClaims[tokenID][_airdropID] == false, "MerkleDistributor: Drop already claimed or gotchi not included.");
        _;
    }

    event addressAirdropCreated(string name, uint256 id, address tokenAddress);
    event gotchiAirdropCreated(string name, uint256 id, address tokenAddress);
    event addressClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);
    event gotchiClaim(uint256 airdropID, uint256 gotchiID, uint256 itemId, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function addAddressAirdrop(
        string memory airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 MAX,
        uint256[] calldata _itemIDs
    ) public returns (string memory, address) {
        require(msg.sender == owner, "You are not the contract owner");
        addressAirdrop storage drop = addressAirdrops[airdropCounter];
        drop.name = airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxUsers = MAX;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit addressAirdropCreated(airdropName, airdropCounter, _tokenAddress);

        airdropCounter++;
        return (airdropName, _tokenAddress);
    }

    function addGotchiAirdrop(
        string memory airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 MAX,
        uint256[] calldata _itemIDs
    ) public returns (string memory, address) {
        require(msg.sender == owner, "You are not the contract owner");
        gotchiAirdrop storage drop = gotchiAirdrops[airdropCounter];
        drop.name = airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxGotchis = MAX;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit gotchiAirdropCreated(airdropName, airdropCounter, _tokenAddress);
        airdropCounter++;
        return (airdropName, _tokenAddress);
    }

    function isAddressClaimed(address _user, uint256 _airdropID) public view returns (bool) {
        return addressClaims[_user][_airdropID];
    }

    function isGotchiClaimed(uint256 _airdropID, uint256 tokenId) public view returns (bool) {
        return gotchiClaims[tokenId][_airdropID];
    }

    function _setAddressClaimed(address _user, uint256 _airdropID) private {
        addressClaims[_user][_airdropID] = true;
    }

    function _setGotchiClaimed(uint256 tokenId, uint256 _airdropID) private {
        gotchiClaims[tokenId][_airdropID] = true;
    }

    function claimForAddress(
        uint256 airdropId,
        address _account,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external onlyUnclaimedAddress(_account, airdropId) {
        if (airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        addressAirdrop storage drop = addressAirdrops[airdropId];
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_account, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setAddressClaimed(_account, airdropId);
        IERC1155(token).safeTransferFrom(address(this), _account, _itemId, _amount, data);
        drop.claims++;
        //only emit when successful
        emit addressClaim(airdropId, _account, _itemId, _amount);
    }

    function claimForGotchis(
        uint256 airdropId,
        uint256[] calldata tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata merkleProof
    ) external {
        require(
            tokenIds.length == _itemIds.length && _itemIds.length == _amounts.length && merkleProof.length == _itemIds.length,
            "GotchiClaim: mismatched number of array elements"
        );
        if (airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        gotchiAirdrop storage drop = gotchiAirdrops[airdropId];
        bytes32 merkleRoot = drop.merkleRoot;
        address itemContract = drop.tokenAddress;
        for (uint256 index; index < tokenIds.length; index++) {
            //using a temporary struct to avoid stack too deep errors
            gotchiClaimDetails memory g;
            g.tokenId = tokenIds[index];
            g.amount = _amounts[index];
            g.itemId = _itemIds[index];
            g.tokenContract = itemContract;
            g.proof = merkleProof[index];
            g._node = keccak256(abi.encodePacked(g.tokenId, g.itemId, g.amount));
            if ((MerkleProof.verify(g.proof, merkleRoot, g._node)) && !(isGotchiClaimed(airdropId, tokenIds[index]))) {
                _setGotchiClaimed(g.tokenId, airdropId);
                ItemsTransferFacet(g.tokenContract).transferToParent(sender, receivingContract, g.tokenId, g.itemId, g.amount);
                _setGotchiClaimed(g.tokenId, airdropId);
                drop.claims++;
                emit gotchiClaim(airdropId, tokenIds[index], _itemIds[index], _amounts[index]);
            }
        }
    }

    function checkAddressAirdropDetails(uint256 _airdropID) public view returns (addressAirdrop memory) {
        return addressAirdrops[_airdropID];
    }

    function checkGotchiAirdropDetails(uint256 _airdropID) public view returns (gotchiAirdrop memory) {
        return gotchiAirdrops[_airdropID];
    }
}
