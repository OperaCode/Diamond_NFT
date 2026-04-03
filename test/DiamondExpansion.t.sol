// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import {Diamond} from "../contracts/Diamond.sol";
import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {ERC721Facet} from "../contracts/facets/ERC721Facet.sol";
import {ERC20Facet} from "../contracts/facets/ERC20Facet.sol";
import {MultisigFacet} from "../contracts/facets/MultisigFacet.sol";
import {StakingFacet} from "../contracts/facets/StakingFacet.sol";
import {SVGFacet} from "../contracts/facets/SVGFacet.sol";
import {MarketplaceFacet} from "../contracts/facets/MarketplaceFacet.sol";
import {BorrowerFacet} from "../contracts/facets/BorrowerFacet.sol";

contract DiamondExpansionTest is Test, IDiamondCut {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721Facet;
    ERC20Facet erc20Facet;
    MultisigFacet multisigFacet;
    StakingFacet stakingFacet;
    SVGFacet svgFacet;
    MarketplaceFacet marketplaceFacet;
    BorrowerFacet borrowerFacet;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address user = address(0x3);

    function setUp() public {
        // Initial setup
        dCutFacet = new DiamondCutFacet();
        // Set address(0x99) as initial owner to avoid address(this) being owner in tests
        diamond = new Diamond(address(0x99), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721Facet = new ERC721Facet();
        erc20Facet = new ERC20Facet();
        multisigFacet = new MultisigFacet();
        stakingFacet = new StakingFacet();
        svgFacet = new SVGFacet();
        marketplaceFacet = new MarketplaceFacet();
        borrowerFacet = new BorrowerFacet();

        // 1. Initial Cut: Add basic facets + Multisig
        FacetCut[] memory cut = new FacetCut[](9);
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
        cut[3] = FacetCut({
            facetAddress: address(erc20Facet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC20Facet")
        });
        cut[4] = FacetCut({
            facetAddress: address(multisigFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MultisigFacet")
        });
        cut[5] = FacetCut({
            facetAddress: address(stakingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("StakingFacet")
        });
        cut[6] = FacetCut({
            facetAddress: address(svgFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("SVGFacet")
        });
        cut[7] = FacetCut({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });
        cut[8] = FacetCut({
            facetAddress: address(borrowerFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("BorrowerFacet")
        });
        // Self-cut to update DiamondCutFacet if needed, but here it's already deployed with restriction
        
        vm.prank(address(0x99));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        // Initialize Multisig
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;
        MultisigFacet(address(diamond)).multisigInit(owners, 2);

        // Initialize ERC721
        ERC721Facet(address(diamond)).init("DiamondNFT", "DNFT");
        // Initialize ERC20
        ERC20Facet(address(diamond)).erc20Init("DiamondToken", "DTK", 18);
    }

    function testERC20Functionality() public {
        ERC20Facet token = ERC20Facet(address(diamond));
        token.erc20Mint(user, 1000);
        assertEq(token.erc20BalanceOf(user), 1000);
        
        vm.prank(user);
        token.erc20Transfer(owner1, 100);
        assertEq(token.erc20BalanceOf(user), 900);
        assertEq(token.erc20BalanceOf(owner1), 100);
    }

    function testMarketplace() public {
        ERC721Facet nft = ERC721Facet(address(diamond));
        ERC20Facet token = ERC20Facet(address(diamond));
        MarketplaceFacet market = MarketplaceFacet(address(diamond));

        // 1. Mint NFT to user
        nft.mint(user, 1);
        
        // 2. Mint tokens to owner1
        token.erc20Mint(owner1, 500);

        // 3. User lists NFT
        vm.prank(user);
        market.listNFT(1, 500);

        // 4. Owner1 buys NFT
        vm.prank(owner1);
        market.buyNFT(1);

        assertEq(nft.ownerOf(1), owner1);
        assertEq(token.erc20BalanceOf(user), 500);
        assertEq(token.erc20BalanceOf(owner1), 0);
    }

    function testMultisigDiamondCutRestriction() public {
        FacetCut[] memory cut = new FacetCut[](0);
        
        // Should fail because not called by the diamond itself OR owner
        vm.expectRevert("Must be called via multisig or by owner");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function testMultisigExecution() public {
        MultisigFacet multisig = MultisigFacet(address(diamond));
        ERC20Facet token = ERC20Facet(address(diamond));

        bytes memory data = abi.encodeWithSelector(ERC20Facet.erc20Mint.selector, user, 500);
        
        vm.prank(owner1);
        multisig.submitTransaction(address(diamond), 0, data);

        vm.prank(owner1);
        multisig.confirmTransaction(0);
        
        vm.prank(owner2);
        multisig.confirmTransaction(0);

        vm.prank(owner1);
        multisig.executeTransaction(0);

        assertEq(token.erc20BalanceOf(user), 500);
    }

    function testSVGMetadata() public {
        SVGFacet svg = SVGFacet(address(diamond));
        ERC721Facet(address(diamond)).mint(user, 10);
        
        svg.setTokenColor(10, "red");
        string memory uri = svg.tokenURI(10);
        assertTrue(bytes(uri).length > 0);
        // Should contain red
    }

    function generateSelectors(string memory _facetName) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(FacetCut[] calldata, address, bytes calldata) external override {}
}
