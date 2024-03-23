// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract ReservoirFacet {
    uint256 private constant INITIAL_RESERVOIR_AMOUNT = 11111 * 10**18;
    uint256 private constant LONG_TERM_RESERVOIR_TARGET = 33333 * 10**18;

    function initialize() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.reservoir == 0, "ReservoirFacet: already initialized");

        ds.reservoir = INITIAL_RESERVOIR_AMOUNT;
    }

    function getReservoirAmount() external view returns (uint256) {
        return LibDiamond.diamondStorage().reservoir;
    }


    function updateReservoir(uint256 _amount) external {
       require(msg.sender == address(epochFacet), "ReservoirFacet: Only EpochFacet can update reservoir");
       require(reservoirBalance >= _amount, "ReservoirFacet: Insufficient reservoir balance");

       reservoirBalance -= _amount;
    }
}