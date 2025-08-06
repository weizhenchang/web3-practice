package denglian

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"
)

/*
用自己熟悉的语言模拟实现最小的区块链， 包含两个功能：

POW 证明出块，难度为 4 个 0 开头
每个区块包含previous_hash 让区块串联起来。
如下是一个参考区块结构：

block = {
'index': 1,
'timestamp': 1506057125,
'transactions': [

	{ 'sender': "xxx",
	'recipient': "xxx",
	'amount': 5, } ],

'proof': 324984774000,
'previous_hash': "xxxx"
}
*/
type Blockchain struct {
	Blocks []*Block `json:"blocks"`
}

// 添加新区块
func (bc *Blockchain) AddBlock(transactions []Transaction) {
	prevBlock := bc.Blocks[len(bc.Blocks)-1] // 获取上一个区块

	newBlock := &Block{
		Index:        prevBlock.Index + 1,
		Timestamp:    time.Now().Unix(),
		Transactions: transactions,
		PreviousHash: calHash(*prevBlock), // 计算区块的哈希值
	}

	newBlock.Proof = calProof(*newBlock)

	bc.Blocks = append(bc.Blocks, newBlock)
}

// 计算区块的哈希值
func calHash(block Block) string {
	jsonStr, _ := json.Marshal(block)
	hash := sha256.Sum256(jsonStr)
	return hex.EncodeToString(hash[:])
}

// 计算nonce值，直到满足工作量证明条件
// 这里简单实现为找到一个以4个0开头的哈希值
func calProof(block Block) int64 {
	nonce := int64(0)
	for {
		block.Proof = nonce
		hash := calHash(block)
		if hash[:4] == "0000" { // POW 证明，难度为 4 个 0 开头
			return nonce
		}
		nonce++
	}
}

// 创建一个新的区块链，包含创世区块
func NewBlockchain() *Blockchain {
	// 创世区块
	genesisBlock := &Block{
		Index:        0,
		Timestamp:    time.Now().Unix(),
		Transactions: []Transaction{},
		Proof:        0,
		PreviousHash: "0",
	}
	return &Blockchain{
		Blocks: []*Block{genesisBlock},
	}
}

type Block struct {
	Index        int64         `json:"index"`
	Timestamp    int64         `json:"timestamp"`
	Transactions []Transaction `json:"transactions"`
	Proof        int64         `json:"proof"`
	PreviousHash string        `json:"previous_hash"`
}
type Transaction struct {
	Sender    string `json:"sender"`
	Recipient string `json:"recipient"`
	Amount    int64  `json:"amount"`
}

func q3() {
	// 创建一个新的区块链，包含创世区块
	bc := NewBlockchain()

	// 第1笔转账
	transaction1 := Transaction{
		Sender:    "A",
		Recipient: "B",
		Amount:    100,
	}
	// 创建新区块1
	bc.AddBlock([]Transaction{transaction1})

	// 第2笔转账
	transaction2 := Transaction{
		Sender:    "B",
		Recipient: "C",
		Amount:    10,
	}
	// 第3笔转账
	transaction3 := Transaction{
		Sender:    "B",
		Recipient: "D",
		Amount:    1,
	}
	// 创建新区块2
	bc.AddBlock([]Transaction{transaction2, transaction3})

	// 打印区块链
	for _, block := range bc.Blocks {
		fmt.Printf("区块序号: %d\n", block.Index)
		fmt.Printf("创建时间戳: %d\n", block.Timestamp)
		fmt.Println("交易:")
		for _, tx := range block.Transactions {
			fmt.Printf("    发起人: %s, 接收人: %s, 金额: %d\n", tx.Sender, tx.Recipient, tx.Amount)
		}
		fmt.Printf("nonce: %d\n", block.Proof)
		fmt.Printf("上一个区块哈希: %s\n", block.PreviousHash)
		fmt.Println("")
	}

	// 校验
	for i := 1; i < len(bc.Blocks); i++ {
		// 检查相邻区块的hash是否一致
		currBlock := bc.Blocks[i]
		prevBlock := bc.Blocks[i-1]
		if currBlock.PreviousHash != calHash(*prevBlock) {
			fmt.Printf("区块index: %d 的前一个哈希不匹配！\n", currBlock.Index)
			return
		}

		// 校验工作证明
		if calHash(*currBlock)[:4] != "0000" {
			fmt.Printf("区块index: %d 的工作证明不匹配！\n", currBlock.Index)
			return
		}
	}
}
