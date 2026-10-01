# Web3 Solidity Libraries

<p align="center">
  <img alt="Solidity" src="https://img.shields.io/badge/Solidity-0.8.24-363636?logo=solidity&logoColor=white" />
  <img alt="Hardhat" src="https://img.shields.io/badge/Hardhat-2.x-FFF0B3?logo=hardhat&logoColor=black" />
  <img alt="License" src="https://img.shields.io/badge/License-GPL--2.0-blue.svg" />
  <img alt="Web3 Libraries" src="https://img.shields.io/badge/Library%20Type-Smart%20Contract-8A2BE2" />
</p>

Production-grade Solidity libraries for Ethereum and Web3 contracts, focused on security, DeFi primitives, token operations, governance, access control, and protocol infrastructure.

This repository is organized as a reusable library collection for robust smart contract development using Hardhat and modern Solidity patterns.

## Search-friendly metadata

This project is designed to be easy to discover through GitHub and package search:

- solidity
- ethereum
- web3
- smart-contracts
- smart-contract-library
- solidity-library
- hardhat
- defi
- token
- erc20
- erc721
- erc1155
- governance
- access-control
- merkle
- oracle
- auction
- vesting
- order-book
- bonding-curve
- security

## Library catalog

### Core utilities
- `Web3Math` — arithmetic, bounds checks, min/max, safe comparisons, and numeric guards
- `Web3Array` — membership checks, deduplication, sorting, slicing, and array utilities
- `Web3DynamicArray` — in-place array mutation, ordered/unordered removal, filtering, and rotation
- `Web3Strings` — string normalization, concatenation, formatting, and comparison helpers
- `Web3Time` — timestamp, duration, deadline, and scheduling helpers
- `Web3Address` — zero-address checks, validation, and address utility patterns
- `Web3BitOperations` — bit flags, bitmask operations, rotation, and population count
- `Web3FixedPoint128` — Q64.64 fixed-point arithmetic for precision-sensitive calculations

### Token, DeFi, and settlement
- `Web3SafeTransfer` — safe ERC20 transfer logic with guards and validation
- `Web3SafeERC20` — allowance-safe token transfer helpers
- `Web3TokenSwap` — constant-product swap estimation, slippage checks, and route logic
- `Web3PriceFeed` — price aggregation, TWAP-style averaging, volatility, and freshness checks
- `Web3BondCurve` — bonding-curve pricing for dynamic mint/burn mechanisms
- `Web3OrderBook` — order lifecycle and matching utilities for DEX-style book management

### Access, governance, and security
- `Web3AccessControl` — permission primitives and access gate patterns
- `Web3PermissionMatrix` — role-based and delegated permission management
- `Web3MerkleProof` — Merkle verification and proof generation support
- `Web3Auction` — English, Dutch, sealed-bid, and Vickrey auction patterns
- `Web3VestingSchedule` — token vesting, cliff periods, release calculations, and revocation

## Repository structure

```text
.
├── contracts/
│   ├── examples/
│   ├── finance/
│   ├── governance/
│   ├── interfaces/
│   ├── libraries/
│   │   ├── Web3AccessControl.sol
│   │   ├── Web3Address.sol
│   │   ├── Web3Array.sol
│   │   ├── Web3Auction.sol
│   │   ├── Web3BitOperations.sol
│   │   ├── Web3BondCurve.sol
│   │   ├── Web3DynamicArray.sol
│   │   ├── Web3FixedPoint128.sol
│   │   ├── Web3Math.sol
│   │   ├── Web3MerkleProof.sol
│   │   ├── Web3OrderBook.sol
│   │   ├── Web3PermissionMatrix.sol
│   │   ├── Web3PriceFeed.sol
│   │   ├── Web3SafeERC20.sol
│   │   ├── Web3SafeTransfer.sol
│   │   ├── Web3Strings.sol
│   │   ├── Web3Time.sol
│   │   ├── Web3TokenSwap.sol
│   │   └── Web3VestingSchedule.sol
│   ├── nft/
│   ├── patterns/
│   ├── security/
│   ├── tokens/
│   └── utilities/
├── scripts/
├── test/
├── hardhat.config.js
├── package.json
├── README.md
├── LICENSE
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

Deploy locally:

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

## Design goals

- secure by default
- production-oriented primitives
- modular composition across protocol layers
- reusable patterns for DeFi, governance, access, and token infrastructure
- compatibility with Hardhat and Web3 tooling

## License

This project is licensed under the GNU General Public License v2.0.

