pragma solidity ^0.8.24;

library Web3Encoding {
    error Web3Encoding__InvalidEncoding();

    function encodeAddress(address account) internal pure returns (bytes memory) { return abi.encode(account); }

    function decodeAddress(bytes memory encoded) internal pure returns (address) {
        if (encoded.length != 32) revert Web3Encoding__InvalidEncoding();
        return abi.decode(encoded, (address));
    }

    function encodeMultiple(bytes[] memory data) internal pure returns (bytes memory) { return abi.encode(data); }
    function decodeUint256Array(bytes memory encoded) internal pure returns (uint256[] memory) { return abi.decode(encoded, (uint256[])); }
    function decodeAddressArray(bytes memory encoded) internal pure returns (address[] memory) { return abi.decode(encoded, (address[])); }

    function toHexString(uint256 value) internal pure returns (string memory) {
        bytes16 symbols = "0123456789abcdef";
        bytes memory buffer = new bytes(66);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < 32; ++i) {
            buffer[2 + i * 2] = symbols[(value >> (8 * (31 - i) + 4)) & 0x0f];
            buffer[3 + i * 2] = symbols[(value >> (8 * (31 - i))) & 0x0f];
        }
        return string(buffer);
    }
}
