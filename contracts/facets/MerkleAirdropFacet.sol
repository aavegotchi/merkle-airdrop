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
    event TokenAirdropCreated(string name, uint256 id, address tokenAddress);
    event AddressClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);
    event TokenClaim(uint256 airdropID, uint256 tokenID, uint256 itemId, uint256 amount);

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

    function addTokenAirdrop(
        string memory _airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 _max,
        uint256[] calldata _itemIDs
    ) public onlyOwner returns (uint256) {
        TokenAirdrop storage drop = s.tokenAirdrops[s.airdropCounter];
        drop.name = _airdropName;
        drop.airdropID = s.airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxTokens = _max;
        drop.itemIDs = _itemIDs;
        drop.claims = 0;
        emit TokenAirdropCreated(_airdropName, s.airdropCounter, _tokenAddress);
        s.airdropCounter++;
        return (drop.airdropID);
    }

    function isAddressClaimed(address _user, uint256 _airdropID) public view returns (bool) {
        return s.addressClaims[_user][_airdropID];
    }

    function isTokenClaimed(uint256 _airdropID, uint256 tokenId) public view returns (bool) {
        return s.tokenClaims[tokenId][_airdropID];
    }

    function setAddressClaimed(address _user, uint256 _airdropID) private {
        s.addressClaims[_user][_airdropID] = true;
    }

    function areTokensClaimed(uint256[] memory _tokenIds, uint256 _airdropID) public view returns (bool[] memory) {
        TokenAirdrop storage drop = s.tokenAirdrops[_airdropID];

        require(drop.maxTokens > 0, "Airdrop is not created yet");
        //}
        bool[] memory gStat = new bool[](_tokenIds.length);
        for (uint256 i; i < _tokenIds.length; i++) {
            if (isTokenClaimed(_airdropID, _tokenIds[i])) {
                gStat[i] = true;
            }
            if (!(isTokenClaimed(_airdropID, _tokenIds[i]))) {
                gStat[i] = false;
            }
        }
        return gStat;
    }

    function setTokenClaimed(uint256 _tokenId, uint256 _airdropID) private {
        s.tokenClaims[_tokenId][_airdropID] = true;
    }

    function claimForAddress(
        uint256 _airdropId,
        uint256 _itemId,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        bytes calldata _data
    ) external onlyUnclaimedAddress(msg.sender, _airdropId) {
        AddressAirdrop storage drop = s.addressAirdrops[_airdropId];
        require(drop.maxUsers > 0, "Airdrop is not created yet");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        setAddressClaimed(msg.sender, _airdropId);
        IERC1155(token).safeTransferFrom(address(this), msg.sender, _itemId, _amount, _data);
        drop.claims++;
        //only emit when successful
        emit AddressClaim(_airdropId, msg.sender, _itemId, _amount);
    }

    struct TokenClaimDetails {
        uint256 tokenId;
        uint256 amount;
        uint256 itemId;
        address tokenContract;
        bytes32[] proof;
        bytes32 _node;
    }

    function claimForTokens(
        uint256 _airdropId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _itemIds,
        uint256[] calldata _amounts,
        bytes32[][] calldata _merkleProofs
    ) external {
        require(
            _tokenIds.length == _itemIds.length && _itemIds.length == _amounts.length && _merkleProofs.length == _itemIds.length,
            "TokenClaim: mismatched number of array elements"
        );

        TokenAirdrop storage drop = s.tokenAirdrops[_airdropId];
        require(drop.maxTokens > 0, "Airdrop is not created yet");

        bytes32 merkleRoot = drop.merkleRoot;
        address itemContract = drop.tokenAddress;
        for (uint256 index; index < _tokenIds.length; index++) {
            TokenClaimDetails memory g;
            g.tokenId = _tokenIds[index];
            g.amount = _amounts[index];
            g.itemId = _itemIds[index];
            g.tokenContract = itemContract;
            g.proof = _merkleProofs[index];
            g._node = keccak256(abi.encodePacked(g.tokenId, g.itemId, g.amount));
            if ((MerkleProof.verify(g.proof, merkleRoot, g._node)) && !(isTokenClaimed(_airdropId, _tokenIds[index]))) {
                setTokenClaimed(g.tokenId, _airdropId);
                IItemsTransferFacet(g.tokenContract).transferToParent(address(this), s.tokenContract, g.tokenId, g.itemId, g.amount);
                drop.claims++;
                emit TokenClaim(_airdropId, _tokenIds[index], _itemIds[index], _amounts[index]);
            }
        }
    }

    function getAddressAirdropDetails(uint256 _airdropID) public view returns (AddressAirdrop memory) {
        return s.addressAirdrops[_airdropID];
    }

    function getTokenAirdropDetails(uint256 _airdropID) public view returns (TokenAirdrop memory) {
        return s.tokenAirdrops[_airdropID];
    }

    function setTokenContract(address _tokenContract) public onlyOwner {
        s.tokenContract = _tokenContract;
    }
}
