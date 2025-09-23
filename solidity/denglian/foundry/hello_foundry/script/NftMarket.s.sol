// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NftMarket.sol";

// 相关部署和操作
// cd /Users/weizhenchang/Code/web3-practice/solidity/denglian/foundry/hello_foundry
// 参考: nodejs/denglian/viem/hello_viem/demo/src/watchNftMarket.ts
// 部署 NftMarket 合约 (0x2da3B30C617FDEC54c64225547B74CB39F8a6181)
// forge script script/NftMarket.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

contract NftMarketScript is Script {
    NFTMarket public nftMarket;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // MyERC20 myERC20 = new MyERC20();
        // nftMarket = new NFTMarket(address(myERC20));
        address myERC20Contract = address(
            0x52e1c3C1FE9e1b6298B9C08bCfB4BbFbDd2AeCB5
        );
        nftMarket = new NFTMarket(myERC20Contract);

        vm.stopBroadcast();
    }
}
