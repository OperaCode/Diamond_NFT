// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";

contract ERC20Facet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function erc20Init(string memory _name, string memory _symbol, uint8 _decimals) external {
        AppStorage storage s = _s();
        s.erc20Name = _name;
        s.erc20Symbol = _symbol;
        s.erc20Decimals = _decimals;
    }

    function erc20Name() external view returns (string memory) {
        return _s().erc20Name;
    }

    function erc20Symbol() external view returns (string memory) {
        return _s().erc20Symbol;
    }

    function erc20Decimals() external view returns (uint8) {
        return _s().erc20Decimals;
    }

    function erc20TotalSupply() external view returns (uint256) {
        return _s().erc20TotalSupply;
    }

    function erc20BalanceOf(address account) external view returns (uint256) {
        return _s().erc20Balances[account];
    }

    function erc20Transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function erc20Allowance(address owner, address spender) external view returns (uint256) {
        return _s().erc20Allowances[owner][spender];
    }

    function erc20Approve(address spender, uint256 amount) external returns (bool) {
        _s().erc20Allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function erc20TransferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _s().erc20Allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _s().erc20Allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function erc20Mint(address to, uint256 amount) external {
        // In a real scenario, this should be restricted
        AppStorage storage s = _s();
        s.erc20TotalSupply += amount;
        s.erc20Balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        AppStorage storage s = _s();
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        require(s.erc20Balances[from] >= amount, "ERC20: insufficient balance");

        s.erc20Balances[from] -= amount;
        s.erc20Balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}
