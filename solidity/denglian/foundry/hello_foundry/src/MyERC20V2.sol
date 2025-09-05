//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 从 OpenZeppelin GitHub 导入 ERC20 合约
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 定义接收代币回调的接口
interface ITokenReceiver {
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

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

    // 以下为扩展功能

    // 检查地址是否为合约
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // 带有回调功能的转账函数
    function transferFromWithCallback(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            balanceOf(_from) >= _value,
            "ERC20: transfer amount exceeds balance"
        );
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            allowance(_from, msg.sender) >= _value,
            "ERC20: insufficient allowance"
        );

        transferFrom(_from, _to, _value);

        // 如果接收方是合约，调用其 tokenReceived 方法
        if (isContract(_to)) {
            try ITokenReceiver(_to).tokensReceived(_from, _value, "") returns (
                bool
            ) {
                // 回调成功
            } catch (bytes memory reason) {
                // 回调失败，但不回滚交易
                revert(string(reason));
            }
        }

        return true;
    }

    // 带有回调功能的转账函数(附带数据)
    function transferFromWithCallbackAndData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success) {
        require(
            balanceOf(_from) >= _value,
            "ERC20: transfer amount exceeds balance"
        );
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            allowance(_from, msg.sender) >= _value,
            "ERC20: insufficient allowance"
        );

        transferFrom(_from, _to, _value);

        // 如果接收方是合约，调用其 tokenReceived 方法
        if (isContract(_to)) {
            try
                ITokenReceiver(_to).tokensReceived(_from, _value, _data)
            returns (bool) {
                // 回调成功
            } catch (bytes memory reason) {
                // 回调失败
                revert(string(reason));
            }
        }

        return true;
    }
}
