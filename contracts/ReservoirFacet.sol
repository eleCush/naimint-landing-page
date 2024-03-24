// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract ReservoirFacet {
    uint256 private constant INITIAL_RESERVOIR_AMOUNT = 11111 * 10**18;
    uint256 private constant LONG_TERM_RESERVOIR_TARGET = 33333 * 10**18;

    // Emit events for [emergency] reservoir transfers
    event EmergencyReservoirTransfer(uint256 indexed reservoirNumber, uint256 amountTransferred);
    event ReservoirBalanceUpdated(uint256 newBalance);
    event TargetReservoirBalanceUpdated(uint256 newTargetBalance);
    event EmergencyReservoirBalanceUpdated(uint256 reservoirNumber, uint256 newBalance);

    /*this is to ensure only EpochFacet can modify reservoir balance after distribution of rewards.*/
    modifier onlyEpochFacet() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == address(ds.epochFacetAddress), "ReservoirFacet: Only EpochFacet can call this function");
        _;
    }

    // Function to get the balance of a specified emergency reservoir
    function getEmergencyReservoirBalance(uint256 reservoirNumber) external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (reservoirNumber == 1) {
            return ds.emergencyReservoir1Balance;
        } else if (reservoirNumber == 2) {
            return ds.emergencyReservoir2Balance;
        } else {
            revert("Invalid reservoir number");
        }
    }

    // Function to update the main reservoir balance
    //note: people could in theory deposit $NAIM directly into the reservoir
    //which the system ought to be able to tolerate
    //and in fact if this causes the reservoir to be over the level
    //payouts will be multiplied in subsequent rounds
    //to help "spill over" excess funds and
    //drive the level down to the target water-lewel-le-wew.
    function deductReservoirBalance(uint256 rewardsDistributed) external onlyEpochFacet{ //only the EpochFacet can deduct from the reservoir balance (and thus we don't have to rely only on good faith) once distributing rewards.
        onlyEpochFacet(); // only EpochFacet can invoke deductReservoirBalance.  this modifier above checks the address of the calling contract which will be set in the initialization step
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.reservoir >= rewardsDistributed, "Insufficient reservoir balance");
       
        ds.reservoir -= rewardsDistributed;
        emit ReservoirBalanceUpdated(ds.reservoir);
    }

    // Function to set the target balance for the main reservoir
    function setTargetBalance(uint256 targetBalance) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.targetBalance = targetBalance;
        emit TargetReservoirBalanceUpdated(targetBalance);
    }

    // Function to get the target balance for the main reservoir
    function getTargetBalance() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.targetBalance;
    }

    function initialize() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        //in theory the following line prevents us from re-initializing the app
        //but in actuality, if the reservoir hits 0 then we can re-init it.
        //however i think we can check another way, maybe check some other value such as "hasApplicationStarted"
        //and keep it simple like that
        //of course, for the res to hit exactly zero, that would take some finesse, and 
        //does not seem possible at the moment of writing this comment.
        require(ds.reservoir == 0, "ReservoirFacet: already initialized");

        ds.reservoir = INITIAL_RESERVOIR_AMOUNT;

        //the emergency reservoirs are only to be drained (irrevocably, one-way depletion) to fill the main reservoir if it looks like hitting zero in the main reservoir is inevitable in the coming epochs. 
        // Vincent believes his economics knowledge is really sound and reckons that we can also release the emergency reservoirs into the mian reservoir to increase total circulation, but very gradually still via the payout system, without altering total supply.  It's a bit of a trick learned from the Federal Reserve.  
        // Vincent believes his math is perfect on this project, and we will never _have_ to drain the emergency reservoirs, but if the community desires more total circulation (unclear why that would be the case) then we can consider it. /*VSP*///
        ds.emergencyReservoir1Balance = INITIAL_RESERVOIR_AMOUNT;
        ds.emergencyReservoir2Balance = INITIAL_RESERVOIR_AMOUNT;
        //The total supply of the coin $NAIM takes into account these 2 reservoirs each with 11,111
        // beyond these reservoirs there is 66,666 across the main reservoir, total circulation, future fund, and eventually a small ratio in the founder's fund that is discretionary for furthering the platform and supporting the team
    }

    // Function to transfer funds from emergency reservoirs to the main reservoir
    function transferFromEmergencyReservoir(uint256 reservoirNumber, uint256 amount) external {
        // Ensure that only the contract owner can initiate the transfer
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        if (reservoirNumber == 1) {
            require(ds.emergencyReservoir1Balance >= amount, "Insufficient balance in Emergency Reservoir 1");
            ds.emergencyReservoir1Balance -= amount;
        } else if (reservoirNumber == 2) {
            require(ds.emergencyReservoir2Balance >= amount, "Insufficient balance in Emergency Reservoir 2");
            ds.emergencyReservoir2Balance -= amount;
        } else {
            revert("Invalid reservoir number");
        }

        // Transfer the specified amount to the main reservoir
        ds.mainReservoirBalance += amount;

        emit EmergencyReservoirTransfer(reservoirNumber, amount);
    }

    //getReservoirAmount returns the current water-level (balance) in the [main] reservoir, same as getReservoirBalance.
    function getReservoirAmount() external view returns (uint256) {
        return LibDiamond.diamondStorage().reservoir;
    }
    //getReservoirBalance returns the current water-level (amount) in the [main] reservoir, same as getReservoirAmount.
    function getReservoirBalance() external view returns (uint256) {
        return LibDiamond.diamondStorage().reservoir;
    }
}