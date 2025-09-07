// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyNFTCollection} from "../src/MyERC721.sol";

contract MyNFTCollectionScript is Script {
    MyNFTCollection public myNFTCollection;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        myNFTCollection = new MyNFTCollection();

        vm.stopBroadcast();
    }
}
