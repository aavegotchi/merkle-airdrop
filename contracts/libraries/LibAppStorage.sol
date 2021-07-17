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

struct GotchiAirdrop {
    string name;
    uint256 airdropID;
    bytes32 merkleRoot;
    address tokenAddress;
    uint256 maxGotchis;
    uint256[] itemIDs;
    uint256 claims;
}

struct AppStorage {
    mapping(uint256 => AddressAirdrop) addressAirdrops;
    mapping(uint256 => GotchiAirdrop) gotchiAirdrops;
    mapping(address => mapping(uint256 => bool)) addressClaims;
    mapping(uint256 => mapping(uint256 => bool)) gotchiClaims;
    uint256 airdropCounter;
    address receivingContract;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

contract Modifiers {
    AppStorage s;

    modifier onlyUnclaimedAddress(address user, uint256 _airdropID) {
        require(s.addressClaims[user][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }

    modifier onlyUnclaimedGotchi(uint256 tokenID, uint256 _airdropID) {
        require(s.gotchiClaims[tokenID][_airdropID] == false, "MerkleDistributor: Drop already claimed or gotchi not included.");
        _;
    }

    modifier onlyOwner {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
