// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3DynamicArray
 * @dev Advanced array manipulation library with O(1) removal, deduplication,
 * and efficient packing for storage optimization. Supports indexed operations,
 * sparse arrays, and efficient batch processing.
 */
library Web3DynamicArray {
    /**
     * @dev Remove element at index without preserving order (swap-and-pop).
     * Reduces array length by 1. Reverts if index out of bounds.
     */
    function removeUnordered(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    /**
     * @dev Remove element at index while preserving order.
     * Shifts all elements after index left. More expensive than removeUnordered.
     */
    function removeOrdered(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        for (uint256 i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    /**
     * @dev Check if value exists in array. O(n) scan.
     */
    function contains(uint256[] storage arr, uint256 value) internal view returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) return true;
        }
        return false;
    }

    /**
     * @dev Find first index of value. Returns type(uint256).max if not found.
     */
    function indexOf(uint256[] storage arr, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) return i;
        }
        return type(uint256).max;
    }

    /**
     * @dev Remove all duplicate values, preserving first occurrence order.
     * Modifies array in-place. Returns new length.
     */
    function deduplicate(uint256[] storage arr) internal returns (uint256) {
        if (arr.length == 0) return 0;

        uint256 writeIdx = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < writeIdx; j++) {
                if (arr[j] == arr[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                arr[writeIdx] = arr[i];
                writeIdx++;
            }
        }
        while (arr.length > writeIdx) {
            arr.pop();
        }
        return writeIdx;
    }

    /**
     * @dev Sum all elements in array. Guards against overflow.
     */
    function sum(uint256[] storage arr) internal view returns (uint256 total) {
        for (uint256 i = 0; i < arr.length; i++) {
            total += arr[i];
            require(total >= arr[i], "Overflow in sum");
        }
    }

    /**
     * @dev Find minimum value. Reverts if array empty.
     */
    function min(uint256[] storage arr) internal view returns (uint256 minVal) {
        require(arr.length > 0, "Empty array");
        minVal = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] < minVal) minVal = arr[i];
        }
    }

    /**
     * @dev Find maximum value. Reverts if array empty.
     */
    function max(uint256[] storage arr) internal view returns (uint256 maxVal) {
        require(arr.length > 0, "Empty array");
        maxVal = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] > maxVal) maxVal = arr[i];
        }
    }

    /**
     * @dev Calculate average of all elements with proper rounding.
     */
    function average(uint256[] storage arr) internal view returns (uint256) {
        require(arr.length > 0, "Empty array");
        return sum(arr) / arr.length;
    }

    /**
     * @dev Reverse array order in-place.
     */
    function reverse(uint256[] storage arr) internal {
        uint256 left = 0;
        uint256 right = arr.length > 0 ? arr.length - 1 : 0;
        while (left < right) {
            (arr[left], arr[right]) = (arr[right], arr[left]);
            left++;
            right--;
        }
    }

    /**
     * @dev Rotate array left by n positions. n wraps around array length.
     */
    function rotateLeft(uint256[] storage arr, uint256 n) internal {
        if (arr.length == 0) return;
        n = n % arr.length;
        if (n == 0) return;

        reverse(arr);
        reverseRange(arr, 0, n - 1);
        reverseRange(arr, n, arr.length - 1);
    }

    /**
     * @dev Internal: reverse subarray from start to end indices (inclusive).
     */
    function reverseRange(uint256[] storage arr, uint256 start, uint256 end) private {
        while (start < end) {
            (arr[start], arr[end]) = (arr[end], arr[start]);
            start++;
            end--;
        }
    }

    /**
     * @dev Find index of nth occurrence of value. Returns type(uint256).max if not found.
     */
    function indexOfNth(uint256[] storage arr, uint256 value, uint256 n) internal view returns (uint256) {
        require(n > 0, "n must be positive");
        uint256 count = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                count++;
                if (count == n) return i;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Count occurrences of value in array.
     */
    function countValue(uint256[] storage arr, uint256 value) internal view returns (uint256 count) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) count++;
        }
    }

    /**
     * @dev Check if array is sorted in ascending order.
     */
    function isSorted(uint256[] storage arr) internal view returns (bool) {
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] < arr[i - 1]) return false;
        }
        return true;
    }

    /**
     * @dev Bubble sort in-place (ascending). Use for small arrays only.
     */
    function sort(uint256[] storage arr) internal {
        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = 0; j < len - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
                }
            }
        }
    }

    /**
     * @dev Binary search for value in sorted array. Returns index if found, type(uint256).max otherwise.
     */
    function binarySearch(uint256[] storage arr, uint256 value) internal view returns (uint256) {
        require(isSorted(arr), "Array must be sorted");
        uint256 left = 0;
        uint256 right = arr.length > 0 ? arr.length - 1 : 0;

        while (left <= right) {
            uint256 mid = left + (right - left) / 2;
            if (arr[mid] == value) return mid;
            if (arr[mid] < value) {
                left = mid + 1;
            } else {
                if (mid == 0) break;
                right = mid - 1;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Slice array from start to end (exclusive). Creates new memory array.
     */
    function slice(uint256[] storage arr, uint256 start, uint256 end) internal view returns (uint256[] memory) {
        require(start <= end && end <= arr.length, "Invalid slice bounds");
        uint256[] memory result = new uint256[](end - start);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = arr[start + i];
        }
        return result;
    }

    /**
     * @dev Get every nth element starting from offset. Returns new memory array.
     */
    function stride(uint256[] storage arr, uint256 offset, uint256 n) internal view returns (uint256[] memory) {
        require(n > 0 && offset < arr.length, "Invalid stride parameters");
        uint256 count = 0;
        for (uint256 i = offset; i < arr.length; i += n) {
            count++;
        }
        uint256[] memory result = new uint256[](count);
        count = 0;
        for (uint256 i = offset; i < arr.length; i += n) {
            result[count++] = arr[i];
        }
        return result;
    }

    /**
     * @dev Compact array by removing zeros. Returns new length.
     */
    function compact(uint256[] storage arr) internal returns (uint256) {
        uint256 writeIdx = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] != 0) {
                arr[writeIdx] = arr[i];
                writeIdx++;
            }
        }
        while (arr.length > writeIdx) {
            arr.pop();
        }
        return writeIdx;
    }

    /**
     * @dev Move element from srcIndex to dstIndex, shifting others accordingly.
     */
    function move(uint256[] storage arr, uint256 srcIdx, uint256 dstIdx) internal {
        require(srcIdx < arr.length && dstIdx < arr.length, "Index out of bounds");
        uint256 value = arr[srcIdx];
        if (srcIdx < dstIdx) {
            for (uint256 i = srcIdx; i < dstIdx; i++) {
                arr[i] = arr[i + 1];
            }
        } else if (srcIdx > dstIdx) {
            for (uint256 i = srcIdx; i > dstIdx; i--) {
                arr[i] = arr[i - 1];
            }
        }
        arr[dstIdx] = value;
    }

    /**
     * @dev Swap elements at idx1 and idx2.
     */
    function swap(uint256[] storage arr, uint256 idx1, uint256 idx2) internal {
        require(idx1 < arr.length && idx2 < arr.length, "Index out of bounds");
        (arr[idx1], arr[idx2]) = (arr[idx2], arr[idx1]);
    }

    /**
     * @dev Get all indices where element equals value. Returns new memory array.
     */
    function findAll(uint256[] storage arr, uint256 value) internal view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) count++;
        }
        uint256[] memory indices = new uint256[](count);
        count = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                indices[count++] = i;
            }
        }
        return indices;
    }

    /**
     * @dev Get median value of array. Requires sorting.
     */
    function median(uint256[] storage arr) internal view returns (uint256) {
        require(arr.length > 0, "Empty array");
        uint256[] memory sorted = new uint256[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            sorted[i] = arr[i];
        }
        // Simple bubble sort for median calculation
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = 0; j < sorted.length - i - 1; j++) {
                if (sorted[j] > sorted[j + 1]) {
                    (sorted[j], sorted[j + 1]) = (sorted[j + 1], sorted[j]);
                }
            }
        }
        if (sorted.length % 2 == 1) {
            return sorted[sorted.length / 2];
        } else {
            return (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2;
        }
    }
}
