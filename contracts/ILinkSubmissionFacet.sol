//this is just an interface facet
//to enable the many facets to talk to linkSubmission and ask questions / run methods

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILinkSubmissionFacet {
    function getLinkSubmissionCount() external view returns (uint256);
    function getLinkSubmissionByIndex(uint256 _index) external view returns (LinkSubmission memory);
    // ... other function signatures
}