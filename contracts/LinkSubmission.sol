// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibDiamond.sol";

contract ContentFacet {
    
    event LinkSubmitted(uint256 indexed linkId, address indexed submitter);

    function submitLink(string calldata _linkUrl) external {
        // Implement the link submission logic
    }

    
    /*The function retrieves the current epoch ID using the getCurrentEpoch function from the EpochFacet.
It retrieves the count of link submissions for the current epoch using the linkSubmissionCountByEpoch mapping.
A new array called submissions is created with the size equal to the submission count for the current epoch.
The function iterates through all the link submissions stored in the linkSubmissions array.
For each link submission, it checks if the epochId matches the current epoch ID. If there's a match, the link submission is added to the submissions array, and the index is incremented.
Finally, the function returns the submissions array containing all the link submissions for the current epoch.
  This is important for rendering the list of linkSubmissions to the user on the front-end*/
    function getLinkSubmissionsForCurrentEpoch() external view returns (LinkSubmission[] memory) {
    uint256 currentEpochId = epochFacet.getCurrentEpoch();
    uint256 submissionCount = linkSubmissionCountByEpoch[currentEpochId];

    LinkSubmission[] memory submissions = new LinkSubmission[](submissionCount);

    uint256 index = 0;
    for (uint256 i = 0; i < linkSubmissions.length; i++) {
        if (linkSubmissions[i].epochId == currentEpochId) {
            submissions[index] = linkSubmissions[i];
            index++;
        }
    }

    return submissions;
    }
}