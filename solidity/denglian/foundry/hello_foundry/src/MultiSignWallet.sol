// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// 多签钱包合约
contract MultiSignWallet {
    // 定义事件
    // 事件: 充值
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    // 事件: 提交交易
    event SubmitTransaction(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed to,
        uint256 value,
        bytes data
    );
    // 事件: 确认交易
    event ConfirmTransaction(uint256 indexed txIndex, address indexed owner);
    // 事件: 撤销确认
    event RevokeConfirmation(uint256 indexed txIndex, address indexed owner);
    // 事件: 执行交易
    event ExecuteTransaction(
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    // 定义状态变量
    // 多签持有人地址列表
    address[] public owners;
    // 记录地址是否为多签持有人
    mapping(address => bool) public isOwner;
    // 执行交易所需的最小确认数
    uint256 public numConfirmationsRequired;
    // 交易结构体，记录交易的详细信息
    struct Transaction {
        address to; // 目标地址
        uint256 value; // 转账金额
        bytes data; // 调用数据
        bool executed; // 是否已执行
        uint256 numConfirmations; // 已获得的确认数
    }
    // 记录交易的确认状态，mapping: 交易索引 => 持有人地址 => 是否确认
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    // 所有交易列表
    Transaction[] public transactions;

    // 修饰器
    // 限制只有多签持有人可以调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    // 验证交易是否存在
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
    // 验证交易是否未被执行
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    // 验证交易是否未被当前调用者确认
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // @notice 构造函数，初始化多签持有人列表和所需确认数
    // @param _owners 多签持有人地址列表
    // @param _numConfirmationsRequired 所需确认数
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // 接收ETH的回调函数
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // 提交新的交易提案
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(txIndex, msg.sender, _to, _value, _data);
    }

    // 确认交易提案
    function confirmTransaction(
        uint256 _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(_txIndex, msg.sender);
    }

    // 撤销对交易提案的确认
    function revokeConfirmation(
        uint256 _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(_txIndex, msg.sender);
    }

    // 执行已获得足够确认数的交易提案
    function executeTransaction(
        uint256 _txIndex
    ) public txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "insufficient confirmations"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(
            _txIndex,
            transaction.to,
            transaction.value,
            transaction.data
        );
    }

    // 获取已提案的交易记录总数
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    // 获取所有多签持有人地址
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // 获取交易详情
    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
