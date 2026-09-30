pragma solidity ^0.8.24;

contract Web3RoleBasedAccess {
    error Web3RoleBasedAccess__Unauthorized();
    error Web3RoleBasedAccess__InvalidRole();

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmin;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _roleAdmin[OPERATOR_ROLE] = ADMIN_ROLE;
        _roleAdmin[MODERATOR_ROLE] = ADMIN_ROLE;
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function grantRole(bytes32 role, address account) public onlyRole(_roleAdmin[role]) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(_roleAdmin[role]) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public {
        if (account != msg.sender) revert Web3RoleBasedAccess__Unauthorized();
        _revokeRole(role, account);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmin[role];
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyRole(ADMIN_ROLE) {
        bytes32 previousAdminRole = _roleAdmin[role];
        _roleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) revert Web3RoleBasedAccess__Unauthorized();
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}
