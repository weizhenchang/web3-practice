//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义一个合约
contract Counter {
    // 状态变量声明
    uint public counter;
    
    function add(uint x) public {
        counter += x;
    }
    
    function get() public view returns (uint) {
        return counter;
    }
}