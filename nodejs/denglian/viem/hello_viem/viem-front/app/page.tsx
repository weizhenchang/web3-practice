'use client'; // Next.js 前端组件声明

import { useEffect, useState } from 'react'; // React 的状态和副作用钩子
import {
  createPublicClient, // 创建公共链客户端（只读）
  createWalletClient, // 创建钱包客户端（可发起交易）
  custom,
  formatEther, // 把wei单位转为以太单位
  getContract, // 获取合约实例
  http // HTTP连接
} from 'viem';
import { foundry } from 'viem/chains'; // 导入本地foundry链配置
import Counter_ABI from './contracts/Counter.json'; // 导入Counter合约ABI

// Counter 合约地址
const COUNTER_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

export default function Home() {
  // 定义页面状态变量
  const [balance, setBalance] = useState<string>('0'); // 钱包余额
  const [counterNumber, setCounterNumber] = useState<string>('0'); // Counter 合约的数值
  const [address, setAddress] = useState<`0x${string}` | undefined>(); // 钱包地址
  const [isConnected, setIsConnected] = useState(false); // 是否已连接钱包
  const [chainId, setChainId] = useState<number | undefined>(); // 当前链的 ChainId

  // 创建只读客户端
  const publicClient = createPublicClient({
    chain: foundry,
    transport: http(),
  });

  // 连接钱包
  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      alert('请安装 MetaMask');
      return;
    }

    try {
      // 请求连接钱包，获取地址和链ID
      const [address] = await window.ethereum.request({ method: 'eth_requestAccounts' });
      const chainId = await window.ethereum.request({ method: 'eth_chainId' });

      setAddress(address as `0x${string}`);
      setChainId(Number(chainId));
      setIsConnected(true);

      // 监听账户变化
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length === 0) {
          setIsConnected(false);
          setAddress(undefined);
        } else {
          setAddress(accounts[0] as `0x${string}`);
        }
      });

      // 监听网络变化
      window.ethereum.on('chainChanged', (chainId: string) => {
        setChainId(Number(chainId));
      });
    } catch (error) {
      console.error('连接钱包失败:', error);
    }
  };

  // 断开连接
  const disconnectWallet = () => {
    setIsConnected(false);
    setAddress(undefined);
    setChainId(undefined);
  };

  // 获取 Counter 合约的数值
  const fetchCounterNumber = async () => {
    if (!address) return;

    // 获取合约实例
    const counterContract = getContract({
      address: COUNTER_ADDRESS,
      abi: Counter_ABI,
      client: publicClient,
    });

    // 读取合约 number 变量
    const number = await counterContract.read.number();
    setCounterNumber(number.toString());
  };

  // 调用 increment 函数
  const handleIncrement = async () => {
    if (!address) return;

    // 创建钱包客户端，连接 MetaMask
    const walletClient = createWalletClient({
      chain: foundry,
      transport: custom(window.ethereum),
    });

    try {
      // 调用合约的 increment 方法
      const hash = await walletClient.writeContract({
        address: COUNTER_ADDRESS,
        abi: Counter_ABI,
        functionName: 'increment',
        account: address,
      });
      console.log('Transaction hash:', hash);
      // 更新 Counter 数值
      fetchCounterNumber();
    } catch (error) {
      console.error('调用 increment 失败:', error);
    }
  };

  // 当 address 变化时，自动获取余额和 Counter 数值
  useEffect(() => {
    const fetchBalance = async () => {
      if (!address) return;

      const balance = await publicClient.getBalance({
        address: address,
      });

      setBalance(formatEther(balance));
    };

    if (address) {
      fetchBalance();
      fetchCounterNumber();
    }
  }, [address]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-3xl font-bold mb-8">Simple Viem Demo</h1>

      <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-2xl">
        <div className="mb-4">
          <a
            href="/siwe"
            className="block w-full bg-purple-500 text-white py-2 px-4 rounded hover:bg-purple-600 transition-colors text-center"
          >
            前往 SIWE 登录演示
          </a>
        </div>

        {!isConnected ? (
          <button
            onClick={connectWallet}
            className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 transition-colors"
          >
            连接 MetaMask
          </button>
        ) : (
          <div className="space-y-4">
            <div className="text-center">
              <p className="text-gray-600">钱包地址:</p>
              <p className="font-mono break-all">{address}</p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">当前网络:</p>
              <p className="font-mono">
                {foundry.name} (Chain ID: {chainId})
              </p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">余额:</p>
              <p className="font-mono">{balance} ETH</p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">Counter 数值:</p>
              <p className="font-mono">{counterNumber}</p>
              <button
                onClick={handleIncrement}
                className="mt-2 w-full bg-green-500 text-white py-2 px-4 rounded hover:bg-green-600 transition-colors"
              >
                增加计数
              </button>
            </div>
            <button
              onClick={disconnectWallet}
              className="w-full bg-red-500 text-white py-2 px-4 rounded hover:bg-red-600 transition-colors"
            >
              断开连接
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
