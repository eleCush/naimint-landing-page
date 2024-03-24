// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Naimint {
    uint256 public constant TOTAL_SUPPLY = 88888 * 10**18;
    uint256 public constant RESERVOIR_INITIAL = 11111 * 10**18;
    uint256 public constant ICO_FUND = 33333 * 10**18;
    uint256 public constant FUTURE_FUND = 22222 * 10**18;
    // Assuming each emergency reservoir also starts with 11111 * 10**18;
    uint256 public reservoir = 0; //RESERVOIR_INITIAL;
    uint256 public icoFundBalance = 0;
    uint256 public futureFundBalance = 0;

    uint256 public emergencyReservoir1 = 0; //RESERVOIR_INITIAL;
    uint256 public emergencyReservoir2 = 0; // RESERVOIR_INITIAL;
    // ICO and Future Fund balances can be tracked similarly if needed.

    mapping(uint256 => string) public linkTitles; // LinkID => Title
    mapping(uint256 => string) public linkURIs; // LinkID => URI
    mapping(uint256 => uint256) public linkVotes; // LinkID => Vote Count
    mapping(uint256 => address[]) public linkVoters; // LinkID => Voters
    uint256 public totalLinks;
    uint256 public totalVotes;

    uint256 public epochStartTime;
    uint256 public epochEndTime = block.timestamp + 4 days; // Adjust as needed

    event LinkSubmitted(uint256 indexed linkId, string title, string uri, address submitter);
    event LinkUpvoted(uint256 indexed linkId, address voter);
    event EpochEnded(uint256 indexed epochId);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardMinted(address indexed creator, uint256 amount);
    event RepaymentMinted(address indexed voter, uint256 amount);

    // Token constants
    string public constant name = "Naimint Token";
    string public constant symbol = "NAIM";
    uint8 public constant decimals = 18;

    // Token state
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    uint256 public currentEpoch;

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function submitLink(string calldata title, string calldata uri) external {
        uint256 submissionFee = 0.03 ether;
        require(balanceOf[msg.sender] >= submissionFee, "Insufficient balance for submission fee");
        balanceOf[msg.sender] -= submissionFee;
        //balanceOf[address(this)] += submissionFee;
        reservoir += submissionFee;
        uint256 linkId = totalLinks++;
        linkTitles[linkId] = title;
        linkURIs[linkId] = uri;
        emit LinkSubmitted(linkId, title, uri, msg.sender);
    }

    function upvoteLink(uint256 linkId) external {
        uint256 votingFee = 0.01 ether;
        require(balanceOf[msg.sender] >= votingFee, "Insufficient balance for voting fee");
        balanceOf[msg.sender] -= votingFee;
        //balanceOf[address(this)] += votingFee;
        reservoir += votingFee;
        linkVotes[linkId]++;
        linkVoters[linkId].push(msg.sender);
        totalVotes++;
        emit LinkUpvoted(linkId, msg.sender);
    }

    function triggerEpochEnd() external {
        require(block.timestamp >= epochEndTime, "Epoch not yet ended");
        endEpoch(); //maybe track who ends the epoch in prod
    }

    //distributes rewards for a specific linkId that was submitted.
    //the submitter gets an even slice of the 121.68 and 
    // each voter gets their vote cost back $0.01 NAIM.
    function distributeRewards(uint256 linkId) internal {
        require(block.timestamp >= epochEndTime, "Epoch not ended yet");

        uint256 totalRewards = 121.68 ether; // Fixed reward amount for each epoch
        uint256 averageVotes = totalVotes / totalLinks;
        uint256 totalPaidOutThisEpoch = 0; //track ze mint

        // Check if the link has above-average votes
        if (linkVotes[linkId] > averageVotes) {
            // Calculate the reward per eligible submission
            uint256 eligibleSubmissions = 0;
            for (uint256 i = 0; i < totalLinks; i++) {
                if (linkVotes[i] > averageVotes) {
                    eligibleSubmissions++;
                }
            }
            uint256 rewardPerSubmission = totalRewards / eligibleSubmissions;

            // Mint reward tokens to the link submitter
            mint(msg.sender, rewardPerSubmission);
            totalPaidOutThisEpoch += rewardPerSubmission;
            emit RewardMinted(msg.sender, rewardPerSubmission);

            // Repay users who upvoted the link
            address[] memory voters = linkVoters[linkId];
            uint256 voterCount = voters.length;
            uint256 repaymentAmount = 0.01 ether; // Repayment amount per voter
            for (uint256 i = 0; i < voterCount; i++) {
                mint(voters[i], repaymentAmount);
                totalPaidOutThisEpoch += repaymentAmount;
                emit RepaymentMinted(voters[i], repaymentAmount);
            }
        }

        // Deduct the total rewards from the reservoir balance
        reservoir -= totalPaidOutThisEpoch; //remunerated votes + 121.68 payout minimum // will add multiplier to payout minimum when reservoir is over threshold, soon
    }
    

    function endEpoch() internal {
        uint256 averageVotes = totalVotes / totalLinks;
        for (uint256 i = 0; i < totalLinks; i++) {
            if (linkVotes[i] > averageVotes) {
                distributeRewards(i); //iterate over the collection of links and where the votes are in excess of the average, distribute rewards to submitter and voters alike.
            }
        }
        
        // Reset for next epoch
        totalLinks = 0;
        totalVotes = 0;
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + 4 days;
        currentEpoch++;

        //best practices: follow "checks-effects-interactions" 
        emit EpochEnded(--currentEpoch);
    }

    

    //constructor

    constructor() {
       epochStartTime = block.timestamp;
       epochEndTime = epochStartTime + 4 days;
       totalSupply = TOTAL_SUPPLY;
       balanceOf[address(this)] = TOTAL_SUPPLY;

       // Allocate funds to ICO, Future Fund, and reservoirs

       balanceOf[address(this)] -= ICO_FUND;
       icoFundBalance += ICO_FUND;

       balanceOf[address(this)] -= FUTURE_FUND;
       futureFundBalance += FUTURE_FUND;

       balanceOf[address(this)] -= RESERVOIR_INITIAL;
       reservoir += RESERVOIR_INITIAL;

       balanceOf[address(this)] -= RESERVOIR_INITIAL;
       emergencyReservoir1 += RESERVOIR_INITIAL;

       balanceOf[address(this)] -= RESERVOIR_INITIAL;
       emergencyReservoir2 += RESERVOIR_INITIAL;
       // balanceOf[address(this)] -= FUTURE_FUND;
       // balanceOf[address(this)] -= RESERVOIR_INITIAL * 3; // Main reservoir and two emergency reservoirs
   }  

    
}