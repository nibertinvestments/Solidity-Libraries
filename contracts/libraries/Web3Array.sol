pragma solidity ^0.8.24;

library Web3Array {
    function contains(uint256[] memory values, uint256 target) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; ++i) {
            if (values[i] == target) return true;
        }
        return false;
    }

    function indexOf(uint256[] memory values, uint256 target) internal pure returns (int256) {
        for (uint256 i = 0; i < values.length; ++i) {
            if (values[i] == target) return int256(i);
        }
        return -1;
    }

    function sum(uint256[] memory values) internal pure returns (uint256 total) {
        for (uint256 i = 0; i < values.length; ++i) {
            total += values[i];
        }
    }

    function removeAt(uint256[] storage values, uint256 index) internal {
        require(index < values.length, "Web3Array: index out of range");
        for (uint256 i = index; i < values.length - 1; ++i) {
            values[i] = values[i + 1];
        }
        values.pop();
    }

    function unique(address[] memory values) internal pure returns (address[] memory filtered) {
        uint256 count = 0;
        for (uint256 i = 0; i < values.length; ++i) {
            bool duplicate = false;
            for (uint256 j = 0; j < i; ++j) {
                if (values[j] == values[i]) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) {
                count++;
            }
        }

        filtered = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < values.length; ++i) {
            bool duplicate = false;
            for (uint256 j = 0; j < i; ++j) {
                if (values[j] == values[i]) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) {
                filtered[index++] = values[i];
            }
        }
    }
}
