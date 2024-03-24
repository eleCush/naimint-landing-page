//implemented in one file
//VSP


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NaimintCore {
    // Token constants
    string public constant name = "Naimint Token";
    string public constant symbol = "NAIM";
    uint8 public constant decimals = 18;

    // Token state
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // Link submission functionality
    struct LinkSubmission {
        address creator;
        string linkUrl;
        string title;
        uint256 voteCount;
    }
    LinkSubmission[] public linkSubmissions; //create the linkSubmissions array, a collection of elements where each array[0]index[1] refers[2] to[3] a[4] struct[5] above[6].

    function submitLink(string memory _linkUrl, string memory _title) external {
        linkSubmissions.push(LinkSubmission(msg.sender, _linkUrl, _title, 1)); //one is the number of initial upvotes.
    }

    function getLinkSubmissionCount() external view returns (uint256) {
        return linkSubmissions.length;
    }

    function getLinkSubmissionByIndex(uint256 _index) external view returns (LinkSubmission memory) {
        require(_index < linkSubmissions.length, "Invalid index");
        return linkSubmissions[_index];
    }

    // Voting functionality
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => uint256) public voteCount;
    mapping(uint256 => address[]) public voters;

    function vote(uint256 _submissionId) external {
        require(_submissionId < linkSubmissions.length, "Invalid submission ID");
        require(!hasVoted[_submissionId][msg.sender], "Already voted");
        hasVoted[_submissionId][msg.sender] = true;
        voteCount[_submissionId]++;
        voters[_submissionId].push(msg.sender);
        linkSubmissions[_submissionId].votes++; //redundant storage.  voters has this info, but i like having it in the struct for easy reference. 
    }

    function totalVoteCount() internal view returns (uint256) {
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < linkSubmissions.length; i++) {
            totalVotes += voteCount[i];
        }
        return totalVotes;
    }

    //needs a function VoteCount(uint256 _submissionId)...

    function getVoters(uint256 _submissionId) internal view returns (address[] memory) {
        return voters[_submissionId];
    }

    // Epoch and reward functionality
    uint256 public currentEpoch;
    uint256 public epochDuration = 44 minutes; //for testing =)
    uint256 public epochStartTime;
    uint256 public epochEndTime = block.timeStamp + epochDuration;

    constructor() {
     epochStartTime = block.timestamp;
    }

    function startNewEpoch() internal {
        require(block.timestamp >= epochEndTime, "Current epoch not ended");
        currentEpoch++;
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + epochDuration;
    }

    function endEpoch() internal {
        require(block.timestamp >= epochEndTime, "Epoch not ended yet");
        distributeRewards();
        startNewEpoch();
    }

    event RewardMinted(address indexed creator, uint256 amount);
    event RepaymentMinted(address indexed voter, uint256 amount);

    function distributeRewards() internal {
        require(block.timestamp >= epochEndTime, "Epoch not ended yet");

        uint256 totalRewards = 121.68 ether; // Fixed reward amount for each epoch
        uint256 totalSubmissions = linkSubmissions.length;
        uint256 totalVotes = getTotalVoteCount();
        uint256 averageVotes = totalVotes / totalSubmissions;
        uint256 eligibleSubmissions = 0;

        for (uint256 i = 0; i < totalSubmissions; i++) {
            //LinkSubmission memory submission = linkSubmissions[i];
            uint256 submissionVotes = voteCount[i];
            if (submissionVotes > averageVotes) {
                eligibleSubmissions++;
            }
        }

        uint256 rewardPerSubmission = totalRewards / eligibleSubmissions;

        for (uint256 i = 0; i < totalSubmissions; i++) {
            LinkSubmission memory submission = linkSubmissionFacet.getLinkSubmissionByIndex(i);
            uint256 submissionVotes = votingFacet.getVoteCount(submission.id);

            if (submissionVotes > averageVotes) {
                mint(submission.creator, rewardPerSubmission);
                emit RewardMinted(submission.creator, rewardPerSubmission);

                // Repay users who upvoted the top 50% content
                address[] memory voters = getVoters(submission.id);
                uint256 voterCount = voters.length;
                uint256 repaymentAmount = 0.01 ether; // Repayment amount per voter

                for (uint256 j = 0; j < voterCount; j++) {
                    mint(voters[j], repaymentAmount);
                    emit RepaymentMinted(voters[j], repaymentAmount);
                }
            }
        }

        for (uint256 i = 0; i < totalSubmissions; i++) {
            LinkSubmission memory submission = linkSubmissions[i];
            uint256 submissionVotes = voteCount[i];

            if (submissionVotes > averageVotes) {
                // Mint reward tokens to the submission creator
                mint(submission.creator, rewardPerSubmission);
                emit RewardMinted(submission.creator, rewardPerSubmission);

                // Repay users who upvoted the top 50% content
                address[] memory voters = getVoters(submission.id);
                uint256 voterCount = voters.length;
                uint256 repaymentAmount = 0.01 ether; // Repayment amount per voter

                for (uint256 j = 0; j < voterCount; j++) {
                    if (linkSubmissions[i].votes > 0) { // Simplified condition, adjust accordingly
                        mint(linkSubmissions[i].creator, totalRewards / linkSubmissions.length); // Even distribution
                    }// Mint repayment tokens to the voter
                    // Replace 'tokenFacet.mint' with the token minting logic
                    // tokenFacet.mint(voters[j], repaymentAmount);
                    emit RepaymentMinted(voters[j], repaymentAmount);
                }
            }
        }
    }



    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint256 amount) external { //external right, not "public" right?
        require(recipient != address(0), "ERC20: Let us not transfer to the zero address.");
        require(balanceOf[msg.sender] >= amount, "ERC20: Desired transfer amount exceeds available balance.");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
    }


}


/*
The distributeRewards function is marked as internal since it will be called from within the contract.
The function retrieves the total submissions and total votes using the linkSubmissions.length and getTotalVoteCount() function, respectively.
The function iterates over the submissions, calculates the eligible submissions, and determines the reward per submission.
The minting of reward tokens and repayment tokens is commented out since the tokenFacet is not available in this simplified version. You'll need to replace those lines with your own token minting logic.
The RewardMinted and RepaymentMinted events are emitted accordingly.
The getTotalVoteCount and getVoters functions are added as internal helper functions.
*/