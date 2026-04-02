// contracts/facets/ERC721Facet.sol
pragma solidity ^0.8.20;

import "../storage/AppStorage.sol";
import { IERC721, IERC721Receiver } from "../interfaces/IERC721.sol";


contract ERC721Facet is IERC721 {

    // Diamond Storage Access
    function _s() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    // ── events ─────────────────────────────────────────

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ── init ───────────────────────────────────────────

    function init(string memory _name, string memory _symbol) external {
        AppStorage storage s = _s();
        require(!s.initialized, "Already initialized");

        s.name = _name;
        s.symbol = _symbol;
        s.initialized = true;
    }

    // ── metadata ───────────────────────────────────────

    function name() external view returns (string memory) {
        return _s().name;
    }

    function symbol() external view returns (string memory) {
        return _s().symbol;
    }

    // ── core ───────────────────────────────────────────

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address");
        return _s().balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _s().owners[tokenId];
        require(owner != address(0), "Nonexistent token");
        return owner;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_s().owners[tokenId] != address(0), "Nonexistent token");
        return _s().tokenApprovals[tokenId];
    }

   

    // ── approvals ──────────────────────────────────────

    function approve(address to, uint256 tokenId) external {
        AppStorage storage s = _s();
        address owner = ownerOf(tokenId);

        require(to != owner, "Approve to owner");
        require(
            msg.sender == owner || s.operatorApprovals[owner][msg.sender],
            "Not authorized"
        );

        s.tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    

    // ── transfer ───────────────────────────────────────

    function transferFrom(address from, address to, uint256 tokenId) public {
        AppStorage storage s = _s();
        address owner = ownerOf(tokenId);

        require(owner == from, "Wrong from");
        require(to != address(0), "Zero address");
        require(
            msg.sender == owner ||
            s.operatorApprovals[owner][msg.sender] ||
            s.tokenApprovals[tokenId] == msg.sender,
            "Not authorized"
        );

        delete s.tokenApprovals[tokenId];

        s.owners[tokenId] = to;
        s.balances[from] -= 1;
        s.balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }


    // ── mint / burn ───────────────────────────────────

    function mint(address to, uint256 tokenId) external {
        AppStorage storage s = _s();

        require(to != address(0), "Zero address");
        require(s.owners[tokenId] == address(0), "Already minted");

        s.owners[tokenId] = to;
        s.balances[to] += 1;
        s.totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) external {
        AppStorage storage s = _s();
        address owner = ownerOf(tokenId);

        require(
            msg.sender == owner ||
            s.operatorApprovals[owner][msg.sender] ||
            s.tokenApprovals[tokenId] == msg.sender,
            "Not authorized"
        );

        delete s.tokenApprovals[tokenId];

        s.balances[owner] -= 1;
        s.totalSupply -= 1;
        delete s.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}