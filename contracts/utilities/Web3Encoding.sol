pragma solidity ^0.8.24;

library Web3Encoding {
    error Web3Encoding__InvalidEncoding();

    function encodeAddress(address addr) internal pure returns (bytes memory) {
        return abi.encode(addr);
    }

    function decodeAddress(bytes memory encoded) internal pure returns (address) {
        if (encoded.length < 32) revert Web3Encoding__InvalidEncoding();
        return abi.decode(encoded, (address));
    }

    function encodeMultiple(bytes[] memory data) internal pure returns (bytes memory) {
        return abi.encode(data);
    }

    function decodeUint256Array(bytes memory encoded) internal pure returns (uint256[] memory) {
        return abi.decode(encoded, (uint256[]));
    }

    function decodeAddressArray(bytes memory encoded) internal pure returns (address[] memory) {
        return abi.decode(encoded, (address[]));
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 0; i < 32; ++i) {
            uint8 nibble = uint8((value >> (4 * (31 - i))) & 0x0f);
            buffer[i * 2] = bytes1(nibble < 10 ? 48 + nibble : 87 + nibble);
            buffer[i * 2 + 1] = bytes1((nibble >> 4) < 10 ? 48 + (nibble >> 4) : 87 + (nibble >> 4));
        }
        return string(buffer);
    }
}
