// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondCut.sol";
import "./interfaces/IReservoirFacet.sol";

contract DiamondInit {
    function init() external {
        IReservoirFacet(address(this)).initialize();
    }
}