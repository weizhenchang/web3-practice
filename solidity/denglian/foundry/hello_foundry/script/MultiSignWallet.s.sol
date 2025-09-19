// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MultiSignWallet} from "../src/MultiSignWallet.sol";
/*
    部署合约(本地navil):
        forge script script/MultiSignWallet.s.sol --rpc-url local --private-key $LOCAL_PRIVATE_KEY --broadcast
        Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    查询多签钱包余额:
        cast balance 0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url local
    给多签钱包转账:
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url local --value 1ether --private-key $LOCAL_PRIVATE_KEY
    提交新的交易提案:
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "submitTransaction(address,uint256,bytes)" 0x90F79bf6EB2c4f870365E785982E1f101E93b906 10000000000000000 0x --rpc-url local --private-key $LOCAL_PRIVATE_KEY
    确认交易提案(本地账号0):
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "confirmTransaction(uint256)" 0 --rpc-url local --private-key $LOCAL_PRIVATE_KEY
    确认交易提案(本地账号1):
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "confirmTransaction(uint256)" 0 --rpc-url local --private-key $LOCAL_PRIVATE_KEY1
    撤销对交易提案的确认(本地账号1):
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "revokeConfirmation(uint256)" 0 --rpc-url local --private-key $LOCAL_PRIVATE_KEY1
    重新确认交易提案(本地账号1):
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "confirmTransaction(uint256)" 0 --rpc-url local --private-key $LOCAL_PRIVATE_KEY1
    执行已获得足够确认数的交易提案:
        cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "executeTransaction(uint256)" 0 --rpc-url local --private-key $LOCAL_PRIVATE_KEY
    
    
    
    获取所有多签持有人地址:
        cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getOwners()" --rpc-url local
    查询某个地址是否是多签持有人:
        cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "isOwner(address)(bool)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url local
    获取交易详情:
        cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getTransaction(uint256)(address,uint256,bytes,bool,uint256)" 0 --rpc-url local
*/
contract MultiSignWalletScript is Script {
    MultiSignWallet public multiSignWallet;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 使用本地navil前三个账号
        address[] memory _owners = new address[](3);
        _owners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        _owners[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        _owners[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        uint256 numConfirmationsRequired = 2;
        multiSignWallet = new MultiSignWallet(
            _owners,
            numConfirmationsRequired
        );

        vm.stopBroadcast();
    }
}
