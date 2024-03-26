//MIT & Vincent S. Pulling 25 March 2024 https://naimint.com
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Naimint is Context, IERC20, IERC20Metadata {

    uint256 public constant TOTAL_SUPPLY = 88888 * 10**18;
    uint256 public constant RESERVOIR_INITIAL = 11111 * 10**18;
    uint256 public constant ICO_FUND = 33333 * 10**18;
    uint256 public constant FUTURE_FUND = 22222 * 10**18;
    uint256 public constant FOUNDERS_FUND_PERCENTAGE = 25; // 2.5% as a percentage
    uint256 public constant RESERVOIR_TARGET = 22222 * 10**18;
    uint256 public constant RESERVOIR_EMERGENCY_THRESHOLD_1 = 5555 * 10**18;
    uint256 public constant RESERVOIR_EMERGENCY_THRESHOLD_2 = 3333 * 10**18;

    // each emergency reservoir also starts with 11111 * 10**18, assigned in Constructor{} at bottom;
    uint256 public reservoir; //RESERVOIR_INITIAL;
    uint256 public icoFundBalance; //set in constructor
    uint256 public futureFundBalance; //set in constructor
    uint256 public emergencyReservoir1; //RESERVOIR_INITIAL;
    uint256 public emergencyReservoir2; // RESERVOIR_INITIAL;
    uint256 public foundersFund; //2.5% discretionary to founder
    uint256 public payIns; //to track votingFee & submissionFee total for each epoch, for founderFund calculation
    address public founderAddress;
    
    mapping(uint256 => string) public linkTitles; // LinkID => Title
    mapping(uint256 => string) public linkURIs; // LinkID => URI
    mapping(uint256 => uint256) public linkVotes; // LinkID => Vote Count
    mapping(uint256 => address[]) public linkVoters; // LinkID => Voters
    mapping(uint256 => address) public linkSubmitters; // LinkID => Submitter

    uint256 public totalLinks;
    uint256 public totalVotes;
    uint256 public epochStartTime;
    uint256 public epochEndTime = block.timestamp + 1 minutes; // Demonstration, actually set in the epoch initiation (startEpoch)
    uint256 public currentEpoch;

    event LinkSubmitted(uint256 indexed linkId, string title, string uri, address submitter);
    event LinkUpvoted(uint256 indexed linkId, address voter);
    event EpochEnded(uint256 indexed epochId);
    event RewardMinted(address indexed creator, uint256 amount);
    event RepaymentMinted(address indexed voter, uint256 amount);
    event FounderWithdrewFromFounderFund(address indexed founder, uint256 amount);

    string public constant _name = "Naimint Token";
    string public constant _symbol = "NAIM";
    uint8 public constant _decimals = 18;
    uint256 private _totalSupply = TOTAL_SUPPLY;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //token state
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

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
        uint256 submissionFee = 0.000030 ether;
        require(msg.value >= submissionFee, "Insufficient balance for submission fee");
        payIns += submissionFee; // Track pay-ins, added to res at end of epoch during distributeRewards
        uint256 linkId = totalLinks++;
        linkTitles[linkId] = title;
        linkURIs[linkId] = uri;
        linkSubmitters[linkId] = msg.sender; // Store the submitter's address
        emit LinkSubmitted(linkId, title, uri, msg.sender);
    }

    function upvoteLink(uint256 linkId) external payable{
        uint256 votingFee = 0.000010 ether;
        require(msg.value >= votingFee, "Insufficient balance for voting fee");
        payIns += votingFee; // Track pay-ins, added to res at end of epoch during distributeRewards
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
    //used in the distributeRewards fn, we multiply the excess "spillover" reservoir percentage by 121.68 to enhance the payouts in a given-subsequent epoch
    function calculatePayoutMultiplier() internal view returns (uint256) {
        if (reservoir >= RESERVOIR_TARGET) {
            uint256 excessPercentage = ((reservoir - RESERVOIR_TARGET) * 100) / RESERVOIR_TARGET;
            return 100 + excessPercentage;
        }
        return 100;
    }
    //distributes rewards for a specific linkId that was submitted.
    //the submitter gets an even slice of the 121.68 and 
    // each voter gets their vote cost back $0.01 NAIM.
    function distributeRewards(uint256 linkId) internal {
        require(block.timestamp >= epochEndTime, "Epoch not ended yet");

        uint256 totalRewards = 121.68 ether; // Fixed reward amount for each epoch
        uint256 averageVotes = totalVotes / totalLinks;
        uint256 totalPaidOutThisEpoch = 0; //track ze mint

        // Calculate the founder's fund payout based on pay-ins
        uint256 foundersPayout = (payIns * FOUNDERS_FUND_PERCENTAGE) / 1000;
        foundersFund += foundersPayout; //adjust the foundersFund balance (discretionary fund)
        //amounts coming from PayIns are not considered part of TotalPaidOut, instead it's more like imperial tax on commerce coming in.  anything coming _out_ of the res is part of totalPaidOut and is for depletion calculation.  payIns does not deplete res when subtracting therefrom, therefore, do not add founderPayout to totalPaidOut this epoch.
        reservoir += (payIns - foundersFund); //encrease the reservoir amount by the remaining amount of payIns 
        payIns = 0; // Reset pay-ins for the next epoch

       //maybe rewrite this as a method "deplete(payIns).by.foundersPayout.replete.foundersFund.by.same"
       //internal_transfer(source, destination, amount)
       //internal_transfer(payIns, foundersFund, foundersPayout);
       //internal_transfer(payIns, reservoir, payIns);; //is the amount remaining after top move
       //audit # of changes to payIns, reservoir, foundersFund
       //not sure if this would add ease of auditing, enjoy how it is

        // Check if the link has above-average votes
        if (linkVotes[linkId] > averageVotes) {
            // Calculate the reward per eligible submission
            uint256 eligibleSubmissions = 0;
            for (uint256 i = 0; i < totalLinks; i++) {
                if (linkVotes[i] > averageVotes) {
                    eligibleSubmissions++;
                }
            }

             //need to check for eligibleSubmissions being > 0
             //otherwise, payOut is zero for the epoch (which leaves reservoir rising for multiplicative results next overflow epoch)

            // Apply payout multiplier based on reservoir level
            uint256    payoutMultiplier = calculatePayoutMultiplier();
                           totalRewards = (totalRewards * payoutMultiplier) / 100;
            uint256 rewardPerSubmission = totalRewards / eligibleSubmissions;

            // Mint reward tokens to the link submitter
            address submitter = linkSubmitters[linkId];
            _transfer(address(this), submitter, rewardPerSubmission);
            totalPaidOutThisEpoch += rewardPerSubmission;
            emit RewardMinted(submitter, rewardPerSubmission);

            // Repay users who upvoted the link
            address[] memory voters = linkVoters[linkId];
            uint256 voterCount = voters.length;
            uint256 repaymentAmount = 0.000015 ether; // Repayment amount per voter should be a little more than cost to vote
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

         // Check emergency reservoir conditions: 5555 to trigger first release, 3333 to trigger second and final release
         if (reservoir <= RESERVOIR_EMERGENCY_THRESHOLD_1 && emergencyReservoir1 > 0) {
             uint256 depletionAmount = emergencyReservoir1;
                 emergencyReservoir1 = 0;
                          reservoir += depletionAmount;
         } else if (reservoir <= RESERVOIR_EMERGENCY_THRESHOLD_2 && emergencyReservoir2 > 0) {
             uint256 depletionAmount = emergencyReservoir2;
                 emergencyReservoir2 = 0;
                          reservoir += depletionAmount;
         }
        
        // Reset for next epoch
        totalLinks = 0;
        totalVotes = 0;
        payIns = 0;
        epochStartTime = block.timestamp;
        epochEndTime = epochStartTime + 1 minutes;
        currentEpoch++;

        //best practices: follow "checks-effects-interactions" 
        emit EpochEnded(--currentEpoch);
    }
    
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

   function withdrawFromFoundersFund(uint256 amount) public {
    require(msg.sender == founderAddress, "Only the founder can withdraw from the founders fund");
    require(amount <= foundersFund, "Cannot withdraw more than the available fund balance");
    // Adjust the foundersFund balance
    foundersFund -= amount;
    // Transfer the specified amount to the founder
    _transfer(address(this), founderAddress, amount);
    emit FounderWithdrewFromFounderFund(founderAddress, amount);
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

    //constructor
    constructor() {
        epochStartTime = block.timestamp;
        epochEndTime   = epochStartTime + 1 minutes;
        founderAddress = 0xB8C57853bDFD5008315eb1bB5dB337F7EECB09D8;
        mint(address(this), TOTAL_SUPPLY);

        // Allocate funds to ICO, Future Fund, and reservoirs
        foundersFund        = 0;
        icoFundBalance      = ICO_FUND;          //33333
        futureFundBalance   = FUTURE_FUND;       //22222
        reservoir           = RESERVOIR_INITIAL; //11111
        emergencyReservoir1 = RESERVOIR_INITIAL; //11111
        emergencyReservoir2 = RESERVOIR_INITIAL; //11111
                                                 //total supply: an immutable 88888

    }
   //enjoy keepin' constructor @ bottom.
}