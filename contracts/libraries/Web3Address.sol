pragma solidity ^0.8.24;

library Web3Address {
    function isZero(address account) internal pure returns (bool) {
        return account == address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Web3Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Web3Address: transfer failed");
    }
}
