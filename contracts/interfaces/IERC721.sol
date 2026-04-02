// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);

    
    function transferFrom(address from, address to, uint256 tokenId) external;

   
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}