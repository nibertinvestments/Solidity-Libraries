pragma solidity ^0.8.24;

import "../interfaces/IERC20Minimal.sol";
import "../libraries/Web3SafeERC20.sol";

contract Web3Vault {
    using Web3SafeERC20 for IERC20Minimal;

    error Web3Vault__InvalidAmount();
    error Web3Vault__Unauthorized();
    error Web3Vault__TransferFailed();
    error Web3Vault__InvalidToken();

    address public immutable owner;
    mapping(address => mapping(address => uint256)) public tokenBalances;
    mapping(address => bool) public allowedTokens;
    mapping(address => uint256) public ethBalances;

    event TokenDeposited(address indexed token, address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed user, uint256 amount);
    event ETHDeposited(address indexed user, uint256 amount);
    event ETHWithdrawn(address indexed user, uint256 amount);
    event TokenAllowed(address indexed token);
    event TokenDisallowed(address indexed token);

    constructor() {
        owner = msg.sender;
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
        if (token == address(0) || token.code.length == 0) revert Web3Vault__InvalidToken();
        allowedTokens[token] = true;
        emit TokenAllowed(token);
    }

    function disallowToken(address token) external onlyOwner {
        allowedTokens[token] = false;
        emit TokenDisallowed(token);
    }

    function deposit(address token, uint256 amount) external onlyAllowed(token) {
        if (amount == 0) revert Web3Vault__InvalidAmount();
        IERC20Minimal(token).safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[token][msg.sender] += amount;
        emit TokenDeposited(token, msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external onlyAllowed(token) {
        if (amount == 0 || tokenBalances[token][msg.sender] < amount) revert Web3Vault__InvalidAmount();
        tokenBalances[token][msg.sender] -= amount;
        IERC20Minimal(token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(token, msg.sender, amount);
    }

    function depositETH() external payable {
        if (msg.value == 0) revert Web3Vault__InvalidAmount();
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) external {
        if (amount == 0 || ethBalances[msg.sender] < amount) revert Web3Vault__InvalidAmount();
        ethBalances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Web3Vault__TransferFailed();
        emit ETHWithdrawn(msg.sender, amount);
    }

    receive() external payable {
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }
}
