pragma solidity ^0.8.24;

import "../libraries/Web3Math.sol";
import "../libraries/Web3Array.sol";
import "../libraries/Web3Strings.sol";
import "../libraries/Web3AccessControl.sol";

contract Web3LibraryConsumer {
    using Web3Math for uint256;
    using Web3Array for uint256[];
    using Web3Strings for string;
    using Web3AccessControl for Web3AccessControl.Roles;

    Web3AccessControl.Roles private _roles;

    function compute(uint256 a, uint256 b) external pure returns (uint256 maxValue, uint256 minValue, uint256 avg) {
        maxValue = a.max(b);
        minValue = a.min(b);
        avg = a.average(b);
    }

    function aggregate(uint256[] calldata values) external pure returns (uint256 total) {
        uint256[] memory memoryValues = values;
        return Web3Array.sum(memoryValues);
    }

    function normalize(string calldata value) external pure returns (string memory) {
        return value.toLower();
    }

    function grantRole(bytes32 role, address account) external {
        _roles.grantRole(role, account);
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles.hasRole(role, account);
    }
}
