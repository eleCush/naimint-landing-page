// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract EpochFacet {
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event RewardDistributed(uint256 indexed submissionId, uint256 rewardAmount);

    function diamondStorage() internal pure returns (LibDiamond.DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function startEpoch() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: previous epoch not ended");

        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 44 minutes; // For testing, use 44 minutes as the epoch duration

        emit EpochStarted(ds.epochId, ds.epochStartTime);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return diamondStorage().epochId;
    }























//Using the total number of Votes and total number of Links Submitted, we find the average Upvote amount
//we iterate over the whole collection of links and award an even split of the winnings  to any link with > average upvotes
//see note below
    function finalizeEpoch() external {
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: Epoch not ended yet");
        
        uint256 totalRewards = 121.68 ether; // Total rewards for the epoch
        uint256 totalSubmissions = ds.postCount;
        uint256 totalVotes = ds.voteCount;
        uint256 averageVotes = totalVotes / totalSubmissions;
        uint256 rewardAmount = totalRewards / totalSubmissions; // Evenly distributed

        // Directly distribute rewards to eligible submissions
        for(uint256 i = 0; i < totalSubmissions; i++) {
            if(ds.posts[i].voteCount > averageVotes) {
                distributeReward(ds.posts[i].author, rewardAmount);
                emit RewardDistributed(i, rewardAmount);
            }
        }

        prepareForNextEpoch();
    }


   /* This brilliantly simple setup, courtesy of yours truly, will pay out over time to the top 50% of content submissions.
      Some specific epochs might have the top 70% remunerated or the top 25% remunerated because their number of votes for each of those qualifying submissions exceeds the average vote count.
      This is by design, by doing one long division step and then iterative array compare we are saving a ton on gas fees otherwise spent on sorting a list.
      We do not want to sort anything.
      We just want to get the median (fuck, now we are sorting) or the average (track total votes, total links, do some division)
      and apply the law of many iterations / the laws related to large numbers of iterations / large number laws
      which will, on average, have rewarded the top 50% of content.

      Furthermore, it's actually more agreeable that the average (and not median) is used to determine payouts and that payouts be even.
      This deters more sophisticated attacks for ranked payouts and,
      Will actually promote and promulgate content that is really good, because votes directly tie into how much something is enjoyed, or sybil/nepotistically promoted. 
      In either case, there is upwards pressure on content quality, and thus things that are lukewarm ought fall below the average number of votes, provided we have enough participants.
      -VSP*/




    function prepareForNextEpoch() internal {
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 44 minutes; // For testing
        ds.postCount = 0;
        ds.voteCount = 0;
        // Reset posts and votes for the new epoch
        // Implement logic to reset posts and votes
        ds.Posts = []; //will this wokr?
        ds.Votes = []; //???
    }

    // Placeholder for reward distribution logic
    function distributeReward(address recipient, uint256 rewardAmount) internal {
        // Implement reward distribution logic, possibly calling the TokenFacet to transfer tokens
    }
}