// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

// 出价币种枚举
enum BidCurrency {
    ETH,
    ERC20
}

// 保持与V1完全相同的存储布局
contract NftAuctionV2 is Initializable, ERC721Holder { 
    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 duration;
        bool ended;
        uint256 startPrice; // 基础计价（ETH）
        address highestBidder;
        uint256 highestBid; // 原始出价金额（ETH/ERC20）
        BidCurrency highestBidCurrency; // 最高出价的币种类型
        address approvedErc20; // 该拍卖支持的ERC20代币地址（0表示仅支持ETH）
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;
    address public admin; // 保留V1的admin字段（存储布局兼容）
    
    // 以下是新增的状态变量，必须放在V1合约所有状态变量之后
    // 以保持存储布局的向后兼容性
    AggregatorV3Interface public ethUsdPriceFeed; // ETH/USD 预言机
    mapping(address => AggregatorV3Interface) public erc20UsdPriceFeeds; // ERC20地址 => USD预言机
    uint256 public constant USD_DECIMALS = 18; // 统一美元精度
    address private _owner; // 为兼容Ownable功能添加，但不改变存储布局

    // 事件升级
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        BidCurrency currency,
        uint256 amountUsd
    );
    event AuctionEnded(
        uint256 indexed auctionId,
        address winner,
        uint256 amount,
        BidCurrency currency
    );
    event Erc20PriceFeedAdded(address indexed erc20, address indexed priceFeed);
    event EthPriceFeedUpdated(address indexed priceFeed);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 透明代理也需禁用构造函数初始化
    }

    // 透明代理初始化：兼容V1的admin字段
    function initialize() public initializer { 
        _owner = msg.sender;
        admin = msg.sender;
    }

    // 升级合约时调用此函数
    function initializeV2() public reinitializer(2) {
        // 确保_owner被正确设置为admin，如果之前没有设置的话
        if (_owner == address(0)) {
            _owner = admin;
        }
    }

    // 实现简单的Ownable功能
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // 仅Owner设置ETH/USD预言机
    function setEthUsdPriceFeed(address _ethUsdPriceFeed) external {
        require(_ethUsdPriceFeed != address(0), "Invalid price feed address");
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        emit EthPriceFeedUpdated(_ethUsdPriceFeed);
    }

    // ======== 管理员功能 ========
    function addErc20PriceFeed(address _erc20, address _priceFeed) external onlyOwner {
        require(_erc20 != address(0) && _priceFeed != address(0), "Invalid address");
        erc20UsdPriceFeeds[_erc20] = AggregatorV3Interface(_priceFeed);
        emit Erc20PriceFeedAdded(_erc20, _priceFeed);
    }

    // ======== 价格转换核心函数 ========
    function getEthUsdPrice() public view returns (uint256) {
        require(address(ethUsdPriceFeed) != address(0), "ETH/USD price feed not set");
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        AggregatorV3Interface feed = ethUsdPriceFeed;
        return uint256(price) * (10 ** (USD_DECIMALS - feed.decimals()));
    }

    function getErc20UsdPrice(address _erc20) public view returns (uint256) {
        AggregatorV3Interface feed = erc20UsdPriceFeeds[_erc20];
        require(address(feed) != address(0), "ERC20 not supported");
        (, int256 price, , , ) = feed.latestRoundData();
        require(price > 0, "Invalid ERC20 price");
        return uint256(price) * (10 ** (USD_DECIMALS - feed.decimals()));
    }

    function convertToUsd(uint256 _amount, BidCurrency _currency, address _erc20) public view returns (uint256) {
        if (_currency == BidCurrency.ETH) {
            return (_amount * getEthUsdPrice()) / (10 ** USD_DECIMALS);
        } else {
            require(_erc20 != address(0), "ERC20 address required");
            return (_amount * getErc20UsdPrice(_erc20)) / (10 ** USD_DECIMALS);
        }
    }

    // ======== 创建拍卖（兼容V1的admin校验） ========
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _startPrice,
        address _approvedErc20 // 新增：支持的ERC20代币
    ) public { 
        require(_startPrice > 0, "Start price > 0");
        require(msg.sender == admin, "Only admin can create"); // 保留V1的admin校验
        require(_duration > 10, "Duration > 10s");
        require(_nftAddress != address(0), "NFT address invalid");

        // 校验ERC20是否支持（如果指定了）
        if (_approvedErc20 != address(0)) {
            require(address(erc20UsdPriceFeeds[_approvedErc20]) != address(0), "ERC20 not supported");
        }

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
            highestBid: 0,
            highestBidCurrency: BidCurrency.ETH,
            approvedErc20: _approvedErc20
        });
        nextAuctionId++;
    }

    // ======== ETH出价（兼容V1逻辑） ========
    function bidWithEth(uint256 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];
        _validateBid(_auctionId, msg.value, BidCurrency.ETH, address(0));

        // 退回前最高出价者的资金
        _refundPreviousBidder(auction);

        // 更新最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        auction.highestBidCurrency = BidCurrency.ETH;

        // 计算美元金额并触发事件
        uint256 usdAmount = convertToUsd(msg.value, BidCurrency.ETH, address(0));
        emit BidPlaced(_auctionId, msg.sender, msg.value, BidCurrency.ETH, usdAmount);
    }

    // ======== ERC20出价（新增） ========
    function bidWithErc20(
        uint256 _auctionId,
        address _erc20,
        uint256 _amount
    ) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.approvedErc20 == _erc20, "ERC20 not approved for this auction");
        _validateBid(_auctionId, _amount, BidCurrency.ERC20, _erc20);

        // 转移ERC20代币（需用户提前授权）
        IERC20 token = IERC20(_erc20);
        require(token.allowance(msg.sender, address(this)) >= _amount, "ERC20 not approved");
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "ERC20 transfer failed");

        // 退回前最高出价者的资金
        _refundPreviousBidder(auction);

        // 更新最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = _amount;
        auction.highestBidCurrency = BidCurrency.ERC20;

        // 计算美元金额并触发事件
        uint256 usdAmount = convertToUsd(_amount, BidCurrency.ERC20, _erc20);
        emit BidPlaced(_auctionId, msg.sender, _amount, BidCurrency.ERC20, usdAmount);
    }

    // ======== 内部校验函数 ========
    function _validateBid(
        uint256 _auctionId,
        uint256 _amount,
        BidCurrency _currency,
        address _erc20
    ) internal view {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != address(0), "Auction not exist");
        require(!auction.ended, "Auction ended");
        require(block.timestamp < auction.startTime + auction.duration, "Time expired");

        // 转换为美元，确保出价≥起拍价（统一计价标准）
        uint256 bidUsd = convertToUsd(_amount, _currency, _erc20);
        uint256 startPriceUsd = convertToUsd(auction.startPrice, BidCurrency.ETH, address(0));
        require(bidUsd >= startPriceUsd, "Bid >= start price (USD)");

        // 确保出价＞当前最高出价（美元计价）
        if (auction.highestBid > 0) {
            uint256 highestBidUsd = convertToUsd(
                auction.highestBid,
                auction.highestBidCurrency,
                auction.approvedErc20
            );
            require(bidUsd > highestBidUsd, "Bid > current highest (USD)");
        }
    }

    // ======== 内部退款函数 ========
    function _refundPreviousBidder(Auction storage auction) internal {
        if (auction.highestBid == 0 || auction.highestBidder == address(0)) {
            return;
        }

        if (auction.highestBidCurrency == BidCurrency.ETH) {
            // 退回ETH
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(success, "ETH refund failed");
        } else {
            // 退回ERC20
            IERC20 token = IERC20(auction.approvedErc20);
            bool success = token.transfer(auction.highestBidder, auction.highestBid);
            require(success, "ERC20 refund failed");
        }
    }

    // ======== 结束拍卖（兼容多币种） ========
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
            
            // 转资金给卖家（区分ETH/ERC20）
            if (auction.highestBidCurrency == BidCurrency.ETH) {
                (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
                require(success, "ETH transfer to seller failed");
            } else {
                IERC20 token = IERC20(auction.approvedErc20);
                bool success = token.transfer(auction.seller, auction.highestBid);
                require(success, "ERC20 transfer to seller failed");
            }
        } else {
            // 无出价者，退回NFT给卖家
            IERC721(auction.nftAddress).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(
            _auctionId,
            auction.highestBidder,
            auction.highestBid,
            auction.highestBidCurrency
        );
    }

    // 接收ETH（必须）
    receive() external payable {}
    fallback() external payable {}
}