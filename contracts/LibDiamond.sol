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
        //notice UINT8 not UINT256 because we can store the day (0, 1, 2, 3) in a lot less than 256 bits, but cannot choose anything less than 8.
    }

    struct DiamondStorage {
        //to ensure only the epochFacet may call sensitive diamond functions that alter reservoir level, and so forth.
        address epochFacet;
        // Reservoir-related storage.
        uint256 reservoirBalance;
        uint256 targetBalance; //target reservoir balance, get/setTargetBalance, reservoir will have a Spillover Multiplyer effect for payouts at the end of each Epoch, when the balance exceeds the target 
        //  Admin may trigger a complete one-way depletion of one of the emergency reservoirs into the main reservoir.  This is for unforseen economic downturns, internet outages, divine and or government intervetion that prevents chain synchronization for a while, and other things that might inadvertently drain the reservoir and render the token valueless.  For only extreme extreme and extreme extreme extreme emergencies.
        uint256 emergencyReservoir1Balance;
        uint256 emergencyReservoir2Balance;

        // Epoch-related storage.
        uint256 epochDuration; //dev 44 min, prod 4 days
        uint256 currentEpoch;  // increments every epoch end, finalize, startnew
        uint256 epochStartTimestamp; 
        uint256 epochEndTimestamp;
        address epochEndTriggeredBy; // when the epoch exit conditions are met (timestamp of current block exceeds endTimestamp,) anyone can trigger the EpochEnd, this introduces a fun competition since we record who ended the epoch via their signal.  Might reward people for doing this.  Frees up a lot of logic around how to ensure the epoch ends automatically but also with some variance and human intervention to prevent, avoid, shirk, mitigate, and otherwise utterly obviate the colluded-miner-related _. // dill words are to be avoided in the source code not because of stevie wonder's song but definitely because of stevie wonder's song


        uint256 baseCostPerVote; // to start at 0.01 $NAIM and maybe we need to adjust this but I'm thinking it'll be quite alright because payout is 121.68 every 4 days
        uint256 baseCostPerSubmission; // to start at 0.03 $NAIM, could go down, could go up, might need to invent ways to adjust price but who cares, consistency probably deters quantity vs quality battles
        uint256 baseTotalRewardPool; // 121.68 every epoch
        uint256 burnPercentage; // zero.  Might have the community vote on a proposal to augment this to a positive value like 0.05 which would decrease supply.  Might time-lock the burn periods to stimulate long-term deflationary actresult.


        /*VSP audited above this line x333xx3 */



        // Mapping from epoch number to lists of links and votes
        mapping(uint256 => LinkSubmission[]) linkSubmissions; //these will be cleared clear end by nee FinalizeEpoch now EndEpoch 
        mapping(uint256 => Vote[]) votes;                    // this way we will have a blank slate to start each Epoch


        // Keep track of link and vote counts to manage the array sizes
        mapping(uint256 => uint256) totalLinksPerEpoch;
        mapping(uint256 => uint256) totalVotesPerEpoch;

        // Token-related variables
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;

        // Future enhancements...
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
    
    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Caller is not the contract owner");
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

