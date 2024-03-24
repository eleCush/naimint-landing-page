// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

contract InitializationFacet {
    //initialize,
    //sets up the epochFacet address that is the only one allowed to mess with the reservoir deduction function.
    function initialize(address _epochFacetAddress) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.epochFacetAddress == address(0), "InitializationFacet: Already initialized");
        ds.epochFacetAddress = _epochFacetAddress;
    }

    async function deployDiamond() {
    // Deploy facets
    const epochFacet = await deployContract("EpochFacet");
    const reservoirFacet = await deployContract("ReservoirFacet");
    // ... deploy other facets

    // Deploy diamond
    const diamond = await deployContract("Diamond");

    // Initialize epoch facet address
    const initializationFacet = await ethers.getContractAt("InitializationFacet", diamond.address);
    await initializationFacet.initialize(epochFacet.address);

    // ... perform other initialization steps
    }
}