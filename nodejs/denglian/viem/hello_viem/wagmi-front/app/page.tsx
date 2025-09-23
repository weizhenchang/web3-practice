'use client'; // Next.js 指定为客户端组件

import { useEffect, useState } from 'react'; // React 的 hooks
import {
  useAccount, // 获取钱包账户信息
  useBalance, // 获取钱包余额
  useChainId, // 获取当前链ID
  useChains, // 获取所有支持的链
  useConnect, // 连接钱包
  useDisconnect, // 断开钱包连接
  useReadContract, // 读取合约
  useWaitForTransactionReceipt, // 等待交易回执
  useWriteContract, // 写入合约
} from 'wagmi';
import { readContract } from 'wagmi/actions'; // 从 wagmi/actions 导入 readContract
import { injected, walletConnect } from 'wagmi/connectors'; // 钱包连接器
import NFTMarket_ABI from './contracts/NFTMarket.json'; // NFTMarket 合约 ABI
import { config } from './providers'; // 从 providers.tsx 导入 config

// 市场合约地址
const NFTMARKET_ADDRESS = "0x2da3B30C617FDEC54c64225547B74CB39F8a6181";
// NFT合约地址
const NFT_ADDRESS = "0xc1F2235d72e7dAA67B2D9d262155B3e77fc9F5e4";

// 我的WalletConnect NFTMarket项目ID
// https://dashboard.reown.com/f626f1bd-c0ff-476d-a4f2-4243514ad162/f26030ee-942a-4963-a689-ee02c1d22254
const projectId = '4a099e4832dcb4dcb318e82bc28e2657';

