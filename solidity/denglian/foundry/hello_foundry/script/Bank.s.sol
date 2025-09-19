// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";

/*
    部署合约:
        forge script script/Bank.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
        "contractName": "Bank",
        "contractAddress": "0xD3b262f099cD884C54d6488E7E25BC5ed6067Cf8"
    查看管理员地址:
        cast call 0xD3b262f099cD884C54d6488E7E25BC5ed6067Cf8 "owner()(address)" --rpc-url sepolia
    管理员变更:
        cast send 0xD3b262f099cD884C54d6488E7E25BC5ed6067Cf8 "changeOwner(address)" 0xe34fFbF11Ad27bE11d866179C2bC09DDeC693543 --rpc-url sepolia --private-key $PRIVATE_KEY
    查看余额:
        cast balance 0xD3b262f099cD884C54d6488E7E25BC5ed6067Cf8 --rpc-url sepolia
    生成 calldata(为在safe web端调用bank合约做准备):
        cast calldata "withdraw(uint256)" 10000000000000000
    
*/
contract BankScript is Script {
    Bank public bank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        bank = new Bank();

        vm.stopBroadcast();
    }
}
