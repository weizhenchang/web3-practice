import dotenv from "dotenv"; // 加载环境变量
import {
    createPublicClient, // 把wei单位转为以太单位
    http, // HTTP连接
    publicActions // 公共链操作扩展
} from "viem";
import { foundry } from "viem/chains"; // 导入本地foundry链配置

dotenv.config(); // 加载.env文件里的环境变量

// 相关部署和操作
// cd /Users/weizhenchang/Code/web3-practice/solidity/denglian/foundry/hello_foundry
// 部署 MyERC20V2 合约(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9)
// forge script script/MyERC20V2.s.sol --rpc-url local --private-key $LOCAL_PRIVATE_KEY --broadcast
// 部署 NftMarket 合约(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9)
// forge script script/NftMarket.s.sol --rpc-url local --private-key $LOCAL_PRIVATE_KEY --broadcast
// 部署 MyERC721 合约(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512)
// forge script script/MyERC721.s.sol --rpc-url local --private-key $LOCAL_PRIVATE_KEY --broadcast
// mint nft给 $LOCAL_ADDRESS1
// cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "mintBatch(address[],string[])" '[0x70997970C51812dc3A010C7d01b50e0d17dc79C8]' '["ipfs://bafybeiczsnn2a4utiomwcck2x7or4wj7qnxlyjoavlvvlqxl32vxe6m4mm/1.json"]' --private-key $LOCAL_PRIVATE_KEY
const NFT_MARKET_ADDRESS = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"; // NFTMarket合约地址

const main = async () => {
    // 创建公共客户端（只读），连接本地foundry链
    const publicClient = createPublicClient({
        chain: foundry,
        transport: http(process.env.RPC_URL!), // 用环境变量里的RPC_URL连接
    }).extend(publicActions); // 扩展公共链操作

    console.log('开始监听 NFTMarket 合约相关事件...');

    // 监听 NFTOn 事件
    // 卖家上架tokenId=1的NFT，价格888token
    // cast send 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "list(address,uint256,uint256)" 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 1 888 --private-key $LOCAL_PRIVATE_KEY1
    const unwatchNFTOn = publicClient.watchEvent({
        address: NFT_MARKET_ADDRESS, // 要监听的合约地址
        event: { // 事件定义
            type: 'event',
            name: 'NFTOn', // 事件名
            inputs: [ // 事件参数
                { type: 'uint256', name: 'goodsId', indexed: true },
                { type: 'address', name: 'seller', indexed: true },
                { type: 'address', name: 'nftContract', indexed: true },
                { type: 'uint256', name: 'tokenId' },
                { type: 'uint256', name: 'price' }
            ]
        },
        onLogs: (logs) => { // 事件触发时的回调
            logs.forEach((log) => {
                if (log.args.price !== undefined) {
                    console.log('\n检测到新的NFT上架事件:');
                    console.log(`goodsId: ${log.args.goodsId}`);
                    console.log(`seller: ${log.args.seller}`);
                    console.log(`nftContract: ${log.args.nftContract}`);
                    console.log(`tokenId: ${log.args.tokenId}`);
                    console.log(`price: ${log.args.price}`);
                    console.log(`交易哈希: ${log.transactionHash}`); // 打印交易哈希
                    console.log(`区块号: ${log.blockNumber}`); // 打印区块号
                }
            });
        }
    });

    // 监听 NFTOff 事件
    // cast send 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "cancelListing(uint256)" 1 --private-key $LOCAL_PRIVATE_KEY1
    const unwatchNFTOff = publicClient.watchEvent({
        address: NFT_MARKET_ADDRESS, // 要监听的合约地址
        event: { // 事件定义
            type: 'event',
            name: 'NFTOff', // 事件名
            inputs: [ // 事件参数
                { type: 'uint256', name: 'goodsId', indexed: true },
            ]
        },
        onLogs: (logs) => { // 事件触发时的回调
            logs.forEach((log) => {
                if (log.args.goodsId !== undefined) {
                    console.log('\n检测到新的NFT下架事件:');
                    console.log(`goodsId: ${log.args.goodsId}`);
                    console.log(`交易哈希: ${log.transactionHash}`); // 打印交易哈希
                    console.log(`区块号: ${log.blockNumber}`); // 打印区块号
                }
            });
        }
    });

    // 监听 NFTSold 事件
    // 卖家授权nft给市场
    // cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "approve(address,uint256)" 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 1 --private-key $LOCAL_PRIVATE_KEY1
    // 买家授权token给市场
    // cast send 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "approve(address,uint256)" 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 1000 --private-key $LOCAL_PRIVATE_KEY
    // 发起购买
    // cast send 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "buyNFT(uint256)" 2 --private-key $LOCAL_PRIVATE_KEY
    const unwatchNFTSold = publicClient.watchEvent({
        address: NFT_MARKET_ADDRESS, // 要监听的合约地址
        event: { // 事件定义
            type: 'event',
            name: 'NFTSold', // 事件名
            inputs: [ // 事件参数
                { type: 'uint256', name: 'goodsId', indexed: true },
                { type: 'address', name: 'buyer', indexed: true },
                { type: 'address', name: 'seller', indexed: true },
                { type: 'address', name: 'nftContract' },
                { type: 'uint256', name: 'tokenId' },
                { type: 'uint256', name: 'price' }
            ]
        },
        onLogs: (logs) => { // 事件触发时的回调
            logs.forEach((log) => {
                if (log.args.price !== undefined) {
                    console.log('\n检测到新的NFT成交事件:');
                    console.log(`goodsId: ${log.args.goodsId}`);
                    console.log(`buyer: ${log.args.buyer}`);
                    console.log(`seller: ${log.args.seller}`);
                    console.log(`nftContract: ${log.args.nftContract}`);
                    console.log(`tokenId: ${log.args.tokenId}`);
                    console.log(`price: ${log.args.price}`);
                    console.log(`交易哈希: ${log.transactionHash}`); // 打印交易哈希
                    console.log(`区块号: ${log.blockNumber}`); // 打印区块号
                }
            });
        }
    });

    // 保持程序运行，监听 Ctrl+C 退出
    process.on('SIGINT', () => {
        console.log('\n停止监听...');

        unwatchNFTOn(); // 停止 NFTOn 事件监听
        unwatchNFTOff(); // 停止 NFTOff 事件监听
        unwatchNFTSold(); // 停止 NFTSold 事件监听

        process.exit(); // 退出程序
    });
};

main().catch((error) => {
    console.error('发生错误:', error); // 捕获并打印主函数异常
    process.exit(1); // 异常时退出程序
}); 