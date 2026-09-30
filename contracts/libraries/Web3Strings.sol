pragma solidity ^0.8.24;

library Web3Strings {
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function isEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function toLower(string memory value) internal pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length);

        for (uint256 i = 0; i < input.length; ++i) {
            bytes1 char = input[i];
            if (char >= 0x41 && char <= 0x5A) {
                output[i] = bytes1(uint8(char) + 32);
            } else {
                output[i] = char;
            }
        }

        return string(output);
    }

    function substring(string memory value, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory input = bytes(value);
        require(start <= end && end <= input.length, "Web3Strings: invalid slice range");

        bytes memory output = new bytes(end - start);
        for (uint256 i = start; i < end; ++i) {
            output[i - start] = input[i];
        }
        return string(output);
    }
}
