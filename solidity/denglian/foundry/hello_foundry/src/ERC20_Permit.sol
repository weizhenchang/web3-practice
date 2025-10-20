// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入EIP712标准所需的接口和库
interface IERC20Permit {
    // permit函数，允许通过签名授权
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // 查询owner的nonce
    function nonces(address owner) external view returns (uint256);
    // 查询EIP712域分隔符
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// ERC20Permit 合约，支持EIP2612 permit功能
contract ERC20Permit {
    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals; // 小数位数

    uint256 public totalSupply; // 总发行量

    mapping(address => uint256) balances; // 账户余额映射

    mapping(address => mapping(address => uint256)) allowances; // 授权额度映射

    // EIP2612所需的状态变量
    bytes32 private immutable _DOMAIN_SEPARATOR; // 域分隔符
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        ); // permit类型哈希
    mapping(address => uint256) private _nonces; // 每个owner的nonce

    event Transfer(address indexed from, address indexed to, uint256 value); // 转账事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); // 授权事件

    constructor() {
        name = "AndyToken"; // 代币名称
        symbol = "AnToken"; // 代币符号
        decimals = 18; // 小数位数
        totalSupply = 100000000 * 10 ** uint256(decimals); // 发行1亿个代币

        balances[msg.sender] = totalSupply; // 部署者获得全部初始代币

        // 初始化EIP712域分隔符
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // 查询账户余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 转账
    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            balances[msg.sender] >= _value,
            "ERC20: transfer amount exceeds balance"
        ); // 检查余额
        require(_to != address(0), "ERC20: transfer to the zero address"); // 不能转给0地址

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value); // 触发转账事件
        return true;
    }

    // 授权转账
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            balances[_from] >= _value,
            "ERC20: transfer amount exceeds balance"
        ); // 检查_from余额
        require(
            allowances[_from][msg.sender] >= _value,
            "ERC20: transfer amount exceeds allowance"
        ); // 检查授权额度
        require(_to != address(0), "ERC20: transfer to the zero address"); // 不能转给0地址

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value); // 触发转账事件
        return true;
    }

    // 授权
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address"); // 不能授权给0地址

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); // 触发授权事件
        return true;
    }

    // 查询授权额度
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    // EIP2612 permit函数实现，允许通过签名授权
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline"); // 检查过期时间

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner]++, // 使用并自增nonce
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(hash, v, r, s); // 恢复签名者
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        ); // 校验签名

        allowances[owner][spender] = value; // 设置授权额度
        emit Approval(owner, spender, value); // 触发授权事件
    }

    // 获取用户当前的nonce
    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    // 获取EIP712域分隔符
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }
}
