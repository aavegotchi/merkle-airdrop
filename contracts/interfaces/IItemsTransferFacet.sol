// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IItemsTransferFacet {
    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) external;
}
