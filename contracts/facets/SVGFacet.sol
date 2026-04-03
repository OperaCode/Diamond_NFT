// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";

contract SVGFacet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    function setTokenColor(uint256 tokenId, string memory color) external {
        _s().tokenColor[tokenId] = color;
    }

    function getTokenSVG(uint256 tokenId) public view returns (string memory) {
        string memory color = _s().tokenColor[tokenId];
        if (bytes(color).length == 0) {
            color = "blue";
        }
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">',
            '<rect width="100" height="100" fill="', color, '"/>',
            '<text x="50%" y="50%" text-anchor="middle" fill="white">ID: ', _toString(tokenId), '</text>',
            '</svg>'
        ));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        // In a real scenario, this should be base64 encoded
        return getTokenSVG(tokenId);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
