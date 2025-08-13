//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
在 该挑战 的 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：

要求存款金额 >0.001 ether（用modifier权限控制）
BigBank 合约支持转移管理员
编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。

BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后

Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。
*/

interface IBank {
    function deposit(uint amount) external payable;
    function withdraw(uint amount) external;
    function getBalance() external view returns (uint);
}

contract Bank is IBank {
    uint8 constant RANKINGS_LEN = 3; // 排行榜长度
    address public owner; // 管理员地址
    mapping(address => uint256) public balances; // 地址 => 余额 map
    address[RANKINGS_LEN] public rankings; // 存款金额前三名的地址 array
    uint256 public fallbackCount; // fallback函数的调用次数

    constructor(){
        owner = msg.sender;
    }

    // 主动充值
    function deposit(uint amount) virtual override public payable {
        require(amount > 0, "amount require gt zero");
        require(amount == msg.value, "amount not match");
        _deposit();
    }
    // 接受转账
    receive() virtual external payable {
        require(msg.value > 0, "msg.value require gt zero");
        _deposit();
    }
    // 处理充值
    function _deposit() internal {
        balances[msg.sender] += msg.value; // 累加对应地址上的余额

        // 更新排行榜
        updateRankings(msg.sender);
    }

    // 提取
    function withdraw(uint amount) virtual override public {
        // 仅管理员可以提取资金
        require(msg.sender == owner, "only owner can withdraw");
        // 检查提取金额
        require(amount > 0, "amount require gt zero");
        require(amount <= address(this).balance, "balance not enough");
        // 执行提取
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, 'transfer failed');
    }

    // 获取余额
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    fallback() external {
        fallbackCount++;
    }

    // 更新排行榜
    function updateRankings(address addr) private {
        address[RANKINGS_LEN] memory newRankings = rankings;

        uint balance = balances[addr];

        // 移除已存在的地址
        for(uint i=0;i<RANKINGS_LEN;i++){
            if (addr == newRankings[i]) {
                for (uint j=i;j<RANKINGS_LEN-1;j++) {
                    newRankings[j] = newRankings[j+1];
                }
                newRankings[RANKINGS_LEN-1] = address(0);
                break;
            }
        }

        // 将地址插入正确的位置
        for(uint i=0;i<RANKINGS_LEN;i++){
            if (newRankings[i] == address(0) || balance > balances[newRankings[i]]) {
                for (uint j=RANKINGS_LEN-1;j>i;j--) {
                    newRankings[j] = newRankings[j-1];
                }
                newRankings[i] = addr;
                break;
            }
        }

        rankings = newRankings;
    }
}

contract BigBank is Bank {
    // 限制充值金额
    modifier amountLimit {
        require(msg.value > 0.001 ether, "Amount must be greater than 0.001 ether");
        _;
    }

    // 主动充值
    function deposit(uint amount) override public payable amountLimit {
        require(amount == msg.value, "amount not match");
        super._deposit();
    }
    // 接受转账
    receive() override external payable amountLimit {
        super._deposit();
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "only owner can owner");
        require(newOwner != address(0), "newOwner must not be 0 address");
        owner = newOwner;
    }
    
}

contract Admin is BigBank {

    // 取款
    function adminWithdraw(BigBank bank)public{
        bank.withdraw(bank.getBalance());
    }

}