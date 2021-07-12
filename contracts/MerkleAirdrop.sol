// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";
import {ItemsTransferFacet} from "./ItemsTransferFacet.sol";

contract MerkleDistributor is ERC1155Holder {
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

    //used this to prevent stack too deep
    struct GotchiClaimDetails {
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
    address public receivingContract;

    mapping(uint256 => AddressAirdrop) public addressAirdrops;
    mapping(uint256 => GotchiAirdrop) public gotchiAirdrops;
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

    event AddressAirdropCreated(string name, uint256 id, address tokenAddress);
    event GotchiAirdropCreated(string name, uint256 id, address tokenAddress);
    event AddressClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);
    event GotchiClaim(uint256 airdropID, uint256 gotchiID, uint256 itemId, uint256 amount);

    constructor(address _receivingContract) {
        owner = msg.sender;
        receivingContract = _receivingContract;
    }

    function addAddressAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) public returns (string memory, address) {
        require(msg.sender == owner, "You are not the contract owner");
        AddressAirdrop storage drop = addressAirdrops[airdropCounter];
        drop.name = _airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxUsers = _max;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit AddressAirdropCreated(_airdropName, airdropCounter, _tokenAddress);

        airdropCounter++;
        return (_airdropName, _tokenAddress);
    }

    function addGotchiAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) public returns (string memory, address) {
        require(msg.sender == owner, "You are not the contract owner");
        GotchiAirdrop storage drop = gotchiAirdrops[airdropCounter];
        drop.name = _airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxGotchis = _max;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit GotchiAirdropCreated(_airdropName, airdropCounter, _tokenAddress);
        airdropCounter++;
        return (_airdropName, _tokenAddress);
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

    function areGotchisClaimed(uint256[] memory _gotchiIds, uint256 _airdropID) public view returns (bool[] memory) {
        if (_airdropID > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        bool[] memory gStat = new bool[](_gotchiIds.length);
        for (uint256 i; i < _gotchiIds.length; i++) {
            if (isGotchiClaimed(_airdropID, _gotchiIds[i])) {
                gStat[i] = false;
            }
            if (!(isGotchiClaimed(_airdropID, _gotchiIds[i]))) {
                gStat[i] = true;
            }
        }
        return gStat;
    }

    function _setGotchiClaimed(uint256 _tokenId, uint256 _airdropID) private {
        gotchiClaims[_tokenId][_airdropID] = true;
    }

    function claimForAddress(
        uint256 _airdropId,
        address _account,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external onlyUnclaimedAddress(_account, _airdropId) {
        if (_airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        AddressAirdrop storage drop = addressAirdrops[_airdropId];
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_account, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setAddressClaimed(_account, _airdropId);
        IERC1155(token).safeTransferFrom(address(this), _account, _itemId, _amount, data);
        drop.claims++;
        //only emit when successful
        emit AddressClaim(_airdropId, _account, _itemId, _amount);
    }

    function claimForGotchis(
        uint256 _airdropId,
        uint256[] calldata tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata merkleProof
    ) external {
        require(
            tokenIds.length == _itemIds.length && _itemIds.length == _amounts.length && merkleProof.length == _itemIds.length,
            "GotchiClaim: mismatched number of array elements"
        );
        if (_airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        GotchiAirdrop storage drop = gotchiAirdrops[_airdropId];
        bytes32 merkleRoot = drop.merkleRoot;
        address itemContract = drop.tokenAddress;
        for (uint256 index; index < tokenIds.length; index++) {
            //using a temporary struct to avoid stack too deep errors
            // uint256[] storage ineligibleGotchis;
            GotchiClaimDetails memory g;
            g.tokenId = tokenIds[index];
            g.amount = _amounts[index];
            g.itemId = _itemIds[index];
            g.tokenContract = itemContract;
            g.proof = merkleProof[index];
            g._node = keccak256(abi.encodePacked(g.tokenId, g.itemId, g.amount));
            if ((MerkleProof.verify(g.proof, merkleRoot, g._node)) && !(isGotchiClaimed(_airdropId, tokenIds[index]))) {
                _setGotchiClaimed(g.tokenId, _airdropId);
                ItemsTransferFacet(g.tokenContract).transferToParent(sender, receivingContract, g.tokenId, g.itemId, g.amount);
                drop.claims++;
                emit GotchiClaim(_airdropId, tokenIds[index], _itemIds[index], _amounts[index]);
            }
        }
    }

    function checkAddressAirdropDetails(uint256 _airdropID) public view returns (AddressAirdrop memory) {
        return addressAirdrops[_airdropID];
    }

    function checkGotchiAirdropDetails(uint256 _airdropID) public view returns (GotchiAirdrop memory) {
        return gotchiAirdrops[_airdropID];
    }
}
