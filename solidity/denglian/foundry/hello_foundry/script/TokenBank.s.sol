// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {TokenBank, MyERC20} from "../src/TokenBank.sol";

/*
    部署合约:
        forge script script/TokenBank.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
        "contractName": "MyERC20",
        "contractAddress": "0x107da14106564e39f0267155cc48c98725ffbfcc"
        "contractName": "TokenBank",
        "contractAddress": "0x58aD83e2a7d59B76A60C19fC38fc25C03f123a58"
    查询余额:
        cast call 0x107da14106564e39f0267155cc48c98725ffbfcc "balanceOf(address)(uint256)" 0xC7eD154C2309Ec99e6d7cf11B96564d1d1838675 --rpc-url $SEPOLIA_RPC_URL
*/
contract TokenBankScript is Script {
    TokenBank public tokenBank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        MyERC20 myERC20 = new MyERC20();
        tokenBank = new TokenBank(address(myERC20));

        vm.stopBroadcast();
    }
}
