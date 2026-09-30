pragma solidity ^0.8.24;

library Web3SignatureVerifier {
    error Web3SignatureVerifier__InvalidSignature();
    error Web3SignatureVerifier__InvalidLength();

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hash
        ));
    }

    function recover(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) revert Web3SignatureVerifier__InvalidLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) revert Web3SignatureVerifier__InvalidSignature();

        address recovered = ecrecover(messageHash, v, r, s);
        if (recovered == address(0)) revert Web3SignatureVerifier__InvalidSignature();

        return recovered;
    }

    function verify(
        bytes32 messageHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        try Web3SignatureVerifier.recover(messageHash, signature) returns (address recovered) {
            return recovered == expectedSigner;
        } catch {
            return false;
        }
    }
}
