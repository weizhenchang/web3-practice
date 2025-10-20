'use client'; // Next.js 客户端组件

import { useEffect, useState } from 'react'; // React hooks
import { Hex, createPublicClient, createWalletClient, custom, formatEther, getContract, http, parseEther } from 'viem'; // viem 工具
import { signTypedData } from 'viem/actions'; // viem 的 EIP-712 签名
import { sepolia } from 'viem/chains'; // sepolia 测试链
import TokenBank_ABI from './contracts/TokenBank.json'; // TokenBank 合约 ABI

// TokenBank 合约地址
const TOKEN_BANK_ADDRESS = "0xD3375B8927db243335501EC0436c0283E71031B6"; // todo...待更新
// PermitTokenBank 合约地址
const PERMIT_TOKEN_BANK_ADDRESS = "0x201Fc8A0607070D04e98eA68B559F4A7fD7aB4e8"; // todo...待更新

export default function Home() {
    // 各种状态变量
    const [balance, setBalance] = useState<string>('0'); // ETH 余额
    const [tokenBalance, setTokenBalance] = useState<string>('0'); // Token 余额
    const [depositBalance, setDepositBalance] = useState<string>('0'); // 存款余额
    const [depositAmount, setDepositAmount] = useState<string>(''); // 存款金额
    const [withdrawAmount, setWithdrawAmount] = useState<string>(''); // 取款金额
    const [address, setAddress] = useState<`0x${string}` | undefined>(); // 用户地址
    const [isConnected, setIsConnected] = useState(false); // 是否连接钱包
    const [chainId, setChainId] = useState<number | undefined>(); // 链ID
    const [isLoading, setIsLoading] = useState(false); // 是否加载中
    const [txHash, setTxHash] = useState<string>(''); // 交易哈希
    // permit 存款相关状态
    const [permitDepositAmount, setPermitDepositAmount] = useState<string>(''); // 签名存款输入
    const [isPermitLoading, setIsPermitLoading] = useState(false); // 签名存款加载状态

    // 创建 sepolia 公共客户端
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http('https://eth-sepolia.public.blastapi.io'),
    });

    // 连接钱包
    const connectWallet = async () => {
        if (typeof window.ethereum === 'undefined') {
            alert('请安装 MetaMask');
            return;
        }

        try {
            const [address] = await window.ethereum.request({ method: 'eth_requestAccounts' }); // 请求账户
            const chainId = await window.ethereum.request({ method: 'eth_chainId' }); // 请求链ID

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

    // 获取 Token 余额和存款余额
    const fetchBalances = async () => {
        if (!address) return;

        // 获取 PermitTokenBank 合约实例
        const tokenBankContract = getContract({
            address: PERMIT_TOKEN_BANK_ADDRESS, // 使用PermitTokenBank地址
            abi: TokenBank_ABI,
            client: publicClient,
        });

        try {
            // 获取用户在TokenBank中的存款余额
            const depositBal = await tokenBankContract.read.balanceOf([address]);
            setDepositBalance(formatEther(depositBal as bigint));

            // 查询 Token 合约地址
            const tokenAddress = await tokenBankContract.read.token() as `0x${string}`;

            // 查询用户的 Token 余额
            const tokenContract = getContract({
                address: tokenAddress,
                // 使用ERC20标准ABI中的balanceOf方法
                abi: [{
                    "type": "function",
                    "name": "balanceOf",
                    "inputs": [{ "name": "owner", "type": "address" }],
                    "outputs": [{ "name": "", "type": "uint256" }],
                    "stateMutability": "view"
                }],
                client: publicClient,
            });

            const tokenBal = await tokenContract.read.balanceOf([address]);
            setTokenBalance(formatEther(tokenBal));
        } catch (error) {
            console.error('获取余额失败:', error);
        }
    };

    // 普通存款
    const handleDeposit = async () => {
        if (typeof window.ethereum === 'undefined') {
            alert('请安装 MetaMask');
            return;
        }

        if (!address || !depositAmount) return;
        setIsLoading(true);
        setTxHash('');

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            // 首先需要批准TokenBank合约使用Token
            const tokenBankContract = getContract({
                address: PERMIT_TOKEN_BANK_ADDRESS, // 修改这里，使用PERMIT_TOKEN_BANK_ADDRESS
                abi: TokenBank_ABI,
                client: publicClient,
            });

            // 获取Token合约地址
            const tokenAddress = await tokenBankContract.read.token() as `0x${string}`;

            // 批准TokenBank使用Token
            const tokenContract = getContract({
                address: tokenAddress,
                // 使用ERC20标准ABI中的approve方法
                abi: [{
                    "type": "function",
                    "name": "approve",
                    "inputs": [
                        { "name": "spender", "type": "address" },
                        { "name": "amount", "type": "uint256" }
                    ],
                    "outputs": [{ "name": "", "type": "bool" }],
                    "stateMutability": "nonpayable"
                }],
                client: {
                    public: publicClient,
                    wallet: walletClient,
                },
            });

            // 先 approve 授权
            const approveHash = await tokenContract.write.approve([
                PERMIT_TOKEN_BANK_ADDRESS, // 修改这里，使用PERMIT_TOKEN_BANK_ADDRESS
                parseEther(depositAmount),
            ], { account: address });

            console.log('Approve hash:', approveHash);

            // 等待批准交易确认
            await publicClient.waitForTransactionReceipt({ hash: approveHash });

            // 然后调用存款方法
            const hash = await walletClient.writeContract({
                address: PERMIT_TOKEN_BANK_ADDRESS, // 修改这里，使用PERMIT_TOKEN_BANK_ADDRESS
                abi: TokenBank_ABI,
                functionName: 'deposit',
                args: [parseEther(depositAmount)],
                account: address,
            });

            console.log('Deposit hash:', hash);
            setTxHash(hash);

            // 等待交易确认后刷新余额
            await publicClient.waitForTransactionReceipt({ hash });
            fetchBalances();
            setDepositAmount('');
        } catch (error) {
            console.error('存款失败:', error);
        } finally {
            setIsLoading(false);
        }
    };

    // 取款
    const handleWithdraw = async () => {
        if (typeof window.ethereum === 'undefined') {
            alert('请安装 MetaMask');
            return;
        }

        if (!address || !withdrawAmount) return;
        setIsLoading(true);
        setTxHash('');

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            const hash = await walletClient.writeContract({
                address: PERMIT_TOKEN_BANK_ADDRESS, // 修改这里，使用PERMIT_TOKEN_BANK_ADDRESS
                abi: TokenBank_ABI,
                functionName: 'withdraw',
                args: [parseEther(withdrawAmount)],
                account: address,
            });

            console.log('Withdraw hash:', hash);
            setTxHash(hash);

            // 等待交易确认后刷新余额
            await publicClient.waitForTransactionReceipt({ hash });
            fetchBalances();
            setWithdrawAmount('');
        } catch (error) {
            console.error('取款失败:', error);
        } finally {
            setIsLoading(false);
        }
    };

    // 通过签名存款（permit + 存款）
    const handlePermitDeposit = async () => {
        if (typeof window.ethereum === 'undefined') {
            alert('请安装 MetaMask');
            return;
        }

        if (!address || !permitDepositAmount) return;
        setIsPermitLoading(true);
        setTxHash('');

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            // 获取 PermitTokenBank 合约
            const tokenBankContract = getContract({
                address: PERMIT_TOKEN_BANK_ADDRESS,
                abi: TokenBank_ABI,
                client: publicClient,
            });

            // 获取 Token 合约地址
            const tokenAddress = await tokenBankContract.read.token() as `0x${string}`;

            // 获取 Token 合约实例（带 permit 方法）
            const tokenContract = getContract({
                address: tokenAddress,
                // 使用ERC20Permit标准ABI
                abi: [
                    {
                        "type": "function",
                        "name": "nonces",
                        "inputs": [{ "name": "owner", "type": "address" }],
                        "outputs": [{ "name": "", "type": "uint256" }],
                        "stateMutability": "view"
                    },
                    {
                        "type": "function",
                        "name": "DOMAIN_SEPARATOR",
                        "inputs": [],
                        "outputs": [{ "name": "", "type": "bytes32" }],
                        "stateMutability": "view"
                    }
                ],
                client: publicClient,
            });

            // 获取nonce
            const nonce = await tokenContract.read.nonces([address]);

            // 设置deadline为当前时间+1小时
            const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);

            // 构造 EIP-712 域
            const domain = {
                name: 'AndyToken', // Token 名称，需与合约一致
                version: '1',
                chainId: sepolia.id,
                verifyingContract: tokenAddress,
            };

            // EIP-712 类型定义
            const types = {
                Permit: [
                    { name: 'owner', type: 'address' },
                    { name: 'spender', type: 'address' },
                    { name: 'value', type: 'uint256' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'deadline', type: 'uint256' },
                ],
            };

            // EIP-712 消息内容
            const value = {
                owner: address,
                spender: PERMIT_TOKEN_BANK_ADDRESS,
                value: parseEther(permitDepositAmount),
                nonce,
                deadline,
            };

            // 进行 EIP-712 签名
            const signature = await signTypedData(walletClient, {
                account: address,
                domain,
                types,
                primaryType: 'Permit',
                message: value,
            });

            // 从签名中提取v, r, s
            // 使用 viem 的签名格式提取 r, s, v
            const r = signature.slice(0, 66) as Hex;
            const s = ('0x' + signature.slice(66, 130)) as Hex;
            const v = parseInt('0x' + signature.slice(130, 132), 16);

            // 调用permitDeposit方法
            const hash = await walletClient.writeContract({
                address: PERMIT_TOKEN_BANK_ADDRESS,
                abi: TokenBank_ABI,
                functionName: 'permitDeposit',
                args: [parseEther(permitDepositAmount), deadline, v, r, s],
                account: address,
            });

            console.log('Permit Deposit hash:', hash);
            setTxHash(hash);

            // 等待交易确认后刷新余额
            await publicClient.waitForTransactionReceipt({ hash });
            fetchBalances();
            setPermitDepositAmount('');
        } catch (error) {
            console.error('签名存款失败:', error);
        } finally {
            setIsPermitLoading(false);
        }
    };

    // 监听 address 变化，自动刷新余额
    useEffect(() => {
        const fetchEthBalance = async () => {
            if (!address) return;

            const balance = await publicClient.getBalance({
                address: address,
            });

            setBalance(formatEther(balance));
        };

        if (address) {
            fetchEthBalance();
            fetchBalances();
        }
    }, [address]);

    // 页面渲染
    return (
        <div className="min-h-screen flex flex-col items-center justify-center p-8">
            <h1 className="text-3xl font-bold mb-8">Token Bank Demo</h1>

            <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-2xl">
                {!isConnected ? (
                    <button
                        onClick={connectWallet}
                        className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 transition-colors"
                    >
                        连接 MetaMask
                    </button>
                ) : (
                    <div className="space-y-4">
                        {/* 钱包信息 */}
                        <div className="text-center">
                            <p className="text-gray-600">钱包地址:</p>
                            <p className="font-mono break-all">{address}</p>
                        </div>
                        <div className="text-center">
                            <p className="text-gray-600">当前网络:</p>
                            <p className="font-mono">
                                {sepolia.name} (Chain ID: {chainId})
                            </p>
                        </div>
                        <div className="text-center">
                            <p className="text-gray-600">ETH 余额:</p>
                            <p className="font-mono">{balance} ETH</p>
                        </div>

                        {/* Token 余额显示 */}
                        <div className="text-center">
                            <p className="text-gray-600">Token 余额:</p>
                            <p className="font-mono">{tokenBalance} Token</p>
                        </div>

                        {/* 存款余额显示 */}
                        <div className="text-center">
                            <p className="text-gray-600">存款余额:</p>
                            <p className="font-mono">{depositBalance} Token</p>
                        </div>

                        {/* 普通存款表单 */}
                        <div className="border p-4 rounded-lg">
                            <h3 className="text-lg font-semibold mb-2">存款</h3>
                            <div className="flex space-x-2">
                                <input
                                    type="text"
                                    value={depositAmount}
                                    onChange={(e) => setDepositAmount(e.target.value)}
                                    placeholder="输入存款金额"
                                    className="flex-1 border rounded p-2"
                                    disabled={isLoading}
                                />
                                <button
                                    onClick={handleDeposit}
                                    disabled={isLoading || !depositAmount}
                                    className={`px-4 py-2 rounded ${isLoading ? 'bg-gray-400' : 'bg-green-500 hover:bg-green-600'} text-white`}
                                >
                                    {isLoading ? '处理中...' : '存款'}
                                </button>
                            </div>
                        </div>

                        {/* 签名存款表单 */}
                        <div className="border p-4 rounded-lg bg-blue-50">
                            <h3 className="text-lg font-semibold mb-2">通过签名存款 (EIP-2612)</h3>
                            <div className="flex space-x-2">
                                <input
                                    type="text"
                                    value={permitDepositAmount}
                                    onChange={(e) => setPermitDepositAmount(e.target.value)}
                                    placeholder="输入存款金额"
                                    className="flex-1 border rounded p-2"
                                    disabled={isPermitLoading}
                                />
                                <button
                                    onClick={handlePermitDeposit}
                                    disabled={isPermitLoading || !permitDepositAmount}
                                    className={`px-4 py-2 rounded ${isPermitLoading ? 'bg-gray-400' : 'bg-blue-500 hover:bg-blue-600'} text-white`}
                                >
                                    {isPermitLoading ? '处理中...' : '签名存款'}
                                </button>
                            </div>
                            <p className="text-xs text-gray-600 mt-2">无需预先授权，一步完成签名和存款</p>
                        </div>

                        {/* 取款表单 */}
                        <div className="border p-4 rounded-lg">
                            <h3 className="text-lg font-semibold mb-2">取款</h3>
                            <div className="flex space-x-2">
                                <input
                                    type="text"
                                    value={withdrawAmount}
                                    onChange={(e) => setWithdrawAmount(e.target.value)}
                                    placeholder="输入取款金额"
                                    className="flex-1 border rounded p-2"
                                    disabled={isLoading}
                                />
                                <button
                                    onClick={handleWithdraw}
                                    disabled={isLoading || !withdrawAmount}
                                    className={`px-4 py-2 rounded ${isLoading ? 'bg-gray-400' : 'bg-red-500 hover:bg-red-600'} text-white`}
                                >
                                    {isLoading ? '处理中...' : '取款'}
                                </button>
                            </div>
                        </div>

                        {/* 交易哈希显示 */}
                        {txHash && (
                            <div className="text-center">
                                <p className="text-gray-600">交易哈希:</p>
                                <p className="font-mono break-all text-blue-500">{txHash}</p>
                            </div>
                        )}
                        {/* 断开连接 */}
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