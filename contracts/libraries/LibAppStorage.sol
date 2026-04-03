// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
    uint256 numConfirmations;
}

struct Listing {
    uint256 price;
    address seller;
    bool active;
}

struct BorrowRecord {
    address borrower;
    uint256 expiry;
}

struct AppStorage {
    // ─── ERC721 Core ────────────────────────────────────────────────
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    string name;
    string symbol;
    uint256 totalSupply;

    // ─── ERC20 Core ─────────────────────────────────────────────────
    mapping(address => uint256) erc20Balances;
    mapping(address => mapping(address => uint256)) erc20Allowances;
    uint256 erc20TotalSupply;
    string erc20Name;
    string erc20Symbol;
    uint8 erc20Decimals;

    // ─── Multisig ───────────────────────────────────────────────────
    address[] multisigOwners;
    mapping(address => bool) isMultisigOwner;
    uint256 multisigThreshold;
    Transaction[] multisigTransactions;
    mapping(uint256 => mapping(address => bool)) multisigConfirmations;

    // ─── Staking ────────────────────────────────────────────────────
    mapping(address => uint256) stakedERC20;
    mapping(address => uint256[]) stakedERC721;
    mapping(address => uint256) lastStakedTimestamp;
    mapping(address => uint256) stakingRewards;

    // ─── Marketplace ───────────────────────────────────────────────
    mapping(uint256 => Listing) listings;

    // ─── Borrower ──────────────────────────────────────────────────
    mapping(uint256 => BorrowRecord) borrowRecords;

    // ─── Metadata ──────────────────────────────────────────────────
    mapping(uint256 => string) tokenColor; // example for SVG

    // ─── Init Guard ────────────────────────────────────────────────
    bool initialized;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}
