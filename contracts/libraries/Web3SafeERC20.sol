pragma solidity ^0.8.24;

library Web3SafeERC20 {
    error Web3SafeERC20__CallFailed();

    function safeTransfer(address token, address to, uint256 value) internal returns (bool) {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, value);
        (bool success, bytes memory result) = token.call(data);
        return success && (result.length == 0 || abi.decode(result, (bool)));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal returns (bool) {
        bytes memory data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value);
        (bool success, bytes memory result) = token.call(data);
        return success && (result.length == 0 || abi.decode(result, (bool)));
    }

    function safeApprove(address token, address spender, uint256 value) internal returns (bool) {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", spender, value);
        (bool success, bytes memory result) = token.call(data);
        return success && (result.length == 0 || abi.decode(result, (bool)));
    }

    function balanceOf(address token, address account) internal view returns (uint256) {
        bytes memory data = abi.encodeWithSignature("balanceOf(address)", account);
        (bool success, bytes memory result) = token.staticcall(data);
        if (!success || result.length == 0) return 0;
        return abi.decode(result, (uint256));
    }
}
