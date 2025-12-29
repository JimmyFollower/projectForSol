package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/local/go-task2/counter"
)

func main() {
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/")
	if err != nil {
		log.Fatal(err)
	}
	privateKey, err := crypto.HexToECDSA("privateKey")
	if err != nil {
		log.Fatal(err)

	}
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}
	//获得发送方地址
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)

	}
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatal(err)
	}
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(3000000)
	auth.GasPrice = gasPrice

	// address, tx, instance, err := counter.DeployCounter(auth, client)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	opt, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatalf("创建交易签名器失败: %v", err)
	}
	CounterContract, err := counter.NewCounter(common.HexToAddress("0xd32a2e4cd58e1d04506c5ea4fed14601f252a24d"), client)
	if err != nil {
		log.Fatal(err)
	}
	tx, err := CounterContract.Inc(opt)
	if err != nil {
		log.Fatalf("发送自增交易失败: %v", err)
	}

	// 7. 等待交易被打包确认（关键：确保状态更新后再查询）
	log.Printf("自增交易已发送，交易哈希: %s", tx.Hash().Hex())
	log.Println("等待交易被区块链打包确认...")

	// 上下文控制：超时时间设置为30秒（可根据链的拥堵情况调整）
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 等待交易回执
	receipt, err := bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("等待交易打包失败: %v", err)
	}

	// 检查交易是否执行成功（状态码为0表示成功，非0表示执行失败）
	if receipt.Status != 1 {
		log.Fatalf("自增交易执行失败，交易回执状态码: %d", receipt.Status)
	}
	log.Println("自增交易已成功打包上链")

	// 8. 调用Get()查询最新计数器值（添加错误检查，接收完整返回值）
	counterNum, err := CounterContract.Get(&bind.CallOpts{}) // 读方法使用CallOpts，默认空配置即可
	if err != nil {
		log.Fatalf("查询计数器值失败: %v", err)
	}

	// 9. 输出最新结果
	fmt.Printf("Counter 最新值: %d\n", counterNum.Int64())

}
