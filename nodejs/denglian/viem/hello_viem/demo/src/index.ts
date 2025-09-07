import dotenv from "dotenv"; // 加载环境变量
import {
  createPublicClient, // 创建公共链客户端（只读）
  createWalletClient, // 创建钱包客户端（可发起交易）
  formatEther, // 把wei单位转为以太单位
  getContract, // 获取合约实例
  http, // HTTP连接
  parseEther, // 把以太单位转为wei
  parseEventLogs, // 解析事件日志
  parseGwei, // 把gwei单位转为wei
  publicActions // 公共链操作扩展
} from "viem";
import { privateKeyToAccount } from "viem/accounts"; // 私钥转账户
import { foundry } from "viem/chains"; // 导入本地foundry链配置
import Counter_ABI from './abis/Counter.json' with { type: 'json' }; // 导入Counter合约ABI
import ERC20_ABI from './abis/MyToken.json' with { type: 'json' }; // 导入ERC20合约ABI
dotenv.config(); // 加载.env文件里的环境变量

const COUNTER_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"; // Counter合约地址
const ERC20_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // ERC20合约地址
const LOCAL_ADDRESS0 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"; // 本地节点预设地址0
const LOCAL_ADDRESS1 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; // 本地节点预设地址1


const main = async () => {
  // 创建一个公共客户端（只读）
  const publicClient = createPublicClient({
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  }).extend(publicActions);

  // 获取当前区块号
  const blockNumber = await publicClient.getBlockNumber();
  console.log(`The block number is ${blockNumber}`);

  // 查询某地址余额（以太币）
  const tbalance = formatEther(await publicClient.getBalance({
    address: LOCAL_ADDRESS0,
  }));
  console.log(`The balance of ${LOCAL_ADDRESS0} is ${tbalance}`);

  // 用私钥创建钱包账户
  const account = privateKeyToAccount(
    process.env.PRIVATE_KEY! as `0x${string}`
  );
  const walletClient = createWalletClient({
    account,
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  }).extend(publicActions);
  const address = await walletClient.getAddresses();
  console.log(`The wallet address is ${address}`);

  // 发起一笔ETH转账（默认gas和nonce）
  const hash1 = await walletClient.sendTransaction({
    account,
    to: LOCAL_ADDRESS1,
    value: parseEther("0.001"),
  });
  console.log(` 默认 gas 和 nonce 的 transaction hash is ${hash1}`);

  // 发起一笔ETH转账（自定义gas和nonce）
  const hash2 = await walletClient.sendTransaction({
    account,
    gas: 21000n,  // 21000 是 gas 的默认值
    maxFeePerGas: parseGwei('20'), // 最大gas费
    maxPriorityFeePerGas: parseGwei("2"), // 优先gas费
    to: LOCAL_ADDRESS1,
    value: parseEther('1'),
    // nonce: 10, // 可选，指定nonce
  })
  console.log(` 自定义 gas 和 nonce 的 transaction hash is ${hash2}`);

  // 获取ERC20合约实例
  const erc20Contract = getContract({
    address: ERC20_ADDRESS,
    abi: ERC20_ABI,
    client: {
      public: publicClient,
      wallet: walletClient,
    },
  });
  // 读取ERC20余额（方法1）
  const balance1 = formatEther(BigInt(await erc20Contract.read.balanceOf([
    LOCAL_ADDRESS0.toString(),
  ]) as string));
  console.log(`方法 1 获取的余额是 ${LOCAL_ADDRESS0.toString()} is ${balance1}`);
  // 读取ERC20余额（方法2）
  const balance = formatEther(
    BigInt(
      (await publicClient.readContract({
        address: ERC20_ADDRESS,
        abi: ERC20_ABI,
        functionName: "balanceOf",
        args: [LOCAL_ADDRESS0.toString()],
      })) as string
    )
  );
  console.log(`方法 2 获取的余额是 ${LOCAL_ADDRESS0.toString()} is ${balance}`);

  // 获取Counter合约实例
  const counterContract = getContract({
    address: COUNTER_ADDRESS,
    abi: Counter_ABI,
    client: {
      public: publicClient,
      wallet: walletClient,
    },
  });
  // 调用Counter合约的increment方法（写操作1）
  const hash = await counterContract.write.increment();
  console.log(` 调用 increment 方法的 transaction hash is ${hash}`);
  const number1 = await counterContract.read.number([]);
  console.log(` 调用 number 方法的 number is ${number1}`);

  // 用钱包客户端直接写合约（写操作2）
  await walletClient.writeContract({
    address: COUNTER_ADDRESS,
    abi: Counter_ABI,
    functionName: 'increment',
    args: [],
  });
  // 再次读取Counter合约的number变量
  const number2 = await counterContract.read.number([]);
  console.log(` 调用 number 方法的 number is ${number2}`);

  // 调用ERC20合约的transfer方法，转账1个token
  const tx = await erc20Contract.write.transfer([
    LOCAL_ADDRESS1,
    parseEther("1"),
  ]);
  console.log(` 调用 transfer 方法的 transaction hash is ${tx}`);

  // 等待转账交易被确认
  const receipt = await publicClient.waitForTransactionReceipt({ hash: tx });
  console.log(`交易状态: ${receipt.status === 'success' ? '成功' : '失败'}`);
  // console.log(receipt.logs);
  // 解析转账事件日志
  const transferLogs = await parseEventLogs({
    abi: ERC20_ABI,
    eventName: 'Transfer',
    logs: receipt.logs,
  });

  // 打印每个转账事件的详情
  for (const log of transferLogs) {
    // 把 log 强制转换为一个包含事件名和参数的对象类型，方便后续用 eventLog.eventName、eventLog.args.from 等属性来访问事件内容。
    const eventLog = log as unknown as {
      eventName: string;
      args: {
        from: string;
        to: string;
        value: bigint
      }
    };
    if (eventLog.eventName === 'Transfer') {
      console.log('转账事件详情:');
      console.log(`从: ${eventLog.args.from}`);
      console.log(`到: ${eventLog.args.to}`);
      console.log(`金额: ${formatEther(eventLog.args.value)}`);
    }
  }

};

main(); // 执行主函数
