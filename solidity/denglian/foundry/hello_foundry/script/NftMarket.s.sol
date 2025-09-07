// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NftMarket.sol";

contract NftMarketScript is Script {
    NFTMarket public nftMarket;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // MyERC20 myERC20 = new MyERC20();
        // nftMarket = new NFTMarket(address(myERC20));
        address myERC20Contract = address(
            0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
        );
        nftMarket = new NFTMarket(myERC20Contract);

        vm.stopBroadcast();
    }
}
