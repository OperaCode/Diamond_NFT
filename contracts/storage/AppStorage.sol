// contracts/storage/AppStorage.sol
pragma solidity ^0.8.20;

struct AppStorage {
    // ERC721 core
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;

    // approvals
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    // metadata
    string name;
    string symbol;

    // supply
    uint256 totalSupply;

    // init guard
    bool initialized;
}