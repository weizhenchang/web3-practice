import { Wallet } from '@ethersproject/wallet'; // ethers.js 的钱包工具
import dotenv from 'dotenv'; // 加载环境变量
import { readFileSync } from 'fs'; // 读取文件
import { join } from 'path'; // 路径拼接
import {
    createPublicClient, // 创建公共链客户端（只读）
    createWalletClient, // 创建钱包客户端（可发起交易）
    formatEther, // 把wei单位转为以太单位
    http, // HTTP连接
    parseEther, // 把以太单位转为wei
    parseGwei, // 把gwei单位转为wei
    type Hash, // 交易哈希类型
    type PublicClient, // 公共客户端类型
    type TransactionReceipt, // 交易回执类型
    type WalletClient // 钱包客户端类型
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts'; // 私钥转账户
import { prepareTransactionRequest } from 'viem/actions'; // 构建交易请求
import { sepolia } from 'viem/chains'; // 导入本地sepolia链配置

dotenv.config() // 加载.env文件里的环境变量

async function sendTransactionWithKeystore(): Promise<Hash> {
    try {
        // 从环境变量获取 keystore 文件路径和密码
        const keystorePath = process.env.KEYSTORE_PATH; // 存储路径
        const keystorePassword = process.env.KEYSTORE_PASSWORD; // 加密密码
        if (!keystorePath || !keystorePassword) {
            throw new Error('请在 .env 文件中设置 KEYSTORE_PATH 和 KEYSTORE_PASSWORD')
        }

        // // 随机生成一个新以太坊钱包
        // const wallet = Wallet.createRandom();
        // // 加密生成 keystore JSON（符合以太坊标准格式）
        // const keystoreJson = await wallet.encrypt(keystorePassword, {
        //     scrypt: { N: 16384 } // 加密算法参数（N 越大越安全，默认即可）
        // });
        // // 写入文件
        // writeFileSync(join(process.cwd(), keystorePath), keystoreJson, "utf-8");
        // console.log(`Keystore 文件已保存至：${keystorePath}`);
        // console.log(`钱包地址：${wallet.address}`);

        // 读取 keystore 文件内容
        const keystoreJson = readFileSync(join(process.cwd(), keystorePath), "utf-8");
        // 解密并恢复钱包
        const wallet = await Wallet.fromEncryptedJson(keystoreJson, keystorePassword);
        console.log("地址：", wallet.address);
        // console.log("私钥：", wallet.privateKey);

        // 创建公共客户端
        const publicClient: PublicClient = createPublicClient({
            chain: sepolia,
            transport: http(process.env.SEPOLIA_RPC_URL)
        })
        // 创建钱包客户端
        const walletClient: WalletClient = createWalletClient({
            chain: sepolia,
            transport: http(process.env.SEPOLIA_RPC_URL)
        })

        // 查询余额
        const userAddress = wallet.address as `0x${string}`
        const balance = await publicClient.getBalance({
            address: userAddress
        })
        console.log('账户余额:', formatEther(balance), 'SepoliaETH')

        // 获取当前 gas 价格
        const gasPrice = await publicClient.getGasPrice()
        console.log('当前 gas 价格:', formatEther(gasPrice), 'SepoliaETH')

        // 查询 nonce
        const nonce = await publicClient.getTransactionCount({
            address: userAddress
        })
        console.log('当前 Nonce:', nonce)

        // 从私钥创建账户
        const account = privateKeyToAccount(wallet.privateKey as `0x${string}`)

        // 构建交易参数
        const txParams = {
            account: account,
            to: '0xC7eD154C2309Ec99e6d7cf11B96564d1d1838675' as `0x${string}`, // 目标地址
            value: parseEther('0.001'), // 发送金额（ETH）
            chainId: sepolia.id,
            type: 'eip1559' as const,
            chain: sepolia,

            // EIP-1559 交易参数
            maxFeePerGas: gasPrice * 2n,
            // maxPriorityFeePerGas: parseGwei('1.5'),
            maxPriorityFeePerGas: parseGwei('0.002'),
            gas: 21000n,
            nonce: nonce,
        }

        // 准备交易
        const preparedTx = await prepareTransactionRequest(publicClient, txParams)
        console.log('准备后的交易参数:', {
            ...preparedTx,
            maxFeePerGas: parseGwei(preparedTx.maxFeePerGas.toString()),
            maxPriorityFeePerGas: parseGwei(preparedTx.maxPriorityFeePerGas.toString()),
        })

        // 签名交易
        const signedTx = await walletClient.signTransaction(preparedTx)
        console.log('Signed Transaction:', signedTx)

        // 发送交易
        const txHash = await publicClient.sendRawTransaction({
            serializedTransaction: signedTx
        })
        console.log('Transaction Hash:', txHash)

        // 等待交易确认
        const receipt: TransactionReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash })
        console.log('交易状态:', receipt.status === 'success' ? '成功' : '失败')
        console.log('区块号:', receipt.blockNumber)
        console.log('Gas 使用量:', receipt.gasUsed.toString())

        return txHash

    } catch (error) {
        console.error('错误:', error)
        if (error instanceof Error) {
            console.error('错误信息:', error.message)
        }
        if (error && typeof error === 'object' && 'details' in error) {
            console.error('错误详情:', error.details)
        }
        throw error
    }
}

// 执行
sendTransactionWithKeystore() 