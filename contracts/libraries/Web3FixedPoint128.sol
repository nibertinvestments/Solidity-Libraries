// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3FixedPoint128
 * @dev 128-bit fixed-point arithmetic library for precise decimal calculations.
 * Uses Q64.64 format: 64 bits for integer part, 64 bits for fractional part.
 * Enables high-precision calculations without floating-point operations.
 */
library Web3FixedPoint128 {
    uint128 constant ONE = 1 << 64; // 2^64 = 1.0 in Q64.64
    uint128 constant HALF = ONE / 2;
    uint128 constant MAX_VALUE = type(uint128).max;

    error OverflowError();
    error DivisionByZeroError();
    error UnderflowError();

    /**
     * @dev Convert unsigned integer to Q64.64 fixed-point.
     * value * 2^64
     */
    function fromUint(uint256 value) internal pure returns (uint128) {
        if (value > type(uint64).max) revert OverflowError();
        return uint128(value) << 64;
    }

    /**
     * @dev Convert Q64.64 fixed-point to unsigned integer (truncates fractional part).
     */
    function toUint(uint128 value) internal pure returns (uint256) {
        return uint256(value >> 64);
    }

    /**
     * @dev Get fractional part of Q64.64 value (0 to 1).
     */
    function frac(uint128 value) internal pure returns (uint128) {
        return value & ((1 << 64) - 1);
    }

    /**
     * @dev Add two Q64.64 values with overflow protection.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 result = a + b;
        if (result < a) revert OverflowError();
        return result;
    }

    /**
     * @dev Subtract two Q64.64 values with underflow protection.
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) revert UnderflowError();
        return a - b;
    }

    /**
     * @dev Multiply two Q64.64 values: (a * b) >> 64.
     * High-precision multiplication using 256-bit intermediate.
     */
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        uint256 result = (uint256(a) * uint256(b)) >> 64;
        if (result > type(uint128).max) revert OverflowError();
        return uint128(result);
    }

    /**
     * @dev Divide two Q64.64 values: (a * 2^64) / b.
     * High-precision division using 256-bit intermediate.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) revert DivisionByZeroError();
        uint256 result = (uint256(a) << 64) / uint256(b);
        if (result > type(uint128).max) revert OverflowError();
        return uint128(result);
    }

    /**
     * @dev Multiply integer by Q64.64 value: (a * b) >> 64.
     */
    function mulInt(uint256 a, uint128 b) internal pure returns (uint256) {
        return (a * uint256(b)) >> 64;
    }

    /**
     * @dev Divide integer by Q64.64 value: (a * 2^64) / b.
     */
    function divInt(uint256 a, uint128 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZeroError();
        return (a << 64) / uint256(b);
    }

    /**
     * @dev Calculate power: value^exponent where exponent is Q64.64.
     * Uses iterative multiplication with exponentiation by squaring.
     */
    function pow(uint128 base, uint128 exponent) internal pure returns (uint128) {
        if (base == 0) return 0;
        if (exponent == ONE) return base;
        if (exponent == 0) return ONE;

        uint128 result = ONE;
        uint128 exp = exponent;
        uint128 b = base;

        while (exp > 0) {
            if ((exp & HALF) != 0) {
                result = mul(result, b);
            }
            b = mul(b, b);
            exp >>= 1;
        }
        return result;
    }

    /**
     * @dev Calculate square root using Newton's method.
     * Iterative refinement for high precision.
     */
    function sqrt(uint128 value) internal pure returns (uint128) {
        if (value == 0) return 0;
        if (value == ONE) return ONE;

        uint128 x = value;
        uint128 y = (x + ONE) / 2;

        while (y < x) {
            x = y;
            y = (x + div(value, x)) / 2;
        }
        return x;
    }

    /**
     * @dev Logarithm base 2 of Q64.64 value.
     * Uses bit manipulation and iteration.
     */
    function log2(uint128 value) internal pure returns (uint128) {
        require(value > 0, "Log of non-positive");
        if (value == ONE) return 0;

        uint128 result = 0;
        if (value >= ONE << 32) {
            value >>= 32;
            result = (32 << 64);
        }
        if (value >= ONE << 16) {
            value >>= 16;
            result = add(result, uint128(16 << 64));
        }
        if (value >= ONE << 8) {
            value >>= 8;
            result = add(result, uint128(8 << 64));
        }
        if (value >= ONE << 4) {
            value >>= 4;
            result = add(result, uint128(4 << 64));
        }
        if (value >= ONE << 2) {
            value >>= 2;
            result = add(result, uint128(2 << 64));
        }
        if (value >= ONE << 1) {
            result = add(result, ONE);
        }
        return result;
    }

    /**
     * @dev Natural logarithm of Q64.64 value.
     * ln(x) = log2(x) * ln(2)
     */
    function ln(uint128 value) internal pure returns (uint128) {
        require(value > 0, "Log of non-positive");
        uint128 ln2 = uint128(0xb17217f7d1cf79abc); // ln(2) in Q64.64
        return mul(log2(value), ln2);
    }

    /**
     * @dev Exponential function: e^value for Q64.64.
     * Uses Taylor series expansion.
     */
    function exp(uint128 value) internal pure returns (uint128) {
        if (value == 0) return ONE;
        if (value > ONE * 20) revert OverflowError(); // e^20 is too large

        uint128 result = ONE;
        uint128 term = ONE;
        uint128 x = value;

        for (uint256 i = 1; i <= 128; i++) {
            term = mul(term, div(x, uint128(i << 64)));
            result = add(result, term);
            if (term == 0) break;
        }
        return result;
    }

    /**
     * @dev Absolute value of Q64.64 number (treating as signed).
     */
    function abs(int128 value) internal pure returns (uint128) {
        return value >= 0 ? uint128(value) : uint128(-value);
    }

    /**
     * @dev Compare two Q64.64 values. Returns -1 if a < b, 0 if equal, 1 if a > b.
     */
    function cmp(uint128 a, uint128 b) internal pure returns (int8) {
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }

    /**
     * @dev Maximum of two Q64.64 values.
     */
    function max(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? a : b;
    }

    /**
     * @dev Minimum of two Q64.64 values.
     */
    function min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    /**
     * @dev Clamp value between min and max.
     */
    function clamp(uint128 value, uint128 minVal, uint128 maxVal) internal pure returns (uint128) {
        if (value < minVal) return minVal;
        if (value > maxVal) return maxVal;
        return value;
    }
}
