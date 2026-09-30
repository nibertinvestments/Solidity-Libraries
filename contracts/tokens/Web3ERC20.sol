pragma solidity ^0.8.24;

import "../interfaces/IERC20.sol";

contract Web3ERC20 is IERC20 {
    error Web3ERC20__InsufficientBalance();
    error Web3ERC20__InsufficientAllowance();
    error Web3ERC20__InvalidRecipient();
    error Web3ERC20__Overflow();

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = initialSupply * 10 ** uint256(_decimals);
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (to == address(0)) revert Web3ERC20__InvalidRecipient();
        if (_balances[msg.sender] < amount) revert Web3ERC20__InsufficientBalance();

        unchecked {
            _balances[msg.sender] -= amount;
            _balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (to == address(0)) revert Web3ERC20__InvalidRecipient();
        if (_balances[from] < amount) revert Web3ERC20__InsufficientBalance();
        if (_allowances[from][msg.sender] < amount) revert Web3ERC20__InsufficientAllowance();

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] -= amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        if (currentAllowance > type(uint256).max - addedValue) revert Web3ERC20__Overflow();

        _allowances[msg.sender][spender] = currentAllowance + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        if (currentAllowance < subtractedValue) revert Web3ERC20__InsufficientAllowance();

        _allowances[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
}
