//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。

TokenBank 有两个方法：

deposit() : 需要记录每个地址的存入数量；
withdraw（）: 用户可以提取自己的之前存入的 token。
*/

// 从 OpenZeppelin GitHub 导入 ERC20 合约
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyERC20 is ERC20 {
    // 构造函数：初始化代币名称、符号和初始供应量
    constructor() ERC20("MyERC20", "MERC20") {
        // 铸造 100,000,000 代币（考虑 18 位小数）给部署者
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }

    // 重写 decimals 函数（可选），明确指定 18 位小数
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

contract TokenBank {
    using SafeERC20 for IERC20;
    mapping(address => uint256) public balances; // 地址 => 余额 map
    IERC20 public token;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "_tokenAddress invalid");
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "amount must be greater than zero");
        token.safeTransferFrom(msg.sender, address(this), amount);

        balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "amount must be greater than zero");
        require(balances[msg.sender] >= amount, "balance not enough");

        balances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
}
