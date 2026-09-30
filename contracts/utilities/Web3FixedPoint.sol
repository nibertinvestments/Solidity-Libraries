pragma solidity ^0.8.24;

library Web3FixedPoint {
    error Web3FixedPoint__Overflow();
    error Web3FixedPoint__DivisionByZero();

    uint256 private constant ONE = 10**18;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = (a * b) / ONE;
        if ((a * b) % ONE > 0) {
            result += 1;
        }
        return result;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert Web3FixedPoint__DivisionByZero();
        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert Web3FixedPoint__DivisionByZero();
        uint256 result = (a * ONE) / b;
        if ((a * ONE) % b > 0) {
            result += 1;
        }
        return result;
    }

    function toUint256(uint256 a) internal pure returns (uint256) {
        return a / ONE;
    }

    function fromUint256(uint256 a) internal pure returns (uint256) {
        return a * ONE;
    }
}
