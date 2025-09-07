'use client'; // Next.js 前端组件声明，表示这是客户端组件

import { useEffect, useState } from 'react'; // React 的状态和副作用钩子
import {
    createPublicClient, // 创建公共链客户端（只读）
    createWalletClient, // 创建钱包客户端（可发起交易）
    custom, // 用于自定义钱包连接（如 MetaMask）
    formatEther, // 把wei单位转为以太单位
    http, // HTTP连接
    parseEther, // 把以太单位转为wei
    type Address // 地址类型
} from 'viem';
import { foundry } from 'viem/chains'; // 导入本地foundry链配置
import MyERC20ABI from '../contracts/MyERC20.json'; // 导入MyERC20合约ABI
import TokenBankABI from '../contracts/TokenBank.json'; // 导入TokenBank合约ABI

// TokenBank 合约地址
const TOKEN_BANK_ADDRESS = "0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB" as Address;
// MyERC20 合约地址
const MY_ERC20_ADDRESS = "0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690" as Address;


export default function MyTokenBankPage() {
    // 定义页面状态变量
    const [address, setAddress] = useState<Address | null>(null); // 钱包地址
    const [amount, setAmount] = useState(''); // 输入的金额
    const [tokenBalance, setTokenBalance] = useState<bigint>(BigInt(0)); // ERC20余额
    const [depositBalance, setDepositBalance] = useState<bigint>(BigInt(0)); // 存款余额
    const [allowance, setAllowance] = useState<bigint>(BigInt(0)); // 授权额度
    const [isLoading, setIsLoading] = useState(false); // 加载状态
    const [error, setError] = useState<string>(''); // 错误信息

    // 创建公共客户端（只读）
    const publicClient = createPublicClient({
        chain: foundry,
        transport: http()
    });

    // 钱包客户端（用于发起交易）
    const [walletClient, setWalletClient] = useState<any>(null);

    // 初始化钱包客户端（连接 MetaMask）
    useEffect(() => {
        if (typeof window !== 'undefined' && window.ethereum) {
            const client = createWalletClient({
                chain: foundry,
                transport: custom(window.ethereum)
            });
            setWalletClient(client);
        }
    }, []);

    // 连接钱包
    const connectWallet = async () => {
        if (!walletClient) {
            setError('钱包客户端未初始化，请确保已安装 MetaMask');
            return;
        }

        try {
            setError('');
            const [address] = await walletClient.requestAddresses(); // 请求钱包地址
            setAddress(address);
        } catch (error) {
            console.error('连接钱包错误:', error);
            setError('连接钱包失败，请确保已安装 MetaMask 并解锁');
        }
    };

    // 读取余额和授权额度
    const fetchBalances = async () => {
        if (!address) return;

        try {
            // 并发读取 ERC20余额、存款余额、授权额度
            const [tokenBal, depositBal, allowanceAmount] = await Promise.all([
                publicClient.readContract({
                    address: MY_ERC20_ADDRESS,
                    abi: MyERC20ABI,
                    functionName: 'balanceOf',
                    args: [address],
                }),
                publicClient.readContract({
                    address: TOKEN_BANK_ADDRESS,
                    abi: TokenBankABI,
                    functionName: 'balances',
                    args: [address],
                }),
                publicClient.readContract({
                    address: MY_ERC20_ADDRESS,
                    abi: MyERC20ABI,
                    functionName: 'allowance',
                    args: [address, TOKEN_BANK_ADDRESS],
                })
            ]);

            setTokenBalance(tokenBal as bigint);
            setDepositBalance(depositBal as bigint);
            setAllowance(allowanceAmount as bigint);
        } catch (error) {
            console.error('读取余额错误:', error);
            setError('读取余额失败');
        }
    };

    // 钱包地址变化时自动读取余额
    useEffect(() => {
        if (address) {
            fetchBalances();
        }
    }, [address]);

    // 授权操作
    const handleApprove = async () => {
        if (!walletClient || !address || !amount) return;

        try {
            setIsLoading(true);
            setError('');

            // 调用 ERC20 的 approve 方法，授权 TokenBank 合约
            const hash = await walletClient.writeContract({
                account: address,
                address: MY_ERC20_ADDRESS,
                abi: MyERC20ABI,
                functionName: 'approve',
                args: [TOKEN_BANK_ADDRESS, parseEther(amount)],
            });

            await publicClient.waitForTransactionReceipt({ hash });
            await fetchBalances();
        } catch (error) {
            console.error('授权错误:', error);
            setError('授权失败');
        } finally {
            setIsLoading(false);
        }
    };

    // 存款操作
    const handleDeposit = async () => {
        if (!walletClient || !address || !amount) return;

        try {
            setIsLoading(true);
            setError('');

            // 调用 TokenBank 的 deposit 方法
            const hash = await walletClient.writeContract({
                account: address,
                address: TOKEN_BANK_ADDRESS,
                abi: TokenBankABI,
                functionName: 'deposit',
                args: [parseEther(amount)],
            });

            await publicClient.waitForTransactionReceipt({ hash });
            await fetchBalances();
        } catch (error) {
            console.error('存款错误:', error);
            setError('存款失败');
        } finally {
            setIsLoading(false);
        }
    };

    // 取款操作
    const handleWithdraw = async () => {
        if (!walletClient || !address || !amount) return;

        try {
            setIsLoading(true);
            setError('');

            // 调用 TokenBank 的 withdraw 方法
            const hash = await walletClient.writeContract({
                account: address,
                address: TOKEN_BANK_ADDRESS,
                abi: TokenBankABI,
                functionName: 'withdraw',
                args: [parseEther(amount)],
            });

            await publicClient.waitForTransactionReceipt({ hash });
            await fetchBalances();
        } catch (error) {
            console.error('取款错误:', error);
            setError('取款失败');
        } finally {
            setIsLoading(false);
        }
    };

    // 如果未连接钱包，显示连接按钮
    if (!address) {
        return (
            <div className="flex min-h-screen flex-col items-center justify-center p-24">
                <h1 className="text-4xl font-bold mb-8">请先连接钱包</h1>
                <button
                    onClick={connectWallet}
                    className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                >
                    连接钱包
                </button>
            </div>
        );
    }

    // 已连接钱包时显示主页面
    return (
        <div className="flex min-h-screen flex-col items-center justify-center p-24">
            <h1 className="text-4xl font-bold mb-8">TokenBank</h1>

            <div className="w-full max-w-md space-y-6">
                {/* 账户信息展示 */}
                <div className="bg-white p-6 rounded-lg shadow-md">
                    <h2 className="text-xl font-semibold mb-4">账户信息</h2>
                    <p className="mb-2">ERC20 代币余额: {formatEther(tokenBalance)} Token</p>
                    <p className="mb-2">TokenBank 存款: {formatEther(depositBalance)} Token</p>
                    <p className="mb-4">当前授权额度: {formatEther(allowance)} Token</p>
                </div>

                {/* 操作区 */}
                <div className="bg-white p-6 rounded-lg shadow-md">
                    <h2 className="text-xl font-semibold mb-4">操作</h2>
                    <div className="space-y-4">
                        {/* 金额输入框 */}
                        <input
                            type="number"
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            placeholder="输入金额"
                            className="w-full p-2 border rounded"
                        />
                        <div className="flex space-x-4">
                            {/* 授权按钮 */}
                            <button
                                onClick={handleApprove}
                                disabled={isLoading || !amount}
                                className="flex-1 bg-yellow-500 text-white p-2 rounded hover:bg-yellow-600 disabled:bg-gray-400"
                            >
                                {isLoading ? '授权中...' : '授权'}
                            </button>
                            {/* 存款按钮 */}
                            <button
                                onClick={handleDeposit}
                                disabled={isLoading || !amount || parseEther(amount) > allowance}
                                className="flex-1 bg-blue-500 text-white p-2 rounded hover:bg-blue-600 disabled:bg-gray-400"
                            >
                                {isLoading ? '存款中...' : '存款'}
                            </button>
                            {/* 取款按钮 */}
                            <button
                                onClick={handleWithdraw}
                                disabled={isLoading || !amount}
                                className="flex-1 bg-green-500 text-white p-2 rounded hover:bg-green-600 disabled:bg-gray-400"
                            >
                                {isLoading ? '取款中...' : '取款'}
                            </button>
                        </div>
                    </div>
                </div>

                {/* 错误信息展示 */}
                {error && (
                    <div className="text-red-500 text-center">
                        {error}
                    </div>
                )}
            </div>
        </div>
    );
}