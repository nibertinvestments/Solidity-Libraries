pragma solidity ^0.8.24;

library Web3Batch {
    error Web3Batch__BatchFailed();

    function batchCall(address[] calldata targets, bytes[] calldata data) internal returns (bytes[] memory results) {
        if (targets.length != data.length) revert Web3Batch__BatchFailed();
        results = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call(data[i]);
            if (!success) revert Web3Batch__BatchFailed();
            results[i] = returndata;
        }
    }

    function batchCallValue(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) internal returns (bytes[] memory results) {
        if (targets.length != data.length || data.length != values.length) revert Web3Batch__BatchFailed();
        results = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(data[i]);
            if (!success) revert Web3Batch__BatchFailed();
            results[i] = returndata;
        }
    }
}
