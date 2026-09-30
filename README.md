# Web3 Solidity Libraries

A production-oriented Solidity library database for public-use Web3 applications. This repository contains reusable library primitives, a registry contract for tracking library metadata, and a deployment-ready Hardhat setup for building and deploying safe, efficient on-chain contracts.

## What is included

- `Web3Math` — overflow-safe arithmetic and common numeric helpers
- `Web3Array` — array containment, sums, deduplication, and index utilities
- `Web3Strings` — string normalization, concatenation, and slicing
- `Web3Address` — zero-address checks, contract checks, and ETH transfers
- `Web3SafeTransfer` — secure ERC20 token transfer wrappers
- `Web3AccessControl` — lightweight role management library
- `Web3Time` — time-based scheduling helpers
- `Web3LibraryDatabase` — registry contract for storing library metadata and versioning

## Contract architecture

The repo is organized for clean reuse:

- `contracts/libraries/` — standalone Web3 library modules
- `contracts/examples/` — integration examples
- `scripts/deploy.js` — deployment script for the registry

## Example usage

```solidity
pragma solidity ^0.8.24;

import "./libraries/Web3Math.sol";
import "./libraries/Web3SafeTransfer.sol";

contract Treasury {
    using Web3Math for uint256;
    using Web3SafeTransfer for IERC20Like;

    function budget(uint256 a, uint256 b) external pure returns (uint256) {
        return a.max(b);
    }

    function pay(IERC20Like token, address recipient, uint256 amount) external {
        token.safeTransfer(recipient, amount);
    }
}
```

## Deployment

```bash
npm install
npx hardhat compile
npx hardhat run scripts/deploy.js --network localhost
```

## Registry usage

The `Web3LibraryDatabase` contract records library metadata and enables a reusable registry for any protocol or application.

```solidity
Web3LibraryDatabase db = Web3LibraryDatabase(0x...);

db.registerLibrary(
    "Web3Math",
    "math",
    "1.0.0",
    "Overflow-safe math helpers for production contracts.",
    0x..., // implementation or library address reference
    true
);
```

## Security standards

- strict checks for zero addresses and invalid input
- safe arithmetic helpers
- role-based access patterns
- no external dependency on untrusted libraries

## License

GPL-2.0
