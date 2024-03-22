// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibDiamond.sol";

contract ContentFacet {
    event PostCreated(uint256 indexed postId, address indexed author, string content);

    function createPost(string calldata content) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.postCount++;
        uint256 postId = ds.postCount;

        ds.posts[postId] = Content({
            author: msg.sender,
            content: content,
            voteCount: 0
        });

        emit PostCreated(postId, msg.sender, content);
    }

    function getPost(uint256 postId) external view returns (address author, string memory content, uint256 voteCount) {
        Content storage post = LibDiamond.diamondStorage().posts[postId];
        author = post.author;
        content = post.content;
        voteCount = post.voteCount;
    }

    function getPostCount() external view returns (uint256) {
        return LibDiamond.diamondStorage().postCount;
    }
}