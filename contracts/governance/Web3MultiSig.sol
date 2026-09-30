pragma solidity ^0.8.24;

contract Web3MultiSig {
    error Web3MultiSig__InvalidThreshold();
    error Web3MultiSig__NotOwner();
    error Web3MultiSig__ExecutionFailed();
    error Web3MultiSig__InvalidTransaction();
    error Web3MultiSig__AlreadyConfirmed();
    error Web3MultiSig__NotConfirmed();
    error Web3MultiSig__TxAlreadyExecuted();

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length == 0 || _required == 0 || _required > _owners.length) {
            revert Web3MultiSig__InvalidThreshold();
        }

        for (uint256 i = 0; i < _owners.length; ++i) {
            address owner = _owners[i];
            if (owner == address(0) || isOwner[owner]) revert Web3MultiSig__InvalidThreshold();
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {}

    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public {
        if (!isOwner[msg.sender]) revert Web3MultiSig__NotOwner();

        uint256 txIndex = transactions.length;
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, to, value, data);
    }

    function confirmTransaction(uint256 txIndex) public {
        if (!isOwner[msg.sender]) revert Web3MultiSig__NotOwner();
        if (txIndex >= transactions.length) revert Web3MultiSig__InvalidTransaction();
        if (confirmations[txIndex][msg.sender]) revert Web3MultiSig__AlreadyConfirmed();

        confirmations[txIndex][msg.sender] = true;
        transactions[txIndex].numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex) public {
        if (!isOwner[msg.sender]) revert Web3MultiSig__NotOwner();
        if (txIndex >= transactions.length) revert Web3MultiSig__InvalidTransaction();

        Transaction storage transaction = transactions[txIndex];
        if (transaction.executed) revert Web3MultiSig__TxAlreadyExecuted();
        if (transaction.numConfirmations < required) revert Web3MultiSig__NotConfirmed();

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) revert Web3MultiSig__ExecutionFailed();

        emit ExecuteTransaction(msg.sender, txIndex);
    }

    function revokeConfirmation(uint256 txIndex) public {
        if (!isOwner[msg.sender]) revert Web3MultiSig__NotOwner();
        if (txIndex >= transactions.length) revert Web3MultiSig__InvalidTransaction();
        if (!confirmations[txIndex][msg.sender]) revert Web3MultiSig__NotConfirmed();

        confirmations[txIndex][msg.sender] = false;
        transactions[txIndex].numConfirmations -= 1;

        emit RevokeConfirmation(msg.sender, txIndex);
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 txIndex) public view returns (
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 numConfirmations
    ) {
        Transaction storage transaction = transactions[txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getOwnersCount() public view returns (uint256) {
        return owners.length;
    }
}
