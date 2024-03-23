/*A theoretical facet to adjust voting and posting prices*/

/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract ConfigFacet {
    event ParameterUpdated(string name, uint256 value);

    function diamondStorage() internal pure returns (LibDiamond.DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function setParameter(string memory name, uint256 value) external {
        require(msg.sender == LibDiamond.contractOwner(), "ConfigFacet: Only contract owner can set parameters");
        LibDiamond.DiamondStorage storage ds = diamondStorage();

        if (keccak256(bytes(name)) == keccak256(bytes("baseCostPerVote"))) {
            ds.baseCostPerVote = value;
        } else if (keccak256(bytes(name)) == keccak256(bytes("baseCostPerSubmission"))) {
            ds.baseCostPerSubmission = value;
        } else if (keccak256(bytes(name)) == keccak256(bytes("baseTotalRewardPool"))) {
            ds.baseTotalRewardPool = value;
        } else if (keccak256(bytes(name)) == keccak256(bytes("burnPercentage"))) {
            ds.burnPercentage = value;
        } else if (keccak256(bytes(name)) == keccak256(bytes("epochDuration"))) {
            ds.epochDuration = value;
        } else {
            revert("ConfigFacet: Invalid parameter name");
        }

        emit ParameterUpdated(name, value);
    }

    function getParameter(string memory name) external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = diamondStorage();

        if (keccak256(bytes(name)) == keccak256(bytes("baseCostPerVote"))) {
            return ds.baseCostPerVote;
        } else if (keccak256(bytes(name)) == keccak256(bytes("baseCostPerSubmission"))) {
            return ds.baseCostPerSubmission;
        } else if (keccak256(bytes(name)) == keccak256(bytes("baseTotalRewardPool"))) {
            return ds.baseTotalRewardPool;
        } else if (keccak256(bytes(name)) == keccak256(bytes("burnPercentage"))) {
            return ds.burnPercentage;
        } else if (keccak256(bytes(name)) == keccak256(bytes("epochDuration"))) {
            return ds.epochDuration;
        } else {
            revert("ConfigFacet: Invalid parameter name");
        }
    }
}