// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {TokenBank, MyERC20} from "../src/TokenBank.sol";

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
