// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor,ERC1155Holder {
    
    address public immutable token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(address => bool) public claimed;

    constructor(address token_, bytes32 merkleRoot_)  {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(address _user) public view override returns (bool) {
        return claimed[_user];
    }

    function _setClaimed(address _user) private {
        claimed[_user]=true;
    }
    
    function tokenAddress() external view override returns (address){
        return token;
    }
    
     function rootHash() external view returns (bytes32){
         return merkleRoot;
     }
     

    function claim( address _account,uint256 _itemId ,uint256 _amount, bytes32[] calldata merkleProof,bytes calldata data ) external override {
        require(!isClaimed(_account), 'MerkleDistributor: Drop already claimed.');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_account, _itemId, _amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(_account);
        IERC1155(token).safeTransferFrom(address(this),_account,_itemId,_amount,data);
        this.onERC1155Received(msg.sender,msg.sender,_itemId,_amount,data);
        //onERC1155Received(msg.sender,msg.sender,_itemId, _amount,data) (bytes4);
        //only emit when successful
        emit Claimed(_account,_itemId,_amount);
    }
    
   
    
}
