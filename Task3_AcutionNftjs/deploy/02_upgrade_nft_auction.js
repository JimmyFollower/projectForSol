const { deployments, upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("===== 开始升级 NftAuction 到 V2 版本（透明代理）=====");
  console.log("升级操作地址：", deployer);

  // 1. 读取 V1 代理缓存
  const cacheDir = path.resolve(__dirname, "./.cache");
  const storePath = path.resolve(cacheDir, "proxyNftAuction.json");
  if (!fs.existsSync(storePath)) {
    throw new Error(`未找到 V1 代理缓存文件，请先部署 V1 合约，文件路径：${storePath}`);
  }

  let proxyData;
  try {
    proxyData = JSON.parse(fs.readFileSync(storePath, "utf-8"));
  } catch (error) {
    throw new Error(`读取代理缓存文件失败：${error.message}`);
  }
  const proxyAddress = proxyData.proxyAddress;
  console.log("待升级的透明代理合约地址：", proxyAddress);

  // 2. 加载 V2 合约工厂
  let NftAuctionV2;
  try {
    NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");
  } catch (error) {
    throw new Error(`加载 NftAuctionV2 合约失败：${error.message}，请检查合约文件是否存在/编译通过`);
  }

  // 3. 执行透明代理升级（核心：指定 kind: "transparent"）
  let nftAuctionV2Proxy;
  try {
    nftAuctionV2Proxy = await upgrades.upgradeProxy(
      proxyAddress,
      NftAuctionV2,
      {
        kind: "transparent", // 强制透明代理模式（和V1一致）
        unsafeAllow: ["constructor"], // 兼容构造函数禁用初始化
      }
    );
    await nftAuctionV2Proxy.waitForDeployment();
  } catch (error) {
    throw new Error(`合约升级失败：${error.message}`);
  }

  // 4. 获取 V2 实现合约地址
  const newImplAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("✅ NftAuction V2 升级成功");
  console.log("透明代理合约地址（不变）：", proxyAddress);
  console.log("V2 实现合约地址：", newImplAddress);

  // 5. 更新缓存文件
  try {
    fs.writeFileSync(
      storePath,
      JSON.stringify({
        ...proxyData,
        implAddress: newImplAddress,
        abi: NftAuctionV2.interface.formatJson(),
        upgradeTime: new Date().toISOString(),
        version: "V2",
        proxyKind: "transparent" // 标记为透明代理
      }, null, 2),
      "utf-8"
    );
    console.log(`✅ 缓存文件已更新：${storePath}`);
  } catch (error) {
    throw new Error(`更新缓存文件失败：${error.message}`);
  }

  // 6. 更新 hardhat-deploy 缓存
  await save("NftAuctionProxy", {
    abi: NftAuctionV2.interface.format("json"),
    address: proxyAddress,
  });

  console.log("===== NftAuction V2 升级完成（透明代理）=====");
};

module.exports.tags = ["upgradeNftAuctionV2"];