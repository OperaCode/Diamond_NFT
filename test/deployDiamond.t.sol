// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

contract DiamondDeployer is Test, IDiamondCut {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721Facet;
    ERC721Facet nft;          

    function setUp() public {
        dCutFacet   = new DiamondCutFacet();
        diamond     = new Diamond(address(this), address(dCutFacet));
        dLoupe      = new DiamondLoupeFacet();
        ownerF      = new OwnershipFacet();
        erc721Facet = new ERC721Facet();

        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = FacetCut({
            facetAddress: address(dLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(ownerF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        cut[2] = FacetCut({
            facetAddress: address(erc721Facet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC721Facet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("Diamond NFT", "DNFT");
    }

    function testDeployDiamond() public  {
        address[] memory facets = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(facets.length, 4);
        assertEq(nft.name(),   "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function testMintWorks() public {
        nft.mint(address(1), 1);

        assertEq(nft.ownerOf(1),            address(1));
        assertEq(nft.balanceOf(address(1)), 1);
    }

    function testTransferWorks() public {
        nft.mint(address(1), 1);

        vm.prank(address(1));
        nft.transferFrom(address(1), address(2), 1);

        assertEq(nft.ownerOf(1),            address(2));
        assertEq(nft.balanceOf(address(2)), 1);
        assertEq(nft.balanceOf(address(1)), 0);
    }

    function testApproveAndTransfer() public {
        nft.mint(address(1), 2);

        vm.prank(address(1));
        nft.approve(address(2), 2);

        vm.prank(address(2));
        nft.transferFrom(address(1), address(2), 2);

        assertEq(nft.ownerOf(2), address(2));
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}