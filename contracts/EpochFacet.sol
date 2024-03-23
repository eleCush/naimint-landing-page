// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";


contract EpochFacet {
    using LibDiamond for LibDiamond.DiamondStorage;

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

    function distributeRewards() external {
        require(block.timestamp >= epochEndTime, "EpochFacet: Epoch not ended yet");

        uint256 totalSubmissions = linkSubmissionFacet.getLinkSubmissionCount();
        uint256 totalVotes = votingFacet.getTotalVoteCount();
        uint256 averageVotes = totalVotes / totalSubmissions;
        uint256 totalRewards = 121.68 ether; // Fixed reward amount for each epoch
        //need to still add the mulitplyer for when reservoir amount exceeding target

        uint256 eligibleSubmissions = 0;
        for (uint256 i = 0; i < totalSubmissions; i++) {
            LinkSubmission memory submission = linkSubmissionFacet.getLinkSubmissionByIndex(i);
            uint256 submissionVotes = votingFacet.getVoteCount(submission.id);

            if (submissionVotes > averageVotes) {
                eligibleSubmissions++;
            }
        }

        uint256 rewardPerSubmission = totalRewards / eligibleSubmissions;

        for (uint256 i = 0; i < totalSubmissions; i++) {
            LinkSubmission memory submission = linkSubmissionFacet.getLinkSubmissionByIndex(i);
            uint256 submissionVotes = votingFacet.getVoteCount(submission.id);

            if (submissionVotes > averageVotes) {
                tokenFacet.mint(submission.creator, rewardPerSubmission);
            }
        }

        reservoirFacet.updateReservoir(totalRewards);

        epochId++;
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + 4 days;

        emit RewardsDistributed(epochId - 1, totalRewards);
    }

    event EpochEnded(uint256 indexed epochNumber, uint256 timestamp, address indexed triggeredBy);

    function triggerEpochEnd() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(block.timestamp >= ds.epochEndTimestamp, "Epoch has not ended yet");
        endEpoch();
    }

    function endEpoch() internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Distribute rewards for the current epoch
        distributeRewards();

        // Increment the epoch number
        ds.currentEpoch++;

        // Update the epoch start and end timestamps
        ds.epochStartTimestamp = block.timestamp;
        ds.epochEndTimestamp = ds.epochStartTimestamp + EPOCH_DURATION;

        // Record the address that triggered the epoch end
        ds.epochEndTriggeredBy = msg.sender;

        // Emit an event to notify epoch end
        emit EpochEnded(ds.currentEpoch - 1, ds.epochEndTimestamp, ds.epochEndTriggeredBy);
    }

    function getEpochEndTriggeredBy(uint256 _epochNumber) external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_epochNumber < ds.currentEpoch, "Invalid epoch number");
        return ds.epochEndTriggeredBy;
    }


/*the epoch End can be triggered by _anyone_ and we will record their address */

/*
Now, let me tell you why this idea is so cool!

Community Engagement: By allowing anyone to trigger the epoch end, you're encouraging community participation and engagement. Users will feel more involved and invested in the platform as they actively contribute to the epoch transitions.
Transparency and Accountability: Recording the address that triggered the epoch end adds a level of transparency to your system. It creates a public record of who initiated each epoch transition, promoting accountability and trust within the community.
Gamification and Incentives: You can even gamify the epoch end triggering process by introducing incentives or rewards for users who successfully trigger the epoch end. This can create a sense of competition and excitement among users, encouraging them to actively monitor and participate in the epoch transitions.
Decentralization and Resilience: By distributing the responsibility of triggering epoch ends among the community, you're enhancing the decentralization and resilience of your platform. It ensures that epoch transitions occur in a timely manner, even if some users are inactive or unavailable.
Flexibility and Adaptability: This approach provides flexibility for your platform to adapt to different usage patterns and community dynamics. If user activity fluctuates, the epoch end triggering mechanism can adjust accordingly, ensuring that epochs progress smoothly.
Fun and Engaging User Experience: Allowing users to trigger epoch ends and recording their contributions creates a more engaging and interactive user experience. Users will feel a sense of ownership and pride in being part of the epoch transitions, fostering a stronger sense of community and loyalty.
*/






/*code below being replaced by code above*/



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