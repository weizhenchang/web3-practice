package denglian

import (
	"crypto/sha256"
	"fmt"
	"strconv"
	"strings"
	"time"
)

/*
实践 POW， 编写程序（编程语言不限）用自己的昵称 + nonce，不断修改nonce 进行 sha256 Hash 运算：

直到满足 4 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。
再次运算直到满足 5 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。
*/

func q1() {
	nickname := "Jerry" // 昵称
	nonce := 0          // 起始nonce值
	target4 := "0000"
	startTime4 := time.Now()
	for {
		hash := sha256.Sum256([]byte(nickname + strconv.Itoa(nonce)))
		hashStr := fmt.Sprintf("%x", hash)
		if strings.HasPrefix(hashStr, target4) {
			fmt.Printf("算出0000开头的哈希值: %s, nonce: %d, nickname: %s, 耗时: %s\n", hashStr, nonce, nickname, time.Since(startTime4))
			break
		}
		nonce++
	}

	nonce = 0
	target5 := "00000"
	startTime5 := time.Now()
	for {
		hash := sha256.Sum256([]byte(nickname + strconv.Itoa(nonce)))
		hashStr := fmt.Sprintf("%x", hash)
		if strings.HasPrefix(hashStr, target5) {
			fmt.Printf("算出00000开头的哈希值: %s, nonce: %d, nickname: %s, 耗时: %s\n", hashStr, nonce, nickname, time.Since(startTime5))
			break
		}
		nonce++
	}
}
