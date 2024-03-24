// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract EpochFacet {
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime, address indexed triggeredBy);

    event RewardMinted(address indexed creator, uint256 amount); //someone got a reward slice.
    event RepaymentMinted(address indexed voter, uint256 amount); //someone got their voting charge back.
    event RewardsDistributed(uint256 indexed epochId, uint256 totalRewards); //everyone got paid out for the epoch.

    /* reward distributed = sent $NAIM to addr.
       rewards distributed = for given epoch, total rewards were: such and such.*/

    
    // Reference LibDiamond using diamondStorage
    function startEpoch() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: Previous epoch not ended");
        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 44 minutes; // Adjusted for testing

        emit EpochStarted(ds.epochId, ds.epochStartTime);
    }

    function getCurrentEpoch() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.epochId;
    }

    function finalizeEpoch() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: Epoch not ended yet");

        // Logic to distribute rewards...
        // Ensure to adjust this method based on your actual implementation

        prepareForNextEpoch();
    }

    function prepareForNextEpoch() internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 44 minutes; // For actual deployment
        // Reset posts and votes for the new epoch
        // Note: Implement logic according to your application's data structure
    }

    // Example method to distribute rewards
    //function distributeReward(address recipient, uint256 rewardAmount) internal {
    //    // Implement logic to transfer $NAIM tokens as rewards
    //}

    // Placeholder for reward distribution logic
    function distributeReward(address recipient, uint256 rewardAmount) internal {
        // Implement reward distribution logic, possibly calling the TokenFacet to transfer tokens
    }

    //maybe not do in for loop ?  consider gas for for loop below or function call above
    //benefit to function call is can emit on ecah one ?  i guess we can emit below but starts to get messy

    function distributeRewards() internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: Epoch not ended yet");
        
        uint256 totalRewards = 121.68 ether; // Fixed reward amount for each epoch
        uint256 totalSubmissions = linkSubmissionFacet.getLinkSubmissionCount();
        uint256 totalVotes = votingFacet.getTotalVoteCount();
        uint256 averageVotes = totalVotes / totalSubmissions;

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
                emit RewardMinted(submission.creator, rewardPerSubmission);

                // Repay users who upvoted the top 50% content
                address[] memory voters = votingFacet.getVoters(submission.id);
                uint256 voterCount = voters.length;
                uint256 repaymentAmount = 0.01 ether; // Repayment amount per voter

                for (uint256 j = 0; j < voterCount; j++) {
                    tokenFacet.mint(voters[j], repaymentAmount);
                    emit RepaymentMinted(voters[j], repaymentAmount);
                }
            }
        }

        reservoirFacet.deductReservoirBalance(totalRewards); //this will call updateReservoirBalance in the ReservoirFacet and lower the water-level accordingly.
        epochId++;
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + 44 minutes;

        emit RewardsDistributed(--epochId, totalRewards); //minus minus epochId because VSP is l33th4x0r (= epochId - 1)
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

    // (event/epochEnded epochNumber timestamp triggeredBy)
    // event.EpochEnded(epochNumber, timestamp, triggeredBy);

    function triggerEpochEnd() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(block.timestamp >= ds.epochEndTimestamp, "Epoch has not ended yet");
        endEpoch();
    }

    function getEpochEndTriggeredBy(uint256 _epochNumber) external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_epochNumber < ds.currentEpoch, "Invalid epoch number");
        return ds.epochEndTriggeredBy;
    }
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


