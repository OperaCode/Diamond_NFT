// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage, Transaction} from "../libraries/LibAppStorage.sol";

contract MultisigFacet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    modifier onlyOwner() {
        require(_s().isMultisigOwner[msg.sender], "not owner");
        _;
    }

    function multisigInit(address[] memory _owners, uint256 _threshold) external {
        AppStorage storage s = _s();
        require(!s.initialized, "Already initialized"); // Assuming shared initialization
        require(_owners.length > 0, "owners required");
        require(_threshold > 0 && _threshold <= _owners.length, "invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!s.isMultisigOwner[owner], "owner not unique");

            s.isMultisigOwner[owner] = true;
            s.multisigOwners.push(owner);
        }
        s.multisigThreshold = _threshold;
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        AppStorage storage s = _s();
        uint256 txIndex = s.multisigTransactions.length;

        s.multisigTransactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex) public onlyOwner {
        AppStorage storage s = _s();
        require(_txIndex < s.multisigTransactions.length, "tx does not exist");
        require(!s.multisigConfirmations[_txIndex][msg.sender], "tx already confirmed");
        require(!s.multisigTransactions[_txIndex].executed, "tx already executed");

        s.multisigConfirmations[_txIndex][msg.sender] = true;
        s.multisigTransactions[_txIndex].numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex) public onlyOwner {
        AppStorage storage s = _s();
        require(_txIndex < s.multisigTransactions.length, "tx does not exist");
        require(!s.multisigTransactions[_txIndex].executed, "tx already executed");
        require(s.multisigTransactions[_txIndex].numConfirmations >= s.multisigThreshold, "cannot execute tx");

        Transaction storage transaction = s.multisigTransactions[_txIndex];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }
}
