# Web3 Solidity Libraries

A production-oriented Solidity library repository for secure, reusable Web3 contracts. The project is organized around modular, battle-tested primitives that can be imported into dApps, vaults, governance systems, token contracts, and protocol infrastructure.

This repository includes standalone libraries, reference implementations, and a deployment-ready registry pattern for managing reusable library metadata in a protocol ecosystem.

## Why this repo exists

The goal is to provide a clean, auditable, and composable foundation for Solidity development without forcing projects to reimplement common utilities. The libraries emphasize:

- arithmetic safety and input validation
- reusable access and authorization patterns
- token safety helpers for ERC20 flows
- modular architecture for upgradeable and governance-heavy systems
- production-oriented deployment and testing workflows

## Repository structure

```text
.
├── contracts/
│   ├── examples/
│   │   └── Web3LibraryConsumer.sol
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
└── .gitignore
```

## Library catalog

### Core libraries

- `Web3Math` — overflow-safe arithmetic, min/max helpers, percentage utilities, and numeric guards
- `Web3Array` — membership checks, summation, deduplication, sorting support, and array utilities
- `Web3Strings` — string normalization, concatenation, substring utilities, and formatting helpers
- `Web3Address` — zero-address checks, contract detection, and address-based validation patterns
- `Web3Time` — timestamp comparisons, deadlines, durations, and scheduling helpers

### Safety and token primitives

- `Web3SafeTransfer` — secure ERC20 transfer wrappers
- `Web3SafeERC20` — safer interaction patterns for token transfer semantics and allowances
- `Web3ReentrancyGuard` — reentrancy protection patterns
- `Web3RateLimiter` — request-throttling and usage control utilities
- `Web3InputValidator` — argument validation helpers for user-controlled inputs

### Access control and governance

- `Web3AccessControl` — lightweight role management and authorization support
- `Web3RoleBasedAccess` — role-based access patterns for protocol control
- `Web3MultiSig` — multisig wallet and approval patterns
- `Web3Timelock` — delayed execution for governance and protocol operations
- `Web3QuadraticVoting` — voting-weight and proposal coordination patterns

### Contracts and system modules

- `Web3LibraryDatabase` — registry contract for storing versioned library metadata
- `Web3ERC20`, `Web3ERC721`, `Web3ERC1155` — standardized token implementations
- `Web3DynamicNFT` — dynamic NFT pattern examples
- `Web3ProxyUpgradeable` — upgradeable proxy patterns
- `Web3Staking`, `Web3Vault` — finance-oriented contract examples

## Quick start

Install dependencies:

```bash
npm install
```

Compile the contracts:

```bash
npx hardhat compile
```

Run the automated tests:

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

## Registry usage

The repository includes a `Web3LibraryDatabase` pattern to track library metadata and versioning. This is useful for protocol registries, developer tooling, or any application that needs to expose a trusted library catalog.

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

## Security notes

These contracts are structured for secure production use and emphasize:

- strict validation of input and address values
- defensive arithmetic patterns
- isolated library responsibilities and single-purpose contracts
- explicit role-based access control patterns
- token-transfer safety checks and allowance handling

## Deployment and environment

The project is configured for Hardhat and supports localhost deployment out of the box. The configuration in `hardhat.config.js` uses Solidity 0.8.24 with optimizer settings enabled for deployment-oriented builds.

## License

This project is licensed under the GNU General Public License v2.0.

See `LICENSE` for full licensing terms.
