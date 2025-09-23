'use client'; // Next.js 指定为客户端组件

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'; // 引入 react-query 的核心对象和 Provider
import { createConfig, http, WagmiProvider } from 'wagmi'; // 引入 wagmi 的配置、http工具和 Provider
import { foundry, optimism, sepolia } from 'wagmi/chains'; // 引入常用链配置
import { injected, walletConnect } from 'wagmi/connectors'; // 引入钱包连接器

// 我的WalletConnect NFTMarket项目ID
// https://dashboard.reown.com/f626f1bd-c0ff-476d-a4f2-4243514ad162/f26030ee-942a-4963-a689-ee02c1d22254
const projectId = '4a099e4832dcb4dcb318e82bc28e2657';

// 导出config对象，使其可以在其他文件中使用
export const config = createConfig({
  chains: [foundry, optimism, sepolia], // 支持的链
  transports: {
    [foundry.id]: http(), // foundry链用本地http
    [optimism.id]: http(), // optimism链用本地http
    [sepolia.id]: http('https://eth-sepolia.public.blastapi.io'), // sepolia链用指定RPC
  },
  connectors: [
    injected(), // 浏览器钱包（如MetaMask）
    walletConnect({ projectId }), // WalletConnect 钱包
  ],
});

const queryClient = new QueryClient(); // 创建 react-query 客户端

// Providers 组件，包裹全局 Provider
export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}> {/* wagmi 全局Provider，注入链和钱包配置 */}
      <QueryClientProvider client={queryClient}> {/* react-query Provider，注入 queryClient */}
        {children} {/* 渲染所有子组件 */}
      </QueryClientProvider>
    </WagmiProvider>
  );
}