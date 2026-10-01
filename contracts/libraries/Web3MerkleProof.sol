// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3MerkleProof
 * @dev Merkle tree proof verification with multi-proof support.
 * Enables efficient verification of tree membership and multiproofs for batch operations.
 */
library Web3MerkleProof {
    error InvalidProof();
    error InvalidProofLength();
    error InvalidFlags();

    /**
     * @dev Verify Merkle proof using keccak256 hashing.
     * Reconstructs root from leaf and proof siblings.
     */
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash == root;
    }

    /**
     * @dev Verify Merkle proof using custom hash function (e.g., poseidon).
     */
    function verifyCustom(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf,
        function(bytes32, bytes32) internal view returns (bytes32) hashFunc
    ) internal view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = hashFunc(computedHash, proof[i]);
        }
        return computedHash == root;
    }

    /**
     * @dev Verify multiproof with flags indicating whether to hash left or right.
     * Efficiently verifies multiple leaves against a single root.
     * flags: bit i = 0 means proof[i] is a sibling, 1 means proof[i] is from leaves
     */
    function verifyMultiProof(
        bytes32[] calldata proof,
        bool[] calldata flags,
        bytes32 root,
        bytes32[] calldata leaves
    ) internal pure returns (bool) {
        if (proof.length + leaves.length - 1 != flags.length) {
            revert InvalidProofLength();
        }

        bytes32[] memory hashes = new bytes32[](proof.length + leaves.length);
        uint256 leafPos = 0;
        uint256 hashPos = leaves.length;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < flags.length; i++) {
            bytes32 a;
            bytes32 b;

            if (flags[i]) {
                a = hashes[leafPos];
                leafPos++;
            } else {
                a = proof[proofPos];
                proofPos++;
            }

            if (flags[i + 1]) {
                b = hashes[leafPos];
                leafPos++;
            } else {
                b = proof[proofPos];
                proofPos++;
            }

            hashes[hashPos] = _hashPair(a, b);
            hashPos++;
        }

        return hashes[hashes.length - 1] == root;
    }

    /**
     * @dev Get the index of a leaf given a proof.
     * Reconstructs the position of the leaf in the tree.
     */
    function getProofPath(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (uint256 path) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            if (computedHash < proof[i]) {
                computedHash = _hashPair(computedHash, proof[i]);
            } else {
                path |= (1 << i);
                computedHash = _hashPair(proof[i], computedHash);
            }
        }
    }

    /**
     * @dev Compute root from leaf and proof.
     */
    function computeRoot(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Verify inclusion of multiple leaves efficiently.
     */
    function verifyLeaves(
        bytes32 root,
        bytes32[] calldata leaves,
        bytes32[][] calldata proofs
    ) internal pure returns (bool) {
        if (leaves.length != proofs.length) revert InvalidProofLength();
        for (uint256 i = 0; i < leaves.length; i++) {
            if (!verify(proofs[i], root, leaves[i])) return false;
        }
        return true;
    }

    /**
     * @dev Check if two leaves are siblings (directly under same parent).
     */
    function areSiblings(
        bytes32 leaf1,
        bytes32 leaf2,
        bytes32[] calldata proof1,
        bytes32[] calldata proof2
    ) internal pure returns (bool) {
        if (proof1.length == 0 || proof2.length == 0) return false;
        
        bytes32 hash1 = leaf1;
        bytes32 hash2 = leaf2;

        for (uint256 i = 0; i < proof1.length - 1; i++) {
            hash1 = _hashPair(hash1, proof1[i]);
            hash2 = _hashPair(hash2, proof2[i]);
        }

        return hash1 == proof2[proof2.length - 1] && hash2 == proof1[proof1.length - 1];
    }

    /**
     * @dev Internal hash pair helper - hashes smaller value first for consistency.
     */
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encode(a, b)) : keccak256(abi.encode(b, a));
    }

    /**
     * @dev Hash leaf with index for enhanced security against second preimage attacks.
     */
    function hashLeaf(bytes memory data, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encode(index, data));
    }

    /**
     * @dev Build tree from leaves array and verify structure.
     */
    function buildTree(bytes32[] memory leaves) internal pure returns (bytes32[] memory tree, bytes32 root) {
        uint256 n = leaves.length;
        require(n > 0, "Empty leaves");

        // Calculate tree size (next power of 2)
        uint256 size = 1;
        while (size < n) size *= 2;
        size = 2 * size - 1;

        tree = new bytes32[](size);
        uint256 treeIndex = size - n;

        // Place leaves
        for (uint256 i = 0; i < n; i++) {
            tree[treeIndex + i] = leaves[i];
        }

        // Build tree bottom-up
        for (int256 i = int256(treeIndex) - 1; i >= 0; i--) {
            uint256 leftIdx = 2 * uint256(i) + 1;
            uint256 rightIdx = 2 * uint256(i) + 2;
            tree[uint256(i)] = _hashPair(tree[leftIdx], tree[rightIdx]);
        }

        return (tree, tree[0]);
    }

    /**
     * @dev Get proof path for leaf at index in pre-built tree.
     */
    function getProof(
        bytes32[] memory tree,
        uint256 leafIndex,
        uint256 leafCount
    ) internal pure returns (bytes32[] memory proof) {
        require(leafIndex < leafCount, "Index out of bounds");

        uint256 size = tree.length;
        uint256 treeIndex = size - leafCount + leafIndex;

        proof = new bytes32[](0);
        uint256 idx = treeIndex;

        while (idx > 0) {
            uint256 sibling = (idx % 2 == 0) ? idx - 1 : idx + 1;
            bytes32[] memory newProof = new bytes32[](proof.length + 1);
            for (uint256 i = 0; i < proof.length; i++) {
                newProof[i] = proof[i];
            }
            newProof[proof.length] = tree[sibling];
            proof = newProof;
            idx = (idx - 1) / 2;
        }

        return proof;
    }
}
