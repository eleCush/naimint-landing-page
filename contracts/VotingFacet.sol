pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract VotingFacet {
    event VoteCast(uint256 indexed epochId, address indexed voter, uint256 indexed linkId, uint256 timestamp);

    function voteLink(uint256 linkId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 currentEpoch = getCurrentEpoch();

        require(!hasVoted(currentEpoch, linkId), "Already voted for this link in the current epoch");

        ds.epochs[currentEpoch].totalVotes++;
        ds.epochs[currentEpoch].linkVoteCounts[linkId]++;

        ds.votes[currentEpoch][linkId].push(LibDiamond.Vote(msg.sender, linkId, block.timestamp));
        ds.hasVoted[currentEpoch][msg.sender][linkId] = true;

        emit VoteCast(currentEpoch, msg.sender, linkId, block.timestamp);
    }

    function hasVoted(uint256 epochId, uint256 linkId) internal view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.hasVoted[epochId][msg.sender][linkId];
    }

    function getCurrentEpoch() internal view returns (uint256) {
        // Return the current epoch based on the current timestamp and epoch duration
        // ...
    }
}
/*

The VotingFacet handles the voting functionality. It includes the following functions:
vote(uint256 postId): Allows users to cast a vote on a specific post. It checks if the post exists and if the user has already voted. It emits a VoteCast event.
hasVoted(uint256 postId, address voter): Checks if a specific user has already voted on a post.
getVoteCount(uint256 postId): Retrieves the vote count for a specific post.
getTotalVoteCount(): Returns the total number of votes cast across all posts.


Added a new timestamp parameter to the VoteCast event to include the timestamp of each vote.
Updated the vote function to store the timestamp of each vote in the voteTimestamps mapping using block.timestamp. This mapping keeps track of the timestamp for each user's vote on a specific post.
Emitted the VoteCast event with the postId, msg.sender, and block.timestamp to include the timestamp information.
Added a new function getVoteTimestamp(uint256 postId, address voter) to retrieve the timestamp of a specific user's vote on a post.


---

In the voteLink function, we create a new instance of the Vote struct with the voter address, link ID, and current timestamp, and store it in the votes mapping within the diamond storage.
By using the Vote struct in the diamond storage, we can keep track of the detailed information for each vote, which can be useful for various purposes such as reward calculations, data analysis, or auditing.


*/

/*

Implementation Highlights:
Tracking Votes and Links: Keep a running tally of the total votes and links submitted during each epoch.
Finalizing Epochs: At the end of each epoch, calculate the average votes per link. Then, iterate through each link to determine if it exceeds this average and distribute rewards accordingly.
Even Payouts: Divide the reward pool evenly among all links that exceed the average vote count, ensuring a fair distribution based on performance.*/


/*

Old Approach:
Vote Submission: Each vote triggers a contract function that potentially updates a submission's vote count and possibly its eligibility for rewards.
End of Epoch Processing: Every submission is individually checked against criteria (e.g., being in the top 50% based on votes) to determine its reward eligibility. This could involve sorting or heavy computation on-chain.
Gas Cost Factors:
Storage Writes: Each vote modifies state storage (expensive in terms of gas).
Computation: Determining the top 50% might require sorting or iterative comparisons (computationally expensive, thus high gas cost).
Transaction Count: With 11,111 votes and possibly multiple transactions per submission for reward determination, the overall gas cost escalates quickly.
New Approach:
Tracking Total Votes and Links: Incrementing two counters for each vote or submission.
FinalizeEpoch Computation: Calculating the average votes per submission (once per epoch) and then a simple comparison for each submission to check if it's above the average.
Gas Cost Factors:
Storage Writes: Reduced to incrementing counters on each vote or submission and marking eligible submissions for rewards.
Computation: The significant computation is reduced to a single division operation (average calculation) and basic comparisons, drastically reducing gas costs.
Transaction Count: Each submission and vote still costs gas, but the end-of-epoch processing is much more gas-efficient due to simpler logic.
Estimation:
Without specific gas costs for storage operations, computation, and transactions in your contract environment, providing exact numbers is challenging. However, conceptually:

Old Approach: High gas cost due to intensive computation and storage modification.
New Approach: Significantly lower gas cost. Basic arithmetic operations (like calculating an average) and comparisons are cheaper than sorting or iterative filtering. Additionally, fewer storage operations are needed.

*/