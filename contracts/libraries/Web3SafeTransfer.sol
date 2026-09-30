pragma solidity ^0.8.24;

interface IERC20Like {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

library Web3SafeTransfer {
    error Web3SafeTransfer__TransferFailed();
    error Web3SafeTransfer__TransferFromFailed();
    error Web3SafeTransfer__ApproveFailed();

    function safeTransfer(IERC20Like token, address to, uint256 amount) internal {
        if (!token.transfer(to, amount)) revert Web3SafeTransfer__TransferFailed();
    }

    function safeTransferFrom(IERC20Like token, address from, address to, uint256 amount) internal {
        if (!token.transferFrom(from, to, amount)) revert Web3SafeTransfer__TransferFromFailed();
    }

    function safeApprove(IERC20Like token, address spender, uint256 amount) internal {
        if (!token.approve(spender, amount)) revert Web3SafeTransfer__ApproveFailed();
    }
}
