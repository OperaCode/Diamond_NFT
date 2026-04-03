// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage, BorrowRecord} from "../libraries/LibAppStorage.sol";

contract BorrowerFacet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    event NFTBorrowed(uint256 indexed tokenId, address borrower, uint256 expiry);
    event NFTReturned(uint256 indexed tokenId, address originalOwner);

    function borrowNFT(uint256 tokenId, uint256 duration) external {
        AppStorage storage s = _s();
        address owner = s.owners[tokenId];
        require(owner != address(0), "token not minted");
        require(owner != msg.sender, "cannot borrow own token");

        // Simple borrow logic: transfer with tracking
        // In reality, this would require approval from owner
        // For this demo, we assume the token is available to borrow
        
        uint256 expiry = block.timestamp + duration;
        s.borrowRecords[tokenId] = BorrowRecord({
            borrower: msg.sender,
            expiry: expiry
        });

        // Don't actually change ownership in this simple model, 
        // just track who is currently "using" it.
        // Or we can do a temporary ownership change if required.
        
        emit NFTBorrowed(tokenId, msg.sender, expiry);
    }

    function isBorrowed(uint256 tokenId) public view returns (bool, address, uint256) {
        BorrowRecord storage record = _s().borrowRecords[tokenId];
        if (record.expiry > block.timestamp) {
            return (true, record.borrower, record.expiry);
        }
        return (false, address(0), 0);
    }
}
