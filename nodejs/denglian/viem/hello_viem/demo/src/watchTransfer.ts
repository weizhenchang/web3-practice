import dotenv from "dotenv"; // 加载环境变量
import {
    createPublicClient, // 创建公共链客户端（只读）
    formatEther, // 把wei单位转为以太单位
    http, // HTTP连接
    publicActions // 公共链操作扩展
} from "viem";
import { foundry } from "viem/chains"; // 导入本地foundry链配置

dotenv.config(); // 加载.env文件里的环境变量

const ERC20_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // ERC20合约地址

const main = async () => {
    // 创建公共客户端（只读），连接本地foundry链
    const publicClient = createPublicClient({
        chain: foundry,
        transport: http(process.env.RPC_URL!), // 用环境变量里的RPC_URL连接
    }).extend(publicActions); // 扩展公共链操作

    console.log('开始监听 ERC20 转账事件...');

    // 监听 Transfer 事件
    // cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "transfer(address,uint256)" 0x01BF49D75f2b73A2FDEFa7664AEF22C86c5Be3df 1000000000000000000 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    const unwatch = publicClient.watchEvent({
        address: ERC20_ADDRESS, // 要监听的合约地址
        event: { // 事件定义
            type: 'event',
            name: 'Transfer', // 事件名
            inputs: [ // 事件参数
                { type: 'address', name: 'from', indexed: true },
                { type: 'address', name: 'to', indexed: true },
                { type: 'uint256', name: 'value' }
            ]
        },
        onLogs: (logs) => { // 事件触发时的回调
            logs.forEach((log) => {
                if (log.args.value !== undefined) { // 如果有转账金额
                    console.log('\n检测到新的转账事件:');
                    console.log(`从: ${log.args.from}`); // 打印转账来源地址
                    console.log(`到: ${log.args.to}`); // 打印转账目标地址
                    console.log(`金额: ${formatEther(log.args.value)}`); // 打印转账金额（单位转换为ETH）
                    console.log(`交易哈希: ${log.transactionHash}`); // 打印交易哈希
                    console.log(`区块号: ${log.blockNumber}`); // 打印区块号
                }
            });
        }
    });

    // 保持程序运行，监听 Ctrl+C 退出
    process.on('SIGINT', () => {
        console.log('\n停止监听...');
        unwatch(); // 停止事件监听
        process.exit(); // 退出程序
    });
};

main().catch((error) => {
    console.error('发生错误:', error); // 捕获并打印主函数异常
    process.exit(1); // 异常时退出程序
}); 