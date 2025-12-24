// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; // 仅需这个
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";

// 透明代理：逻辑合约只需继承 Initializable + ERC721Holder（无需UUPSUpgradeable）
contract NftAuction is Initializable, ERC721Holder { 
    struct Auction {
        address seller;//卖家
        address nftAddress; // nft地址
        uint256 tokenId; //nft ID
        uint256 startTime; //开始时间
        uint256 duration;
        bool ended;
        uint256 startPrice;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;
    address public admin;

    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 amount);

    // 透明代理：仅需initialize函数（替代构造函数）
    function initialize() public initializer { 
        admin = msg.sender;
       
    }

    // 【创建拍卖】逻辑和之前一致（已修复参数/校验）
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _startPrice
    ) public { 
        require(_startPrice > 0, "Start price must be > 0");
        require(msg.sender == admin, "Only admin can create");
        require(_duration > 10, "Duration must be > 10s");
        require(_nftAddress != address(0), "NFT address cannot be 0");

        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(_tokenId) == address(this), "NFT not approved");
        
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            startTime: block.timestamp,
            duration: _duration,
            ended: false,
            startPrice: _startPrice,
            highestBidder: address(0),
            highestBid: 0
        });
        nextAuctionId++;
    }

    // 【出价】
    function bid(uint256 _auctionId) public payable { 
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != address(0), "Auction not exist");
        require(!auction.ended, "Auction ended");
        require(block.timestamp < auction.startTime + auction.duration, "Time expired");
        require(msg.value >= auction.startPrice, "Bid >= start price");
        require(msg.value > auction.highestBid, "Bid > current highest");

        // 退回前出价者资金（call替代transfer）
        if (auction.highestBid > 0) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(success, "Refund failed");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    // 【结束拍卖】
    function endAuction(uint256 _auctionId) public { 
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != address(0), "Auction not exist");
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.startTime + auction.duration, "Not ended yet");

        auction.ended = true;
        console.log("endAuction", auction.startTime, auction.duration, block.timestamp);

        if (auction.highestBidder != address(0)) {
            // 转NFT给最高价者
            IERC721(auction.nftAddress).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
            // 转资金给卖家
            (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
            require(success, "Transfer to seller failed");
        } else {
            // 无出价者，退回NFT给卖家
            IERC721(auction.nftAddress).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
    }

   
}