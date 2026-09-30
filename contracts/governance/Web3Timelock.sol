pragma solidity ^0.8.24;

contract Web3Timelock {
    error Web3Timelock__Unauthorized();
    error Web3Timelock__TransactionNotQueued();
    error Web3Timelock__LockPeriodNotPassed();
    error Web3Timelock__ExecutionFailed();

    address public owner;
    uint256 public lockPeriod = 2 days;

    struct QueuedTransaction {
        address target;
        uint256 value;
        bytes data;
        uint256 queuedTime;
        bool executed;
    }

    mapping(bytes32 => QueuedTransaction) public transactions;
    bytes32[] public queuedHashes;

    event TransactionQueued(bytes32 indexed txHash, address indexed target, uint256 value, bytes data);
    event TransactionExecuted(bytes32 indexed txHash);
    event LockPeriodChanged(uint256 newLockPeriod);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Timelock__Unauthorized();
        _;
    }

    function queueTransaction(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bytes32) {
        bytes32 txHash = keccak256(abi.encode(target, value, data, block.timestamp));

        transactions[txHash] = QueuedTransaction({
            target: target,
            value: value,
            data: data,
            queuedTime: block.timestamp,
            executed: false
        });

        queuedHashes.push(txHash);
        emit TransactionQueued(txHash, target, value, data);
        return txHash;
    }

    function executeTransaction(bytes32 txHash) external onlyOwner {
        if (transactions[txHash].queuedTime == 0) revert Web3Timelock__TransactionNotQueued();
        if (transactions[txHash].executed) revert Web3Timelock__TransactionNotQueued();
        if (block.timestamp < transactions[txHash].queuedTime + lockPeriod) revert Web3Timelock__LockPeriodNotPassed();

        QueuedTransaction storage tx = transactions[txHash];
        tx.executed = true;

        (bool success, ) = tx.target.call{value: tx.value}(tx.data);
        if (!success) revert Web3Timelock__ExecutionFailed();

        emit TransactionExecuted(txHash);
    }

    function setLockPeriod(uint256 newLockPeriod) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodChanged(newLockPeriod);
    }

    function getQueuedTransactions() external view returns (bytes32[] memory) {
        return queuedHashes;
    }
}
