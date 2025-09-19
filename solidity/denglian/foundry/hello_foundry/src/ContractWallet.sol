// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// @title 多签钱包合约
// @notice 这是一个支持多人签名的钱包合约，可以用于团队资金管理
contract ContractWallet {
    // 记录存款事件，包含发送者地址、存款金额和合约余额
    event Deposit(address indexed sender, uint amount, uint balance);
    // 记录提交交易事件，包含交易索引、提交者地址、目标地址、转账金额和调用数据
    event SubmitTransaction(
        uint indexed txIndex,
        address indexed owner,
        address indexed to,
        uint value,
        bytes data
    );
    // 记录确认交易事件，包含交易索引和确认者地址
    event ConfirmTransaction(uint indexed txIndex, address indexed owner);
    // 记录撤销确认事件，包含交易索引和撤销者地址
    event RevokeConfirmation(uint indexed txIndex, address indexed owner);
    // 记录执行交易事件，包含交易索引、目标地址、转账金额和调用数据
    event ExecuteTransaction(
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    // 多签持有人地址列表
    address[] public owners;
    // 记录地址是否为多签持有人
    mapping(address => bool) public isOwner;
    // 执行交易所需的最小确认数
    uint public numConfirmationsRequired;

    // 交易结构体，记录交易的详细信息
    struct Transaction {
        address to; // 目标地址
        uint value; // 转账金额
        bytes data; // 调用数据
        bool executed; // 是否已执行
        uint numConfirmations; // 已获得的确认数
    }

    // 记录交易的确认状态，mapping: 交易索引 => 持有人地址 => 是否确认
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // 所有交易列表
    Transaction[] public transactions;

    // 限制只有多签持有人可以调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // 验证交易是否存在
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // 验证交易是否未执行
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // 验证交易是否未被当前调用者确认
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // @notice 构造函数，初始化多签持有人列表和所需确认数
    // @param _owners 多签持有人地址列表
    // @param _numConfirmationsRequired 所需确认数
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        // 初始化多签持有人
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // @notice 接收ETH的回调函数
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // @notice 提交新的交易提案
    // @param _to 目标地址
    // @param _value 转账金额
    // @param _data 调用数据
    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

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

    // @notice 确认交易
    // @param _txIndex 交易索引
    function confirmTransaction(
        uint _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(_txIndex, msg.sender);
    }

    // @notice 执行已获得足够确认数的交易
    // @param _txIndex 交易索引
    function executeTransaction(
        uint _txIndex
    ) public txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
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

    // @notice 撤销对交易的确认
    // @param _txIndex 交易索引
    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(_txIndex, msg.sender);
    }

    // @notice 获取所有多签持有人地址
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // @notice 获取交易总数
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    // @notice 获取交易详情
    // @param _txIndex 交易索引
    // @return to 目标地址
    // @return value 转账金额
    // @return data 调用数据
    // @return executed 是否已执行
    // @return numConfirmations 已获得的确认数
    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
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
