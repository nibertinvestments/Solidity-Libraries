pragma solidity ^0.8.24;

library Web3ReentrancyGuard {
    error Web3ReentrancyGuard__NoReentrancy();

    uint256 private constant UNLOCKED = 1;
    uint256 private constant LOCKED = 2;

    struct ReentrancyState {
        uint256 status;
    }

    function initialize(ReentrancyState storage self) internal {
        if (self.status == 0) {
            self.status = UNLOCKED;
        }
    }

    function nonReentrant(ReentrancyState storage self) internal {
        if (self.status == LOCKED) revert Web3ReentrancyGuard__NoReentrancy();
        self.status = LOCKED;
    }

    function nonReentrantEnd(ReentrancyState storage self) internal {
        self.status = UNLOCKED;
    }
}
