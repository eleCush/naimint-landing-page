// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract EpochFacet {
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);

    function diamondStorage() internal pure returns (LibDiamond.DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }


    function prepareForNextEpoch() internal {
       LibDiamond.DiamondStorage storage ds = diamondStorage();
       ds.totalVotes = 0;
       ds.totalLinkSubmissions = 0;
       //ds.previousAverageUpvotes = ds.averageUpvotes; //optionally save the previous one to a value before clearing
       ds.averageUpvotes = 0;
    }
    

    function startEpoch() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: previous epoch not ended");

        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 4 days;

        emit EpochStarted(ds.epochId, ds.epochStartTime);
    }


    function getCurrentEpoch() external view returns (uint256) {
        return diamondStorage().epochId;
    }

   
   function finalizeEpoch() external {
    LibDiamond.DiamondStorage storage ds = diamondStorage();
    require(block.timestamp >= ds.epochEndTime, "EpochFacet: Epoch not ended yet");
    
    uint256 totalRewards = ds.rewardPool; // Assuming this is tracked in DiamondStorage
    //actually totalRewards will be 121.68 every time, but maybe with an on-ramp for the first ~77 epochs
    uint256 totalSubmissions = ds.postCount; // Assuming this is tracked in DiamondStorage
    uint256 totalVotes = ds.voteCount; // Assuming this is tracked in DiamondStorage
    uint256 averageVotes = totalVotes / totalSubmissions;

    // Directly distribute rewards to eligible submissions
    for(uint256 i = 0; i < totalSubmissions; i++) {
        if(ds.posts[i].voteCount > averageVotes) {
            uint256 rewardAmount = calculateRewardAmount(ds.posts[i].voteCount, totalRewards, totalSubmissions, averageVotes);
            distributeReward(ds.posts[i].author, rewardAmount);
            emit RewardDistributed(i, rewardAmount);
        }
    }

    // Reset state for next epoch
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


      // Utility function to check if the current epoch has ended
      function isEpochEnd() public view returns (bool) {
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        return block.timestamp >= ds.epochEndTime;
    }
}