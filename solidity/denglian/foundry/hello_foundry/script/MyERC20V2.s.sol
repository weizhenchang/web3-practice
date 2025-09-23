// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyERC20} from "../src/MyERC20V2.sol";

// 相关部署和操作
// cd /Users/weizhenchang/Code/web3-practice/solidity/denglian/foundry/hello_foundry
// 参考: nodejs/denglian/viem/hello_viem/demo/src/watchNftMarket.ts
// 部署 MyERC20 合约 (0x52e1c3C1FE9e1b6298B9C08bCfB4BbFbDd2AeCB5)
// forge script script/MyERC20V2.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

contract MyERC20Script is Script {
    MyERC20 public myERC20;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        myERC20 = new MyERC20();

        vm.stopBroadcast();
    }
}
