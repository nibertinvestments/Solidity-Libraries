pragma solidity ^0.8.24;

library Web3Merkle {
    error Web3Merkle__InvalidProof();

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; ++i) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }

    function verifyMultiple(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves
    ) internal pure returns (bool) {
        if (leaves.length == 0) return false;

        bytes32 computedHash = keccak256(abi.encodePacked(leaves[0]));
        for (uint256 i = 1; i < leaves.length; ++i) {
            computedHash = keccak256(abi.encodePacked(computedHash, leaves[i]));
        }

        for (uint256 i = 0; i < proof.length; ++i) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }

    function leaf(address account, uint256 value) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, value));
    }
}
