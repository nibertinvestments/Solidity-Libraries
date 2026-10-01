// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3BitOperations
 * @dev Efficient bitwise operations library for bit manipulation, flags, and encoding.
 * Enables compact storage and fast flag checking without complex conditionals.
 */
library Web3BitOperations {
    error BitIndexOutOfRange();
    error InvalidBitMask();

    /**
     * @dev Check if specific bit is set in value.
     * Bit 0 is LSB, bit 255 is MSB.
     */
    function getBit(uint256 value, uint256 bitIndex) internal pure returns (bool) {
        if (bitIndex > 255) revert BitIndexOutOfRange();
        return (value >> bitIndex) & 1 == 1;
    }

    /**
     * @dev Set specific bit to 1.
     */
    function setBit(uint256 value, uint256 bitIndex) internal pure returns (uint256) {
        if (bitIndex > 255) revert BitIndexOutOfRange();
        return value | (1 << bitIndex);
    }

    /**
     * @dev Clear specific bit (set to 0).
     */
    function clearBit(uint256 value, uint256 bitIndex) internal pure returns (uint256) {
        if (bitIndex > 255) revert BitIndexOutOfRange();
        return value & ~(1 << bitIndex);
    }

    /**
     * @dev Toggle specific bit.
     */
    function toggleBit(uint256 value, uint256 bitIndex) internal pure returns (uint256) {
        if (bitIndex > 255) revert BitIndexOutOfRange();
        return value ^ (1 << bitIndex);
    }

    /**
     * @dev Count number of set bits (population count / Hamming weight).
     */
    function popCount(uint256 value) internal pure returns (uint256 count) {
        while (value != 0) {
            count++;
            value &= value - 1; // Remove rightmost set bit
        }
    }

    /**
     * @dev Get position of lowest set bit (LSB).
     * Returns 256 if no bits set.
     */
    function lowestSetBit(uint256 value) internal pure returns (uint256) {
        if (value == 0) return 256;
        uint256 pos = 0;
        while ((value & 1) == 0) {
            value >>= 1;
            pos++;
        }
        return pos;
    }

    /**
     * @dev Get position of highest set bit (MSB).
     * Returns 256 if no bits set.
     */
    function highestSetBit(uint256 value) internal pure returns (uint256) {
        if (value == 0) return 256;
        uint256 pos = 0;
        while (value > 1) {
            value >>= 1;
            pos++;
        }
        return pos;
    }

    /**
     * @dev Rotate left by n positions.
     */
    function rotateLeft(uint256 value, uint256 n) internal pure returns (uint256) {
        n = n % 256;
        return (value << n) | (value >> (256 - n));
    }

    /**
     * @dev Rotate right by n positions.
     */
    function rotateRight(uint256 value, uint256 n) internal pure returns (uint256) {
        n = n % 256;
        return (value >> n) | (value << (256 - n));
    }

    /**
     * @dev Reverse bit order of value.
     */
    function reverseBits(uint256 value) internal pure returns (uint256 result) {
        for (uint256 i = 0; i < 256; i++) {
            if ((value >> i) & 1 == 1) {
                result |= (1 << (255 - i));
            }
        }
    }

    /**
     * @dev Set multiple bits at once using a mask.
     */
    function setBits(uint256 value, uint256 mask) internal pure returns (uint256) {
        return value | mask;
    }

    /**
     * @dev Clear multiple bits using a mask.
     */
    function clearBits(uint256 value, uint256 mask) internal pure returns (uint256) {
        return value & ~mask;
    }

    /**
     * @dev Toggle multiple bits using a mask.
     */
    function toggleBits(uint256 value, uint256 mask) internal pure returns (uint256) {
        return value ^ mask;
    }

    /**
     * @dev Check if any bit in mask is set in value.
     */
    function hasAnyBit(uint256 value, uint256 mask) internal pure returns (bool) {
        return (value & mask) != 0;
    }

    /**
     * @dev Check if all bits in mask are set in value.
     */
    function hasAllBits(uint256 value, uint256 mask) internal pure returns (bool) {
        return (value & mask) == mask;
    }

    /**
     * @dev Check if exactly one bit is set in value (is power of 2).
     */
    function isPowerOfTwo(uint256 value) internal pure returns (bool) {
        return value != 0 && (value & (value - 1)) == 0;
    }

    /**
     * @dev Extract bits from start position (inclusive) to end position (exclusive).
     */
    function extractBits(uint256 value, uint256 start, uint256 end) internal pure returns (uint256) {
        require(start < end && end <= 256, "Invalid bit range");
        uint256 mask = (1 << (end - start)) - 1;
        return (value >> start) & mask;
    }

    /**
     * @dev Insert bits into value at specific position.
     */
    function insertBits(uint256 value, uint256 bits, uint256 position, uint256 length) internal pure returns (uint256) {
        require(position + length <= 256, "Invalid insertion range");
        uint256 mask = (1 << length) - 1;
        bits &= mask; // Ensure bits fit in length
        value &= ~(mask << position); // Clear target bits
        return value | (bits << position); // Insert new bits
    }

    /**
     * @dev Mirror bits within a byte (reverse byte).
     */
    function reverseByte(uint8 value) internal pure returns (uint8) {
        uint8 result = 0;
        for (uint256 i = 0; i < 8; i++) {
            if ((value >> i) & 1 == 1) {
                result |= (1 << (7 - i));
            }
        }
        return result;
    }

    /**
     * @dev Count leading zeros in 256-bit value.
     */
    function leadingZeros(uint256 value) internal pure returns (uint256) {
        if (value == 0) return 256;
        uint256 count = 0;
        for (uint256 i = 255; i >= 0; i--) {
            if ((value >> i) & 1 == 0) count++;
            else break;
        }
        return count;
    }

    /**
     * @dev Count trailing zeros in value.
     */
    function trailingZeros(uint256 value) internal pure returns (uint256) {
        if (value == 0) return 256;
        return lowestSetBit(value);
    }

    /**
     * @dev Find next power of 2 greater than or equal to value.
     */
    function nextPowerOfTwo(uint256 value) internal pure returns (uint256) {
        if (value <= 1) return 1;
        value--;
        value |= value >> 1;
        value |= value >> 2;
        value |= value >> 4;
        value |= value >> 8;
        value |= value >> 16;
        value |= value >> 32;
        value |= value >> 64;
        value |= value >> 128;
        return value + 1;
    }
}
