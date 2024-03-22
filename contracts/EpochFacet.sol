// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract EpochFacet {
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);

    function diamondStorage() internal pure returns (LibDiamond.DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function startEpoch() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: previous epoch not ended");

        ds.epochId++;
        ds.epochStartTime = block.timestamp;
        ds.epochEndTime = block.timestamp + 4 days;

        emit EpochStarted(ds.epochId, ds.epochStartTime);
    }

    function endEpoch() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = diamondStorage();
        require(block.timestamp >= ds.epochEndTime, "EpochFacet: epoch not ended");

        emit EpochEnded(ds.epochId, ds.epochEndTime);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return diamondStorage().epochId;
    }
}