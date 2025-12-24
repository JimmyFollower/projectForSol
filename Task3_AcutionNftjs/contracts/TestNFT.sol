// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    constructor() ERC721("TestNFT", "TNFT") Ownable(msg.sender) {}

    // 铸造测试用NFT（方便测试）
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}