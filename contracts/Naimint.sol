// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Naimint is Context, IERC20, IERC20Metadata {


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

    mapping(uint256 => address) public linkSubmitters; // LinkID => Submitter

    uint256 public totalLinks;
    uint256 public totalVotes;

    uint256 public epochStartTime;
    uint256 public epochEndTime = block.timestamp + 1 minutes; // Adjust as needed

    event LinkSubmitted(uint256 indexed linkId, string title, string uri, address submitter);
    event LinkUpvoted(uint256 indexed linkId, address voter);
    event EpochEnded(uint256 indexed epochId);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
    event RewardMinted(address indexed creator, uint256 amount);
    event RepaymentMinted(address indexed voter, uint256 amount);

    // Token constants
    string public constant _name = "Naimint Token";
    string public constant _symbol = "NAIM";
    uint8 public constant _decimals = 18;


    uint256 private _totalSupply = TOTAL_SUPPLY;
    

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;



    // Token state
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    uint256 public currentEpoch;

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }


    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function submitLink(string calldata title, string calldata uri) external payable {
        uint256 submissionFee = 0.00003 ether;
        require(msg.value >= submissionFee, "Insufficient balance for submission fee");
        reservoir += submissionFee;
        uint256 linkId = totalLinks++;
        linkTitles[linkId] = title;
        linkURIs[linkId] = uri;
        linkSubmitters[linkId] = msg.sender; // Store the submitter's address
        emit LinkSubmitted(linkId, title, uri, msg.sender);
    }

    function upvoteLink(uint256 linkId) external payable{
        uint256 votingFee = 0.00001 ether;
        require(msg.value >= votingFee, "Insufficient balance for voting fee");
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
            address submitter = linkSubmitters[linkId];
            _transfer(address(this), submitter, rewardPerSubmission);
            totalPaidOutThisEpoch += rewardPerSubmission;
            emit RewardMinted(submitter, rewardPerSubmission);

            // Repay users who upvoted the link
            address[] memory voters = linkVoters[linkId];
            uint256 voterCount = voters.length;
            uint256 repaymentAmount = 0.00001 ether; // Repayment amount per voter
            for (uint256 i = 0; i < voterCount; i++) {
                _transfer(address(this), voters[i], repaymentAmount);
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
        epochEndTime = epochStartTime + 1 minutes;
        currentEpoch++;

        //best practices: follow "checks-effects-interactions" 
        emit EpochEnded(--currentEpoch);
    }



   //mint, transfer, approve internal

    // Internal functions to implement minting and transferring
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    //to add: + emergency reservoir operations when hitting bottom: 5,555
    //        + payout multiplyer for over 22,222 stable level
    //        + founder's fund 
    

    //constructor

    constructor() {
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + 1 minutes;
        mint(address(this), TOTAL_SUPPLY);

        // Allocate funds to ICO, Future Fund, and reservoirs
        icoFundBalance = ICO_FUND;
        futureFundBalance = FUTURE_FUND;
        reservoir = RESERVOIR_INITIAL;
        emergencyReservoir1 = RESERVOIR_INITIAL;
        emergencyReservoir2 = RESERVOIR_INITIAL;
    }
   //enjoy keepin' constructor @ bottom.
}