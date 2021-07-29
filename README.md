# merkle-airdrop

Generates a list of abjects mapped to each address and root hash. Object contains the leaves and merkle proofs needed to verify that a given data exists for that address in the tree

## Overview

Contract acts as the disseminator of ERC1155 tokens and only sends out tokens on data verification i.e merkle proof and appropriate arguments used to build the merkle tree for that user.

## Airdrop Types

There are two Airdrop types.

Address Airdrops transfer the airdropped token into the claiming user's wallet address.

Token Airdrops utilize the ERC998 Composable NFTs standard to transfer the token directly into the receiving ERC721 token, assuming that it implements the ERC998 methods for receiving ERC1155s.

## Description

Example user story:

1. Owner of contract prepares a list of addresses with many entries and publishes this list in public static .js file in JSON format
2. Owner reads this list, builds the merkle tree structure and writes down the Merkle root of it.
3. Owner deploys the contract passing in the merkle root and token contract address as constructors
4. Owner says to users, that they can claim their tokens, if they owe any of addresses, presented in list, published on owner's site.
5. User wants to claim his N tokens, he also builds Merkle tree from public list and prepares Merkle proof, consisting from log2N hashes, describing the way to reach Merkle root
6. User sends transaction with Merkle proof to contract
7. Contract checks Merkle proof, and, if proof is correct, then sender's address is in list of allowed addresses, and contract does some action for this use. In our case it sends out the appropriate number of `tokens` of the correct `itemId`

## Notes

Merkle tree data structure is the very efficient way to check if arbitrary data is in some list when we're not able to store this list in contract, it takes too much storage space. In our case we store a single hash in contract, allowing user to build the proof by himself. This scheme has advantage in sotrage requirements, but requires additional computations on client side, so, use wisely.
