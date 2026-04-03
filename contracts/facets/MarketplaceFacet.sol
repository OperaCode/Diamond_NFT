// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage, Listing} from "../libraries/LibAppStorage.sol";

contract MarketplaceFacet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    event ListingCreated(uint256 indexed tokenId, uint256 price, address seller);
    event SaleCompleted(uint256 indexed tokenId, uint256 price, address buyer);

    function listNFT(uint256 tokenId, uint256 price) external {
        AppStorage storage s = _s();
        require(s.owners[tokenId] == msg.sender, "not owner");
        
        s.listings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            active: true
        });

        emit ListingCreated(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) external {
        AppStorage storage s = _s();
        Listing storage listing = s.listings[tokenId];
        require(listing.active, "not for sale");
        require(s.erc20Balances[msg.sender] >= listing.price, "insufficient funds");

        // Execute payment using internal ERC20
        s.erc20Balances[msg.sender] -= listing.price;
        s.erc20Balances[listing.seller] += listing.price;

        // Transfer NFT (internal logic)
        address seller = listing.seller;
        s.owners[tokenId] = msg.sender;
        s.balances[seller] -= 1;
        s.balances[msg.sender] += 1;
        
        listing.active = false;

        emit SaleCompleted(tokenId, listing.price, msg.sender);
    }
}
