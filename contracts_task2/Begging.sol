

/*
### ✅ 作业3：编写一个讨饭合约
任务目标
1. 使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
2. 记录每个捐赠者的地址和捐赠金额。
3. 允许合约所有者提取所有捐赠的资金。

任务步骤
1. 编写合约
  - 创建一个名为 BeggingContract 的合约。
  - 合约应包含以下功能：
  - 一个 mapping 来记录每个捐赠者的捐赠金额。
  - 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
  - 一个 withdraw 函数，允许合约所有者提取所有资金。
  - 一个 getDonation 函数，允许查询某个地址的捐赠金额。
  - 使用 payable 修饰符和 address.transfer 实现支付和提款。
2. 部署合约
  - 在 Remix IDE 中编译合约。
  - 部署合约到 Goerli 或 Sepolia 测试网。
3. 测试合约
  - 使用 MetaMask 向合约发送以太币，测试 donate 功能。
  - 调用 withdraw 函数，测试合约所有者是否可以提取资金。
  - 调用 getDonation 函数，查询某个地址的捐赠金额。

任务要求
1. 合约代码：
  - 使用 mapping 记录捐赠者的地址和金额。
  - 使用 payable 修饰符实现 donate 和 withdraw 函数。
  - 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
2. 测试网部署：
  - 合约必须部署到 Goerli 或 Sepolia 测试网。
3. 功能测试：
  - 确保 donate、withdraw 和 getDonation 函数正常工作。

提交内容
1. 合约代码：提交 Solidity 合约文件（如 BeggingContract.sol）。
2. 合约地址：提交部署到测试网的合约地址。
3. 测试截图：提交在 Remix 或 Etherscan 上测试合约的截图。

额外挑战（可选）
1. 捐赠事件：添加 Donation 事件，记录每次捐赠的地址和金额。
2. 捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
3. 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Begging {
    // 捐赠记录
    struct Donor {
        address addr;
        uint256 amount;
    }
    
    mapping(address => uint256) private _donations;
    address[] private _donaters;
    
    // 捐赠排行榜（前3名）
    Donor[3] public topDonors;
    
    // 时间限制
    uint256 public donationStartTime;
    uint256 public donationEndTime;
    bool public timeRestrictionEnabled;
    
    // 基础信息
    address public owner;
    uint256 public totalDonations;

    // 事件
    event Donation(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event TimeRestrictionSet(uint256 start, uint256 end);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier whenDonationOpen() {
        if (timeRestrictionEnabled) {
            require(
                block.timestamp >= donationStartTime && 
                block.timestamp <= donationEndTime,
                "Donations currently closed"
            );
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 设置捐赠时间段（UNIX时间戳）
    function setDonationPeriod(
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");
        donationStartTime = startTime;
        donationEndTime = endTime;
        timeRestrictionEnabled = true;
        emit TimeRestrictionSet(startTime, endTime);
    }

    // 关闭时间限制
    function disableTimeRestriction() external onlyOwner {
        timeRestrictionEnabled = false;
    }

    // 捐赠功能
    function donate() external payable whenDonationOpen {
        require(msg.value > 0, "Donation amount must be positive");
        
        // 更新捐赠记录
        if (_donations[msg.sender] == 0) {
            _donaters.push(msg.sender);
        }
        _donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        
        // 更新排行榜
        _updateTopDonors(msg.sender, _donations[msg.sender]);
        
        emit Donation(msg.sender, msg.value);
    }

    // 更新前3名捐赠者（内部函数）
    function _updateTopDonors(address donor, uint256 newAmount) private {
        // 检查是否已在前3名
        for (uint i = 0; i < 3; i++) {
            if (topDonors[i].addr == donor) {
                // 只更新金额并重新排序
                topDonors[i].amount = newAmount;
                _sortTopDonors();
                return;
            }
        }
        
        // 检查是否能进入前3
        if (newAmount > topDonors[2].amount) {
            topDonors[2] = Donor(donor, newAmount);
            _sortTopDonors();
        }
    }

    // 排行榜排序（内部函数）
    function _sortTopDonors() private {
        for (uint i = 1; i < 3; i++) {
            Donor memory current = topDonors[i];
            uint j = i;
            while (j > 0 && topDonors[j-1].amount < current.amount) {
                topDonors[j] = topDonors[j-1];
                j--;
            }
            topDonors[j] = current;
        }
    }

    // 查询功能
    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }

    // 获取完整排行榜（处理未满3个的情况）
    function getTopDonors() external view returns (Donor[3] memory) {
        return topDonors;
    }

    // 提款功能
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdraw(owner, amount);
    }

    // 获取当前捐赠状态
    function donationStatus() external view returns (
        bool isOpen,
        uint256 timeRemaining
    ) {
        if (!timeRestrictionEnabled) {
            return (true, 0);
        }
        
        isOpen = block.timestamp >= donationStartTime && 
                 block.timestamp <= donationEndTime;
        
        if (block.timestamp < donationStartTime) {
            timeRemaining = donationStartTime - block.timestamp;
        } else if (block.timestamp <= donationEndTime) {
            timeRemaining = donationEndTime - block.timestamp;
        } else {
            timeRemaining = 0;
        }
    }
    receive() external payable {
        require(msg.value > 0, "Amount must > 0");
        
        // 更新捐赠记录
        if (_donations[msg.sender] == 0) {
            _donaters.push(msg.sender);
        }
        _donations[msg.sender] += msg.value;
        totalDonations += msg.value;
        
        // 更新排行榜
        _updateTopDonors(msg.sender, _donations[msg.sender]);
        
        emit Donation(msg.sender, msg.value);
    }

    
}

