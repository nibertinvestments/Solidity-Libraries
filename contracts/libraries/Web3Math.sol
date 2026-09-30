pragma solidity ^0.8.24;

library Web3Math {
    error Web3Math__Overflow();
    error Web3Math__DivisionByZero();

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function clamp(uint256 value, uint256 minValue, uint256 maxValue) internal pure returns (uint256) {
        if (value < minValue) return minValue;
        if (value > maxValue) return maxValue;
        return value;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b) / 2;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (a > type(uint256).max - b) revert Web3Math__Overflow();
            return a + b;
        }
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) revert Web3Math__Overflow();
        return a - b;
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        if (denominator == 0) revert Web3Math__DivisionByZero();
        return (x * y) / denominator;
    }

    function percentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return mulDiv(amount, basisPoints, 10_000);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
