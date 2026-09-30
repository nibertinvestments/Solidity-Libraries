pragma solidity ^0.8.24;

contract Web3Allowlist {
    error Web3Allowlist__NotAuthorized();
    error Web3Allowlist__AlreadyAllowlisted();
    error Web3Allowlist__NotAllowlisted();

    address public owner;
    mapping(address => bool) public allowlist;

    event AddedToAllowlist(address indexed account);
    event RemovedFromAllowlist(address indexed account);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Allowlist__NotAuthorized();
        _;
    }

    modifier onlyAllowlisted() {
        if (!allowlist[msg.sender]) revert Web3Allowlist__NotAllowlisted();
        _;
    }

    function addToAllowlist(address account) external onlyOwner {
        if (allowlist[account]) revert Web3Allowlist__AlreadyAllowlisted();
        allowlist[account] = true;
        emit AddedToAllowlist(account);
    }

    function removeFromAllowlist(address account) external onlyOwner {
        if (!allowlist[account]) revert Web3Allowlist__NotAllowlisted();
        allowlist[account] = false;
        emit RemovedFromAllowlist(account);
    }

    function batchAddToAllowlist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            if (!allowlist[accounts[i]]) {
                allowlist[accounts[i]] = true;
                emit AddedToAllowlist(accounts[i]);
            }
        }
    }

    function batchRemoveFromAllowlist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            if (allowlist[accounts[i]]) {
                allowlist[accounts[i]] = false;
                emit RemovedFromAllowlist(accounts[i]);
            }
        }
    }

    function isAllowlisted(address account) external view returns (bool) {
        return allowlist[account];
    }
}
