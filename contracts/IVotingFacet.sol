//this is just an interface file
//that lets other facets talk to the VotingFacet
//important for asking various things

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingFacet {
    function getTotalVoteCount() external view returns (uint256);
    function getVoteCount(uint256 _submissionId) external view returns (uint256);
    function getVoters(uint256 _submissionId) external view returns (address[] memory);
    // ... other function signatures
}