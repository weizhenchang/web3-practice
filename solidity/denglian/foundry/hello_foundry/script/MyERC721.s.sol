// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyNFTCollection} from "../src/MyERC721.sol";

// 相关部署和操作
// cd /Users/weizhenchang/Code/web3-practice/solidity/denglian/foundry/hello_foundry
// 参考: nodejs/denglian/viem/hello_viem/demo/src/watchNftMarket.ts
// 部署 MyNFTCollection 合约 (0xc1F2235d72e7dAA67B2D9d262155B3e77fc9F5e4)
// forge script script/MyERC721.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
// mint nft给 随机私钥生成的测试账号
// cast send 0xc1F2235d72e7dAA67B2D9d262155B3e77fc9F5e4 "mintBatch(address[],string[])" '[0x35d442b2FbD98d94aB7a506B51Bf0760D9e24076]' '["ipfs://bafybeiczsnn2a4utiomwcck2x7or4wj7qnxlyjoavlvvlqxl32vxe6m4mm/1.json"]' --rpc-url sepolia --private-key $PRIVATE_KEY

contract MyNFTCollectionScript is Script {
    MyNFTCollection public myNFTCollection;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        myNFTCollection = new MyNFTCollection();

        vm.stopBroadcast();
    }
}
