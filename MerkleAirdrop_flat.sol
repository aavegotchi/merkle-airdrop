
// File: contracts/interfaces/IMerkleDistributor.sol

// -License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function tokenAddress() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(address _user,uint256 _airdropID) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim( address _account,uint256 _itemId ,uint256 _amount, bytes32[] calldata merkleProof,bytes calldata data) external;
    //admin only,allows the addition of new airdrops
    function addAirdrop(string memory airdropName,bytes32 _merkleRoot,address _tokenAddress,uint256 MAX,uint256[] calldata _tokenIDs) external returns(string memory,address);
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 airdropID,address account, uint256 itemId,uint256 amount);
}
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// -License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/MerkleAirdrop.sol

// -License-Identifier: UNLICENSED
pragma solidity 0.8.1;






contract MerkleDistributor is ERC1155Holder {
    
    struct addressAirdrop {
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxUsers;
        uint256[] itemIDs;
    }
    
    struct gotchiAirdrop{
        string name;
        uint256 airdropID;
        bytes32 merkleRoot;
        address tokenAddress;
        uint256 maxGotchis;
        uint256[] itemIDs;
    }
    
    struct gotchiDropDetails{
        uint256 tokenId;
        uint256 amount;
        uint256 itemId;
    }

    address public owner;
    uint256 public airdropCounter;
    
    mapping(uint256 => addressAirdrop) public addressAirdrops;
    mapping(uint256 => gotchiAirdrop) public gotchiAirdrops;
    mapping(address => mapping(uint256 => bool)) public addressClaims;
    mapping(uint256 => mapping(uint256 => bool)) public gotchiClaims;

    modifier onlyUnclaimedAddress(address user, uint256 _airdropID) {
        require(addressClaims[user][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }
    
    modifier onlyUnclaimedGotchi(uint256 tokenID,uint256 _airdropID) {
        require(gotchiClaims[tokenID][_airdropID] == false, "MerkleDistributor: Drop already claimed or address not included.");
        _;
    }
    
    event addressAirdropCreated(string name, uint256 id, address tokenAddress);
    event gotchiAirdropCreated(string name,uint256 id,address tokenAddress);
    event addressClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);
    event gotchiClaim(uint256 airdropID, address account, uint256 itemId, uint256 amount);

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
        emit addressAirdropCreated(airdropName, airdropCounter, _tokenAddress);
        
        
        airdropCounter++;
        return (airdropName, _tokenAddress);
    }
    
    function addGotchiAirdrop(string memory airdropName,
        bytes32 _merkleRoot,
        address _tokenAddress,
        uint256 MAX,
        uint256[] calldata _itemIDs) public returns(string memory,address){
            require(msg.sender == owner, "You are not the contract owner");
        gotchiAirdrop storage drop = gotchiAirdrops[airdropCounter];
        drop.name = airdropName;
        drop.airdropID = airdropCounter;
        drop.merkleRoot = _merkleRoot;
        drop.tokenAddress = _tokenAddress;
        drop.maxGotchis = MAX;
        drop.itemIDs = _itemIDs;
        emit gotchiAirdropCreated(airdropName, airdropCounter, _tokenAddress);
        airdropCounter++;
        return (airdropName, _tokenAddress);
        }

    function isAddressClaimed(address _user, uint256 _airdropID) public view returns (bool) {
        return addressClaims[_user][_airdropID];
    }
    
    function isGotchiClaimed(uint256 _airdropID,uint256 tokenId) public view returns(bool){
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
        addressAirdrop memory drop = addressAirdrops[airdropId];
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_account, _itemId, _amount));
        bytes32 merkleRoot = drop.merkleRoot;
        address token = drop.tokenAddress;
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");
        // Mark it claimed and send the token.
        _setAddressClaimed(_account, airdropId);
        IERC1155(token).safeTransferFrom(address(this), _account, _itemId, _amount, data);
        //only emit when successful
        emit addressClaim(airdropId, _account, _itemId, _amount);
    }
    
    function claimForGotchis(uint256 airdropId,uint256[] calldata tokenIds,uint256[] calldata _itemIds,uint256[] calldata _amounts, bytes32[] calldata merkleProof) external {
        require(tokenIds.length==_itemIds.length && _itemIds.length ==_amounts.length,"GotchiClaim: mismatched number of array elements");
        if (airdropId > airdropCounter) {
            revert("Airdrop is not created yet");
        }
        uint[] memory eligibleGotchis;
        gotchiAirdrop memory drop=gotchiAirdrops[airdropId];
        bytes32 merkleRoot=drop.merkleRoot;
        for(uint256 index;index<tokenIds.length;index++){
            uint gotchi=tokenIds[index];
            uint item=_itemIds[index];
            uint amount=_amounts[index];
            bytes32 node=keccak256(abi.encodePacked(gotchi,item,amount));
            if((MerkleProof.verify(merkleProof, merkleRoot, node))==true){
               
            }
            
        }
        
        
    }

   // function checkAirdropDetails(uint256 _airdropID) public view returns (Airdrop memory) {
    //    return Airdrops[_airdropID];
    //}
}
