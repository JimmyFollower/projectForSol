// SPDX-License-Identifier: MIT
pragma solidity  ^0.8;
// 任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
// 合约包含以下标准 ERC20 功能：,
// balanceOf：查询账户余额。,
// transfer：转账。,
// approve 和 transferFrom：授权和代扣转账。,
// 使用 event 记录转账和授权操作。,
// 提供 mint 函数，允许合约所有者增发代币。,
// 提示：
// 使用 mapping 存储账户余额和授权信息。,
// 使用 event 定义 Transfer 和 Approval 事件。,
// 部署到sepolia 测试网，导入到自己的钱包
// contract MyERC20Token{
//     string public  name;
//     string public  symbol;
//     uint8 public  decimals;
//     uint256 public  totalSupply;

//     //合约所有者
//     address public  owner;

//     //余额映射
//     mapping (address => uint256) private _balances;

//     //授权额度信息
//     mapping ( address=> mapping (address=>uint256)) private  _allowances;

//     //event for transfer 
//     event Transfer(address indexed  from,address indexed  to,uint256 value);
//     event Approval(address indexed  owner,address indexed  spender,uint256 value);

//     //Modifer only for owner
//     modifier onlyOwner(){
//         require(msg.sender==owner,"only owner can call this function");
//         _;
//     }

//     constructor (string memory _name,string memory _symbol,uint8 _decimals,uint256 _initialSupply){
//         name=_name;
//         symbol=_symbol;
//         require(_decimals <= 18, "Decimals too high"); // 限制 decimals 合理范围
//          decimals=_decimals;
//         totalSupply = _initialSupply * (10 ** _decimals); // 0.8+ 自动检查溢出
//         _balances[msg.sender]=totalSupply;
//         owner=msg.sender;

//         emit  Transfer(address(0), msg.sender, totalSupply);

//     }

//     function balanceOf(address account) public  view  returns(uint256 ){
//         return  _balances[account];
//     }
//     function transfer(address to, uint256 amount)public returns(bool){
//         require(to!=address(0),"ERC20 transfer to zero address");
//         require(_balances[msg.sender]>=amount,"ERC20 transfer amount exceeds balance");
//         _balances[msg.sender]-=amount;
//         _balances[to]+=amount;

//         emit Transfer(msg.sender, to, amount);
//         return  true;
//     }

//     function approve(address spender,uint256 amount) public returns(bool){
//         require(spender!=address(0),"ERC20:approve to the zero address");

//         _allowances[msg.sender][spender]=amount;

//         emit Approval(msg.sender, spender, amount);
//         return true;

//     }
//     //查询授权额度
//     function allowance(address ownerAddr,address spender) public view  returns(uint256 ){
//         return  _allowances[ownerAddr][spender];
//     }

//     //代扣额度
//     function transferFrom(address from,address to, uint256 amount) public returns (bool){
//         require(from !=address(0),"ERC20 transfer from the zero address");
//         require(to!=address(0),"ERC20 transfer to the zero address");
//         require(_balances[from]>=amount,"ERC20: tranfer to the zero");
//         require(_allowances[from][msg.sender]>=amount,"ERC20:insufficient allowance");

//         _balances[from]-=amount;
//         _balances[to]+=amount;
//         _allowances[from][msg.sender]-=amount;

//         emit Transfer(from, to, amount);

//         return  true;

//     }

//     //增发代币
//     function  mint(address account ,uint256 amount,uint256 amount) public onlyOwner{
//         _mint(account,amount);
//     }


// }




contract MyERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        require(_decimals <= 18, "Decimals too high");
        decimals = _decimals;
        totalSupply = _initialSupply * (10 ** _decimals);
        _balances[msg.sender] = totalSupply;
        owner = msg.sender;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns(bool) {
        require(to != address(0), "ERC20: transfer to zero address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool) {
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address ownerAddr, address spender) public view returns(uint256) {
        return _allowances[ownerAddr][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[from][msg.sender] >= amount, "ERC20: insufficient allowance");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to zero address");
        
        totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
}

