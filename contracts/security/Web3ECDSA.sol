pragma solidity ^0.8.24;

library Web3ECDSA {
    error Web3ECDSA__InvalidSignature();
    error Web3ECDSA__InvalidLength();

    bytes32 private constant HALF_ORDER = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    function toEthSignedMessageHash(bytes32 digest) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
    }

    function recover(bytes32 digest, bytes memory signature) internal pure returns (address signer) {
        if (signature.length != 65) revert Web3ECDSA__InvalidLength();

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) v += 27;
        if ((v != 27 && v != 28) || uint256(s) > uint256(HALF_ORDER) || r == bytes32(0)) {
            revert Web3ECDSA__InvalidSignature();
        }

        signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) revert Web3ECDSA__InvalidSignature();
    }

    function recoverEthSigned(bytes32 digest, bytes memory signature) internal pure returns (address) {
        return recover(toEthSignedMessageHash(digest), signature);
    }
}
