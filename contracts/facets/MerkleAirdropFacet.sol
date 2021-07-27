// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IMerkleDistributor.sol";
import "../interfaces/IItemsTransferFacet.sol";
import "../libraries/LibAppStorage.sol";
import "../shared/ERC1155TokenReceiver.sol";

contract MerkleAirdropFacet is Modifiers, ERC1155TokenReceiver {
    event AddressAirdropCreated(string name, uint256 id, address tokenAddress);
    event GotchiAirdropCreated(string name, uint256 id, address tokenAddress);
    event AddressClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);
    event GotchiClaim(uint256 airdropID, uint256 gotchiID, uint256 itemId, uint256 amount);

    function addAddressAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) public onlyOwner returns (uint256) {
        AddressAirdrop storage drop = s.addressAirdrops[s.airdropCounter];
        drop.name = _airdropName;
        drop.airdropID = s.airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxUsers = _max;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit AddressAirdropCreated(_airdropName, drop.airdropID, _tokenAddress);

        s.airdropCounter++;
        return (drop.airdropID);
    }

    function addGotchiAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) public onlyOwner returns (uint256) {
        GotchiAirdrop storage drop = s.gotchiAirdrops[s.airdropCounter];
        drop.name = _airdropName;
        drop.airdropID = s.airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxGotchis = _max;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit GotchiAirdropCreated(_airdropName, s.airdropCounter, _tokenAddress);
        s.airdropCounter++;
        return (drop.airdropID);
    }

    function isAddressClaimed(address _user, uint256 _airdropID) public view returns (bool) {
        return s.addressClaims[_user][_airdropID];
    }

    function isGotchiClaimed(uint256 _airdropID, uint256 tokenId) public view returns (bool) {
        return s.gotchiClaims[tokenId][_airdropID];
    }

    function setAddressClaimed(address _user, uint256 _airdropID) private {
        s.addressClaims[_user][_airdropID] = true;
    }

    function areGotchisClaimed(uint256[] memory _gotchiIds, uint256 _airdropID) public view returns (bool[] memory) {
        require(_airdropID < s.airdropCounter, "Airdrop is not created yet");
        bool[] memory gStat = new bool[](_gotchiIds.length);
        for (uint256 i; i < _gotchiIds.length; i++) {
            if (isGotchiClaimed(_airdropID, _gotchiIds[i])) {
                gStat[i] = true;
            }
            if (!(isGotchiClaimed(_airdropID, _gotchiIds[i]))) {
                gStat[i] = false;
            }
        }
        return gStat;
    }

    function setGotchiClaimed(uint256 _tokenId, uint256 _airdropID) private {
        s.gotchiClaims[_tokenId][_airdropID] = true;
    }

    function claimForAddress(
        uint256 _airdropId,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes calldata data
    ) external onlyUnclaimedAddress(msg.sender, _airdropId) {
        require(_airdropId < s.airdropCounter, "Airdrop is not created yet");
        AddressAirdrop storage drop = s.addressAirdrops[_airdropId];
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        setAddressClaimed(msg.sender, _airdropId);
        IERC1155(token).safeTransferFrom(address(this), msg.sender, _itemId, _amount, data);
        drop.claims++;
        //only emit when successful
        emit AddressClaim(_airdropId, msg.sender, _itemId, _amount);
    }

    struct GotchiClaimDetails {
        uint256 tokenId;
        uint256 amount;
        uint256 itemId;
        address tokenContract;
        bytes32[] proof;
        bytes32 _node;
    }

    function claimForGotchis(
        uint256 _airdropId,
        uint256[] calldata tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        require(
            tokenIds.length == _itemIds.length && _itemIds.length == _amounts.length && merkleProofs.length == _itemIds.length,
            "GotchiClaim: mismatched number of array elements"
        );
        require(_airdropId < s.airdropCounter, "Airdrop is not created yet");

        GotchiAirdrop storage drop = s.gotchiAirdrops[_airdropId];
        bytes32 merkleRoot = drop.merkleRoot;
        address itemContract = drop.tokenAddress;
        for (uint256 index; index < tokenIds.length; index++) {
            GotchiClaimDetails memory g;
            g.tokenId = tokenIds[index];
            g.amount = _amounts[index];
            g.itemId = _itemIds[index];
            g.tokenContract = itemContract;
            g.proof = merkleProofs[index];
            g._node = keccak256(abi.encodePacked(g.tokenId, g.itemId, g.amount));
            if ((MerkleProof.verify(g.proof, merkleRoot, g._node)) && !(isGotchiClaimed(_airdropId, tokenIds[index]))) {
                setGotchiClaimed(g.tokenId, _airdropId);
                IItemsTransferFacet(g.tokenContract).transferToParent(address(this), s.receivingContract, g.tokenId, g.itemId, g.amount);
                drop.claims++;
                emit GotchiClaim(_airdropId, tokenIds[index], _itemIds[index], _amounts[index]);
            }
        }
    }

    function getAddressAirdropDetails(uint256 _airdropID) public view returns (AddressAirdrop memory) {
        return s.addressAirdrops[_airdropID];
    }

    function getGotchiAirdropDetails(uint256 _airdropID) public view returns (GotchiAirdrop memory) {
        return s.gotchiAirdrops[_airdropID];
    }

    function setRecevingContract(address _recevingContract) public onlyOwner {
        s.receivingContract = _recevingContract;
    }
}
