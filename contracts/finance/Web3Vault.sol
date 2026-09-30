pragma solidity ^0.8.24;

contract Web3Vault {
    error Web3Vault__InvalidAmount();
    error Web3Vault__Unauthorized();
    error Web3Vault__TransferFailed();

    interface IERC20 {
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function transfer(address to, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }

    address public owner;
    address public vault;
    mapping(address => uint256) public tokenBalances;
    mapping(address => bool) public allowedTokens;

    event TokenDeposited(address indexed token, address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed user, uint256 amount);
    event TokenAllowed(address indexed token);
    event TokenDisallowed(address indexed token);

    constructor(address _vault) {
        owner = msg.sender;
        vault = _vault;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Vault__Unauthorized();
        _;
    }

    modifier onlyAllowed(address token) {
        if (!allowedTokens[token]) revert Web3Vault__Unauthorized();
        _;
    }

    function allowToken(address token) external onlyOwner {
        allowedTokens[token] = true;
        emit TokenAllowed(token);
    }

    function disallowToken(address token) external onlyOwner {
        allowedTokens[token] = false;
        emit TokenDisallowed(token);
    }

    function deposit(address token, uint256 amount) external onlyAllowed(token) {
        if (amount == 0) revert Web3Vault__InvalidAmount();

        IERC20 erc20 = IERC20(token);
        if (!erc20.transferFrom(msg.sender, address(this), amount)) revert Web3Vault__TransferFailed();

        unchecked {
            tokenBalances[token] += amount;
        }
        emit TokenDeposited(token, msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external onlyAllowed(token) {
        if (amount == 0) revert Web3Vault__InvalidAmount();
        if (tokenBalances[token] < amount) revert Web3Vault__InvalidAmount();

        IERC20 erc20 = IERC20(token);
        if (!erc20.transfer(msg.sender, amount)) revert Web3Vault__TransferFailed();

        unchecked {
            tokenBalances[token] -= amount;
        }
        emit TokenWithdrawn(token, msg.sender, amount);
    }

    function getBalance(address token) external view returns (uint256) {
        return tokenBalances[token];
    }

    receive() external payable {
        unchecked {
            tokenBalances[address(0)] += msg.value;
        }
    }
}
