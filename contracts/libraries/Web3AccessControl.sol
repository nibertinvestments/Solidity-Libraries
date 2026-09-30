pragma solidity ^0.8.24;

library Web3AccessControl {
    struct Roles {
        mapping(bytes32 => mapping(address => bool)) roleSet;
    }

    function grantRole(Roles storage roles, bytes32 role, address account) internal {
        roles.roleSet[role][account] = true;
    }

    function revokeRole(Roles storage roles, bytes32 role, address account) internal {
        roles.roleSet[role][account] = false;
    }

    function hasRole(Roles storage roles, bytes32 role, address account) internal view returns (bool) {
        return roles.roleSet[role][account];
    }

    function requireRole(Roles storage roles, bytes32 role, address account) internal view {
        require(roles.roleSet[role][account], "Web3AccessControl: missing role");
    }
}
