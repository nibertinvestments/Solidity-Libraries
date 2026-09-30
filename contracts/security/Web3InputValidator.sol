pragma solidity ^0.8.24;

library Web3InputValidator {
    error Web3InputValidator__ZeroAddress();
    error Web3InputValidator__ZeroAmount();
    error Web3InputValidator__InvalidAddress();
    error Web3InputValidator__InvalidAmount();
    error Web3InputValidator__EmptyArray();
    error Web3InputValidator__InvalidPercentage();

    function requireNonZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert Web3InputValidator__ZeroAddress();
    }

    function requireNonZeroAmount(uint256 amount) internal pure {
        if (amount == 0) revert Web3InputValidator__ZeroAmount();
    }

    function requireValidAddress(address addr) internal pure {
        if (addr == address(0)) revert Web3InputValidator__InvalidAddress();
    }

    function requireValidAmount(uint256 amount) internal pure {
        if (amount == 0) revert Web3InputValidator__InvalidAmount();
    }

    function requireNonEmptyArray(uint256[] calldata arr) internal pure {
        if (arr.length == 0) revert Web3InputValidator__EmptyArray();
    }

    function requireNonEmptyArray(address[] calldata arr) internal pure {
        if (arr.length == 0) revert Web3InputValidator__EmptyArray();
    }

    function requireValidPercentage(uint256 percentage) internal pure {
        if (percentage > 10_000) revert Web3InputValidator__InvalidPercentage();
    }

    function requireAddressesNotEqual(address a, address b) internal pure {
        if (a == b) revert Web3InputValidator__InvalidAddress();
    }

    function requireAmountInRange(uint256 amount, uint256 min, uint256 max) internal pure {
        if (amount < min || amount > max) revert Web3InputValidator__InvalidAmount();
    }
}
