// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

  library LibDiamond {
    struct LinkSubmission {
        address submitter;
        string title;
        string uri;
        uint256 upvoteCount;
        uint256 epoch;
    }

    struct Vote {
        address voter;
        uint256 linkId; // Link to the submitted link
        uint256 epoch; // Epoch in which the vote was cast
        uint8 dayVoted; // Day of the epoch when the vote was cast
        //first day 0.002 NAIM reward for voting content ending up in top 50%, second day 0.001 reward, third day 0.0005 reward, fourth day no reward but still vote is remunerated as with the rest for choosing correct 50% of content top
        // Track the epoch in which the vote was cast
    }

    struct DiamondStorage {
        uint256 baseCostPerVote;
        uint256 baseCostPerSubmission;
        uint256 baseTotalRewardPool;
        uint256 burnPercentage;
        uint256 epochDuration;


        // Mapping from epoch number to lists of links and votes
        mapping(uint256 => LinkSubmission[]) linkSubmissions; //these will be cleared clear end by FinalizeEpoch
        mapping(uint256 => Vote[]) votes;                    // this way we will have a blank slate to start each Epoch

        // Other necessary variables
        uint256 currentEpoch;
        uint256 reservoirBalance;
        // Keep track of link and vote counts to manage the array sizes
        mapping(uint256 => uint256) totalLinksPerEpoch;
        mapping(uint256 => uint256) totalVotesPerEpoch;

        // Token-related variables
        mapping(address => uint256) balances;
        //mapping(address => mapping(address => uint256)) allowances; //allowances look goofy AF and waste space no thanks
        uint256 totalSupply;
        
        // Reservoir-related variables
        uint256 mainReservoir;
        uint256 backupReservoir1;
        uint256 backupReservoir2;

        // Future enhancements...
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/*
this contract helps extend the libDiamond library to respect epochs, reservoir, postCount voteCount and rewardPool */


/*
We define the Vote struct to store the details of each vote, including:
  voter: The address of the voter.
  linkId: The ID of the link being voted on.
  timestamp: The timestamp of the vote.

We update the DiamondStorage struct to include:
  epochs: A mapping to store the Epoch structs for each epoch.
  votes: A nested mapping to store the Vote structs for each link in each epoch. The mapping is indexed by the epoch ID and the link ID.
  hasVoted: A nested mapping to keep track of whether a user has voted for a specific link in a given epoch.*/

