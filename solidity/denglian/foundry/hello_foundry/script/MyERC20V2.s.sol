// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyERC20} from "../src/MyERC20V2.sol";

contract MyERC20Script is Script {
    MyERC20 public myERC20;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        myERC20 = new MyERC20();

        vm.stopBroadcast();
    }
}
