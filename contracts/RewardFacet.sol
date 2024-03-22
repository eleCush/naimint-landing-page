// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibDiamond.sol";
import "./interfaces/IERC20.sol";

contract RewardFacet {
    uint256 private constant REWARD_PERCENTAGE_DIVISOR = 10000; // 100%

    event RewardDistributed(uint256 indexed epochId, uint256 totalReward);
    event RewardClaimed(address indexed user, uint256 amount);

    function calculateRewards(uint256 epochId) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(epochId == ds.currentEpochId, "RewardFacet: Invalid epoch ID");
        require(ds.rewardPool > 0, "RewardFacet: No rewards to distribute");

        uint256 totalPosts = ds.postCount;
        uint256 totalReward = ds.rewardPool;

        uint256 rewardPerVote = totalReward / ds.voteCount;

        for (uint256 i = 1; i <= totalPosts; i++) {
            uint256 postVoteCount = ds.posts[i].voteCount;
            uint256 postReward = postVoteCount * rewardPerVote;

            ds.posts[i].author.transfer(postReward);
            ds.rewardPool -= postReward;

            emit RewardClaimed(ds.posts[i].author, postReward);
        }

        emit RewardDistributed(epochId, totalReward);
    }

    function claimReward() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 reward = ds.rewards[msg.sender];
        require(reward > 0, "RewardFacet: No rewards to claim");

        ds.rewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function getRewardPool() external view returns (uint256) {
        return LibDiamond.diamondStorage().rewardPool;
    }

    function getUserReward(address user) external view returns (uint256) {
        return LibDiamond.diamondStorage().rewards[user];
    }

    function updateRewardPool(uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.rewardPool += amount;
    }
}

/*

The RewardFacet handles the reward calculations and distributions. It includes the following functions:
calculateRewards(uint256 epochId): Calculates and distributes the rewards for a specific epoch. It can only be called by the contract owner. It calculates the reward per vote and distributes the rewards to the authors of the posts based on the number of votes received. It emits a RewardDistributed event.
claimReward(): Allows users to claim their earned rewards. It transfers the reward amount to the user's address and emits a RewardClaimed event.
getRewardPool(): Returns the current balance of the reward pool.
getUserReward(address user): Returns the reward amount available for a specific user.
updateRewardPool(uint256 amount): Allows the contract owner to update the reward pool balance.

*/