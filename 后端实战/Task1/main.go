package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	//新建一个eth客户端

	client, err := ethclient.Dial("https://sepolia.infura.io/v3/")
	if err != nil {
		log.Fatal(err)
	}

	blockNumber := big.NewInt(5671744) //查询指定区块的内容
	block, err := client.BlockByNumber(context.Background(), blockNumber)
	fmt.Println(block.Number().Uint64())     //区块高度
	fmt.Println(block.Time)                  //时间戳
	fmt.Println(block.Difficulty().Uint64()) //难度
	fmt.Println(block.Hash().Hex())          //区块哈希
	fmt.Println(len(block.Transactions()))   //交易数量

	//测试收款账户地址
	//0xAcC4175131b26baB6bAF6BCA4b35E9EB1091BabD

	privateKey, err := crypto.HexToECDSA("pk")
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
	value := big.NewInt(10000000000000000) //0.01eth

	gasLimit := uint64(21000)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	toAddreess := common.HexToAddress("0xAcC4175131b26baB6bAF6BCA4b35E9EB1091BabD")
	tx := types.NewTransaction(nonce, toAddreess, value, gasLimit, gasPrice, nil)
	chainID, err := client.NetworkID(context.Background())
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("tx sent: %s", signedTx.Hash().Hex()) //0x628f287d346b5d007d12eac3807c772be5b3216f0b748cb329f7b49851f00062
	//io 											   0x628f287d346b5d007d12eac3807c772be5b3216f0b748cb329f7b49851f00062
}