export default function Home() {
  // 钱包相关 hooks
  const { address, isConnected } = useAccount(); // 当前钱包地址、连接状态
  const { connect } = useConnect(); // 连接钱包方法
  const { disconnect } = useDisconnect(); // 断开钱包方法
  const chainId = useChainId(); // 当前链ID
  const chains = useChains(); // 支持的链
  const currentChain = chains.find(chain => chain.id === chainId); // 当前链对象

  // 状态变量
  // const [activeTab, setActiveTab] = useState('counter'); // 'counter', 'list', 'buy'
  const [nftContractAddress, setNftContractAddress] = useState(NFT_ADDRESS);
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  // const [listingId, setListingId] = useState('');
  const [listings, setListings] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  // 使用 useBalance 获取余额
  const { data: balance } = useBalance({
    address,
  });

  // 读取 NFTMarket 合约的 lastGoodsId
  const { data: lastGoodsId, refetch: refetchLastGoodsId } = useReadContract({
    address: NFTMARKET_ADDRESS as `0x${string}`,
    abi: NFTMarket_ABI,
    // functionName: 'nextListingId',
    functionName: 'lastGoodsId',
  });

  // 使用 useWriteContract 写入合约数据
  const {
    writeContract,
    isPending,
    data: hash,
    isSuccess,
    isError,
    error
  } = useWriteContract();

  // 等待交易完成
  const {
    isLoading: isWaiting,
    isSuccess: isConfirmed
  } = useWaitForTransactionReceipt({
    hash
  });

  // 处理NFT上架
  const handleListNFT = () => {
    if (!nftContractAddress || !tokenId || !price) {
      alert('请填写所有必填字段');
      return;
    }

    writeContract({
      address: NFTMARKET_ADDRESS as `0x${string}`,
      abi: NFTMarket_ABI,
      functionName: 'list',
      args: [
        nftContractAddress,
        BigInt(tokenId),
        BigInt(price)
      ],
    });
  };

  // 处理NFT购买
  // 卖家授权NFT给市场
  // cast send 0xc1F2235d72e7dAA67B2D9d262155B3e77fc9F5e4 "approve(address, uint256)" 0x2da3B30C617FDEC54c64225547B74CB39F8a6181 1 --rpc-url sepolia --private-key $RAND_PRIVATE_KEY
  // 买家授权代币给市场
  // cast send 0x52e1c3C1FE9e1b6298B9C08bCfB4BbFbDd2AeCB5 "approve(address, uint256)" 0x2da3B30C617FDEC54c64225547B74CB39F8a6181 888 --rpc-url sepolia --private-key $PRIVATE_KEY
  const handleBuyNFT = (id: string) => {
    writeContract({
      address: NFTMARKET_ADDRESS as `0x${string}`,
      abi: NFTMarket_ABI,
      functionName: 'buyNFT',
      args: [BigInt(id)],
    });
  };

  // 获取上架列表
  const fetchListings = async () => {
    if (!lastGoodsId) return;

    setIsLoading(true);
    const newListings = [];

    for (let i = 1; i <= Number(lastGoodsId); i++) {
      console.log("goodsId:", i);
      try {
        // 修改这里，添加config参数
        const listing = await readContract(config, {
          address: NFTMARKET_ADDRESS as `0x${string}`,
          abi: NFTMarket_ABI,
          functionName: 'goodsMap',
          args: [BigInt(i)] as const,
        }) as any[];

        // 显示所有列表项，包括非活跃的
        console.log("listing", listing);
        if (listing && listing[4]) {
          // 修改这里，将listing作为数组处理
          newListings.push({
            id: i,
            seller: listing[0],
            nftContract: listing[1],
            tokenId: listing[2].toString(),
            price: listing[3].toString(),
            isActive: listing[4]
          });
        }
      } catch (error) {
        console.error(`Error fetching listing ${i}:`, error);
      }
    }

    setListings(newListings);
    setIsLoading(false);
  };

  // 监听交易完成状态
  useEffect(() => {
    if (isSuccess) {
      refetchLastGoodsId();
      fetchListings();
    }
  }, [isSuccess, refetchLastGoodsId]);

  // 当lastGoodsId变化时，获取上架列表
  useEffect(() => {
    if (lastGoodsId) {
      fetchListings();
    }
  }, [lastGoodsId]);

  // 辅助函数：截断地址显示
  const truncateAddress = (address: string) => {
    return `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;
  };

  // 连接钱包处理函数
  const handleConnectMetaMask = () => {
    connect({ connector: injected() });
  };

  // 连接WalletConnect处理函数
  const handleConnectWalletConnect = () => {
    connect({
      connector: walletConnect({
        projectId,
        showQrModal: true,
        metadata: {
          name: 'NFT Market',
          description: 'NFT Market with WalletConnect',
          url: window.location.host,
          icons: [window.location.origin + '/vercel.svg']
        }
      })
    });
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-3xl font-bold mb-8">NFT Market</h1>

      <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-2xl">
        {!isConnected ? (
          <div className="space-y-4">
            <button
              onClick={handleConnectMetaMask}
              className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 transition-colors"
            >
              连接 MetaMask
            </button>
            <button
              onClick={handleConnectWalletConnect}
              className="w-full bg-purple-500 text-white py-2 px-4 rounded hover:bg-purple-600 transition-colors"
            >
              使用 WalletConnect 连接移动端钱包
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            {/* 现有的钱包信息显示 */}
            <div className="text-center">
              <p className="text-gray-600">钱包地址:</p>
              <p className="font-mono break-all">{address}</p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">当前网络:</p>
              <p className="font-mono">
                {currentChain?.name || '未知网络'} (Chain ID: {chainId})
              </p>
            </div>
            <div className="text-center">
              <p className="text-gray-600">余额:</p>
              <p className="font-mono">
                {balance?.formatted || '0'} {balance?.symbol}
              </p>
            </div>
            {/* 添加 NFT 上架表单 */}
            <div className="border-t pt-4">
              <h2 className="text-xl font-bold mb-4">上架 NFT</h2>
              <div className="space-y-2">
                <input
                  type="text"
                  placeholder="NFT 合约地址"
                  value={nftContractAddress}
                  onChange={(e) => setNftContractAddress(e.target.value)}
                  className="w-full p-2 border rounded"
                />
                <input
                  type="number"
                  placeholder="Token ID"
                  value={tokenId}
                  onChange={(e) => setTokenId(e.target.value)}
                  className="w-full p-2 border rounded"
                />
                <input
                  type="number"
                  placeholder="价格"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  className="w-full p-2 border rounded"
                />
                <button
                  onClick={handleListNFT}
                  disabled={isPending}
                  className={`w-full py-2 px-4 rounded ${isPending ? 'bg-gray-400' : 'bg-blue-500 hover:bg-blue-600'} text-white`}
                >
                  {isPending ? '处理中...' : '上架 NFT'}
                </button>
              </div>
            </div>

            {/* 显示上架列表 */}
            <div className="border-t pt-4">
              <h2 className="text-xl font-bold mb-4">NFT 列表</h2>
              {isLoading ? (
                <p>加载中...</p>
              ) : listings.length > 0 ? (
                <div className="space-y-4">
                  {listings.map((listing) => (
                    <div key={listing.id} className="border p-4 rounded">
                      <p>卖家: {truncateAddress(listing.seller)}</p>
                      <p>NFT 合约: {truncateAddress(listing.nftContract)}</p>
                      <p>Token ID: {listing.tokenId}</p>
                      <p>价格: {listing.price}</p>
                      <button
                        onClick={() => handleBuyNFT(listing.id)}
                        disabled={isPending}
                        className={`mt-2 w-full py-2 px-4 rounded ${isPending ? 'bg-gray-400' : 'bg-green-500 hover:bg-green-600'} text-white`}
                      >
                        {isPending ? '处理中...' : '购买'}
                      </button>
                      {isError && error && (
                        <p className="mt-2 text-red-500 break-all">
                          购买失败: {error.message}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p>暂无上架的 NFT</p>
              )}
            </div>

            <button
              onClick={() => disconnect()}
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