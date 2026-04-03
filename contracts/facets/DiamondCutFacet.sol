// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        // Allow BOTH the Diamond itself (via Multisig) OR the contract owner
        // This allows initial setup by the owner, and later multisig control
        require(msg.sender == address(this) || msg.sender == LibDiamond.contractOwner(), 
            "Must be called via multisig or by owner");
        
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
