# Web3 Solidity Libraries

<p align="center">
  <img alt="Solidity" src="https://img.shields.io/badge/Solidity-0.8.24-363636?logo=solidity&logoColor=white" />
  <img alt="Hardhat" src="https://img.shields.io/badge/Hardhat-2.x-FFF0B3?logo=hardhat&logoColor=black" />
  <img alt="License" src="https://img.shields.io/badge/License-GPL--2.0-blue.svg" />
</p>

Reusable, security-oriented Solidity primitives for protocol infrastructure, token systems, governance, access control, and production-grade dApp development.

This repository packages common smart contract building blocks into a modular library collection with a registry pattern for library metadata and versioning.

## Why this repo exists

Smart-contract development repeatedly needs the same foundational components: arithmetic safety, address validation, token transfer guards, role-based access control, and protocol operating patterns. Instead of rebuilding these patterns in every project, this repository centralizes them into composable libraries and deployment-ready examples.

## What is included

- `Web3Math` — safe arithmetic helpers, comparisons, min/max logic, and numeric guards
- `Web3Array` — array membership, summation, deduplication, and index utilities
- `Web3Strings` — string normalization, concatenation, slice operations, and formatting helpers
- `Web3Address` — zero-address checks, contract detection, and validation utilities
- `Web3Time` — timestamp and duration helpers for deadlines, windows, and schedules
- `Web3SafeTransfer` and `Web3SafeERC20` — secure ERC20 transfer and allowance flows
- `Web3AccessControl` and `Web3RoleBasedAccess` — lightweight role/permission systems
- `Web3ReentrancyGuard`, `Web3RateLimiter`, and `Web3InputValidator` — defensive security patterns
- `Web3MultiSig`, `Web3Timelock`, and `Web3QuadraticVoting` — governance-oriented patterns
- `Web3ERC20`, `Web3ERC721`, `Web3ERC1155`, `Web3DynamicNFT` — token and NFT templates
- `Web3Staking` and `Web3Vault` — finance utility contracts
- `Web3LibraryDatabase` — registry contract for versioned library metadata

## Repository structure

```text
.
├── contracts/
│   ├── examples/
│   │   ├── Web3LibraryConsumer.sol
│   │   └── Web3LibraryDatabase.sol
│   ├── finance/
│   │   ├── Web3Staking.sol
│   │   └── Web3Vault.sol
│   ├── governance/
│   │   ├── Web3MultiSig.sol
│   │   ├── Web3QuadraticVoting.sol
│   │   ├── Web3RoleBasedAccess.sol
│   │   └── Web3Timelock.sol
│   ├── interfaces/
│   │   ├── IERC1155.sol
│   │   ├── IERC20.sol
│   │   ├── IERC20Minimal.sol
│   │   └── IERC721.sol
│   ├── libraries/
│   │   ├── Web3AccessControl.sol
│   │   ├── Web3Address.sol
│   │   ├── Web3Array.sol
│   │   ├── Web3Math.sol
│   │   ├── Web3SafeERC20.sol
│   │   ├── Web3SafeTransfer.sol
│   │   ├── Web3Strings.sol
│   │   └── Web3Time.sol
│   ├── nft/
│   │   └── Web3DynamicNFT.sol
│   ├── patterns/
│   │   └── Web3ProxyUpgradeable.sol
│   ├── security/
│   │   ├── Web3ECDSA.sol
│   │   ├── Web3InputValidator.sol
│   │   ├── Web3RateLimiter.sol
│   │   ├── Web3ReentrancyGuard.sol
│   │   └── Web3SignatureVerifier.sol
│   ├── tokens/
│   │   ├── Web3ERC1155.sol
│   │   ├── Web3ERC20.sol
│   │   └── Web3ERC721.sol
│   └── utilities/
│       ├── Web3Allowlist.sol
│       ├── Web3Batch.sol
│       ├── Web3Encoding.sol
│       ├── Web3FixedPoint.sol
│       ├── Web3LinkedList.sol
│       ├── Web3Merkle.sol
│       └── Web3Oracle.sol
├── scripts/
│   └── deploy.js
├── test/
│   ├── production-security.js
│   └── web3-production.js
├── hardhat.config.js
├── package.json
├── LICENSE
├── README.md
├── .gitignore
└── .solhint.json
```

## Quick start

Install dependencies:

```bash
npm install
```

Compile the project:

```bash
npx hardhat compile
```

Run the test suite:

```bash
npx hardhat test
```

Deploy the registry contract locally:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Example usage

```solidity
pragma solidity ^0.8.24;

import "./contracts/libraries/Web3Math.sol";
import "./contracts/libraries/Web3SafeTransfer.sol";

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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

## Registry pattern

The project includes a `Web3LibraryDatabase` contract for tracking library metadata, versioning, and discovery. This is useful for developer tooling, app-specific registries, and multi-module protocol systems.

```solidity
Web3LibraryDatabase db = Web3LibraryDatabase(0x...);

db.registerLibrary(
    "Web3Math",
    "math",
    "1.0.0",
    "Overflow-safe arithmetic helpers for production contracts.",
    0x..., // implementation or library reference
    true
);
```

## Security design principles

This repository is structured around secure-by-default smart-contract patterns:

- strict validation of user and protocol input
- defensive arithmetic and bounds checking
- safe token-transfer semantics and allowance handling
- explicit access control and authorization boundaries
- isolated library responsibilities and composable interfaces
- deployment configuration optimized for deterministic Hardhat builds

## Deployment environment

The project is configured for Hardhat and targets Solidity `0.8.24` with optimizer settings enabled for deployable contract builds.

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  },
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  }
};
```

## License

This project is licensed under the GNU General Public License v2.0. See `LICENSE` for the full licensing text.
