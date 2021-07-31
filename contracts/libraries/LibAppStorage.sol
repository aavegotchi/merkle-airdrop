// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {LibDiamond} from "./LibDiamond.sol";

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

struct AppStorage {
    mapping(uint256 => AddressAirdrop) addressAirdrops;
    mapping(uint256 => TokenAirdrop) tokenAirdrops;
    mapping(address => mapping(uint256 => bool)) addressClaims;
    mapping(uint256 => mapping(uint256 => bool)) tokenClaims;
    uint256 airdropCounter;
    address tokenContract;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage s;

    modifier onlyUnclaimedAddress(address user, uint256 _airdropID) {
        require(s.addressClaims[user][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }

    modifier onlyOwner {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
