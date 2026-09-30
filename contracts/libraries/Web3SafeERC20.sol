pragma solidity ^0.8.24;

library Web3SafeERC20 {
    error Web3SafeERC20__CallFailed();

    function safeTransfer(IERC20Minimal token, address to, uint256 value) internal {
        _call(token, abi.encodeCall(IERC20Minimal.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20Minimal token, address from, address to, uint256 value) internal {
        _call(token, abi.encodeCall(IERC20Minimal.transferFrom, (from, to, value)));
    }

    function forceApprove(IERC20Minimal token, address spender, uint256 value) internal {
        bytes memory result = _call(token, abi.encodeCall(IERC20Minimal.approve, (spender, value)));
        if (result.length == 0 || abi.decode(result, (bool))) return;

        _call(token, abi.encodeCall(IERC20Minimal.approve, (spender, 0)));
        _call(token, abi.encodeCall(IERC20Minimal.approve, (spender, value)));
    }

    function _call(IERC20Minimal token, bytes memory data) private returns (bytes memory result) {
        (bool success, bytes memory returndata) = address(token).call(data);
        if (!success || (returndata.length != 0 && !abi.decode(returndata, (bool)))) {
            revert Web3SafeERC20__CallFailed();
        }
        return returndata;
    }
}
