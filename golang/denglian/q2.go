package denglian

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"fmt"
)

/*
实践非对称加密 RSA（编程语言不限）：

先生成一个公私钥对
用私钥对符合 POW 4 个 0 开头的哈希值的 “昵称 + nonce” 进行私钥签名
用公钥验证
*/

func q2() {
	// 明文
	// hashStr := "00006aee1fcf0ae329d3567855f34460d850e6a917f83da3e49233012876d081"
	nonce := 15140
	nickname := "Jerry"
	msgBytes := []byte(fmt.Sprintf("%s%d", nickname, nonce))

	// 生成 2048 位 RSA 密钥对
	privateKey, publicKey, err := GenerateRSAKeyPair(2048)
	if err != nil {
		fmt.Printf("生成密钥对失败: %v\n", err)
		return
	}
	fmt.Println("RSA 密钥对生成完成！")

	// 使用私钥签名
	signature, err := SignWithPrivateKey(msgBytes, privateKey)
	if err != nil {
		fmt.Printf("签名失败: %v\n", err)
		return
	}
	fmt.Printf("签名: %x\n", signature)

	// 使用公钥验证签名
	err = VerifyWithPublicKey(msgBytes, signature, publicKey)
	if err != nil {
		fmt.Printf("验证失败: %v\n", err)
		return
	}
	fmt.Println("验证成功！")

	// 测试错误签名（篡改明文）
	nonce++
	msgBytes = []byte(fmt.Sprintf("%s%d", nickname, nonce))
	err = VerifyWithPublicKey(msgBytes, signature, publicKey)
	if err != nil {
		fmt.Printf("篡改验证失败（预期）: %v\n", err)
	} else {
		fmt.Println("篡改验证错误！")
	}
}

// GenerateRSAKeyPair 生成 RSA 公私钥对
func GenerateRSAKeyPair(bits int) (*rsa.PrivateKey, *rsa.PublicKey, error) {
	// 生成私钥
	privateKey, err := rsa.GenerateKey(rand.Reader, bits)
	if err != nil {
		return nil, nil, err
	}
	return privateKey, &privateKey.PublicKey, nil
}

// SignWithPrivateKey 使用私钥对明文进行签名
func SignWithPrivateKey(data []byte, privateKey *rsa.PrivateKey) ([]byte, error) {
	// 使用 SHA-256 哈希明文
	hash := sha256.Sum256(data)
	// 使用 PKCS#1 v1.5 签名
	return rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA256, hash[:])
}

// VerifyWithPublicKey 使用公钥验证签名
func VerifyWithPublicKey(data, signature []byte, publicKey *rsa.PublicKey) error {
	// 使用 SHA-256 哈希明文
	hash := sha256.Sum256(data)
	// 验证签名
	return rsa.VerifyPKCS1v15(publicKey, crypto.SHA256, hash[:], signature)
}
