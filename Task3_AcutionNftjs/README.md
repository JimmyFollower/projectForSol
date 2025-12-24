# NFT Auction Upgradable Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

## 官方常用命令

```shell /cmd /powershell
npx hardhat node
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test #only linux
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```
## 部署步骤
1. 配置env 文件  infurakey 和私钥 需要保存到.gitignore 文件


2. 增加依赖
    1. npm install @openzeppelin/contracts
    2. npm install @chainlink/contracts 
    3. npm install @nomiclabs/hardhat-ethers/ hardhat-deploy  
    4. npm install @openzeppelin/hardhat-upgrades
    5. npm install -D hardhat-deploy  #部署deploy插件
    6. npm install --save-dev dotenv@16.4.5   #env依赖

2.修改hardhat.config.js 配置文件

    require("@nomicfoundation/hardhat-toolbox");
    require("hardhat-deploy");
    require("@openzeppelin/hardhat-upgrades");
    require("dotenv").config();


2. npx hardhat node  本地节点账户

3. 本地部署合约 
npx hardhat deploy --network localhost  部署合约

4. 测试合约
npx hardhat test  测试合约