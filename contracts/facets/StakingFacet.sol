// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";

contract StakingFacet {
    function _s() internal pure returns (AppStorage storage ds) {
        return LibAppStorage.appStorage();
    }

    event StakedERC20(address indexed user, uint256 amount);
    event UnstakedERC20(address indexed user, uint256 amount);
    event StakedERC721(address indexed user, uint256 tokenId);

    function stakeERC20(uint256 amount) external {
        AppStorage storage s = _s();
        require(s.erc20Balances[msg.sender] >= amount, "insufficient balance");
        
        // Simplified staking: transfer to "contract" (it's already in the Diamond)
        // We just track the staked amount
        s.erc20Balances[msg.sender] -= amount;
        s.stakedERC20[msg.sender] += amount;
        s.lastStakedTimestamp[msg.sender] = block.timestamp;

        emit StakedERC20(msg.sender, amount);
    }

    function unstakeERC20(uint256 amount) external {
        AppStorage storage s = _s();
        require(s.stakedERC20[msg.sender] >= amount, "insufficient staked amount");

        s.stakedERC20[msg.sender] -= amount;
        s.erc20Balances[msg.sender] += amount;

        emit UnstakedERC20(msg.sender, amount);
    }

    function getStakedERC20(address account) external view returns (uint256) {
        return _s().stakedERC20[account];
    }
    
    // Simplified ERC721 staking logic can be added here
}
