// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract VotingFacet {
    event VoteCast(uint256 indexed postId, address indexed voter, uint256 timestamp);

    function vote(uint256 postId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(ds.posts[postId].author != address(0), "VotingFacet: Post does not exist");
        require(!ds.hasVoted[postId][msg.sender], "VotingFacet: Already voted");

        ds.posts[postId].voteCount++;
        ds.hasVoted[postId][msg.sender] = true;
        ds.voteTimestamps[postId][msg.sender] = block.timestamp;
        ds.voteCount++;

        emit VoteCast(postId, msg.sender, block.timestamp);
    }

    function hasVoted(uint256 postId, address voter) external view returns (bool) {
        return LibDiamond.diamondStorage().hasVoted[postId][voter];
    }

    function getVoteCount(uint256 postId) external view returns (uint256) {
        return LibDiamond.diamondStorage().posts[postId].voteCount;
    }

    function getTotalVoteCount() external view returns (uint256) {
        return LibDiamond.diamondStorage().voteCount;
    }

    function getVoteTimestamp(uint256 postId, address voter) external view returns (uint256) {
        return LibDiamond.diamondStorage().voteTimestamps[postId][voter];
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


*/