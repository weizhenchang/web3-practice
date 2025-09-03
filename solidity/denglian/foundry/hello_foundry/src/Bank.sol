//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
编写一个 Bank 合约，实现功能：

可以通过 Metamask 等钱包直接给 Bank 合约地址存款
在 Bank 合约记录每个地址的存款金额
编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
用数组记录存款金额的前 3 名用户
*/

contract Bank {
    uint8 public constant RANKINGS_LEN = 3; // 排行榜长度
    address immutable owner = msg.sender; // 管理员地址
    mapping(address => uint256) public balances; // 地址 => 余额 map
    address[RANKINGS_LEN] public rankings; // 存款金额前三名的地址 array
    uint256 public fallbackCount; // fallback函数的调用次数

    // 充值
    receive() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value; // 累加对应地址上的余额

            // 更新排行榜
            updateRankings(msg.sender);
        }
    }

    // 提取
    function withdraw(uint amount) public {
        // 仅管理员可以提取资金
        require(msg.sender == owner, "only owner can withdraw");
        // 检查提取金额
        require(amount > 0, "amount require gt zero");
        require(amount <= address(this).balance, "balance not enough");
        // 执行提取
        (bool success, bytes memory data) = msg.sender.call{value: amount}(
            new bytes(0)
        );

        // require(success, "transfer failed");
        if (!success) {
            // 如果有返回数据，尝试解析 revert 原因
            if (data.length > 0) {
                // revert reason 是 ABI 编码的字符串
                assembly {
                    let returndata_size := mload(data)
                    revert(add(data, 32), returndata_size)
                }
            } else {
                revert("transfer failed: no revert reason");
            }
        }
    }

    fallback() external {
        fallbackCount++;
    }

    // 更新排行榜
    function updateRankings(address addr) private {
        address[RANKINGS_LEN] memory newRankings = rankings;

        uint balance = balances[addr];

        // 移除已存在的地址
        for (uint i = 0; i < RANKINGS_LEN; i++) {
            if (addr == newRankings[i]) {
                // 前移覆盖
                for (uint j = i; j < RANKINGS_LEN - 1; j++) {
                    newRankings[j] = newRankings[j + 1];
                }
                newRankings[RANKINGS_LEN - 1] = address(0);
                break;
            }
        }

        // 将地址插入正确的位置
        for (uint i = 0; i < RANKINGS_LEN; i++) {
            if (
                newRankings[i] == address(0) ||
                balance > balances[newRankings[i]]
            ) {
                // 后移
                for (uint j = RANKINGS_LEN - 1; j > i; j--) {
                    newRankings[j] = newRankings[j - 1];
                }
                newRankings[i] = addr;
                break;
            }
        }

        rankings = newRankings;
    }
}
