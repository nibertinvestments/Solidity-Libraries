// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3PermissionMatrix
 * @dev Fine-grained permission management with role hierarchies and delegation.
 * Enables hierarchical permissions, time-based restrictions, and admin delegation.
 */
library Web3PermissionMatrix {
    struct Permission {
        bytes32 action;
        address target;
        bool allowed;
        uint256 expiryTime; // 0 = permanent
        uint256 rateLimit; // Max calls per period (0 = unlimited)
        uint256 ratePeriod; // Rate limit period in seconds
    }

    struct Role {
        bytes32 roleId;
        Permission[] permissions;
        uint256 priority;
    }

    struct DelegatedAccess {
        address delegator;
        address delegate;
        bytes32 roleId;
        uint256 expiryTime;
        bool active;
    }

    error PermissionDenied();
    error InvalidPermission();
    error RateLimitExceeded();
    error DelegationExpired();

    /**
     * @dev Grant permission to address for action.
     */
    function grantPermission(
        mapping(address => Permission[]) storage userPermissions,
        address user,
        bytes32 action,
        address target,
        uint256 expiryTime
    ) internal {
        userPermissions[user].push(Permission({
            action: action,
            target: target,
            allowed: true,
            expiryTime: expiryTime,
            rateLimit: 0,
            ratePeriod: 0
        }));
    }

    /**
     * @dev Revoke permission.
     */
    function revokePermission(
        mapping(address => Permission[]) storage userPermissions,
        address user,
        bytes32 action
    ) internal returns (bool) {
        Permission[] storage perms = userPermissions[user];
        for (uint256 i = 0; i < perms.length; i++) {
            if (perms[i].action == action) {
                perms[i].allowed = false;
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if user has permission for action on target.
     */
    function hasPermission(
        mapping(address => Permission[]) storage userPermissions,
        address user,
        bytes32 action,
        address target
    ) internal view returns (bool) {
        Permission[] storage perms = userPermissions[user];
        for (uint256 i = 0; i < perms.length; i++) {
            Permission storage perm = perms[i];
            if (perm.action == action && (perm.target == address(0) || perm.target == target)) {
                if (!perm.allowed) continue;
                if (perm.expiryTime > 0 && block.timestamp > perm.expiryTime) continue;
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Add role with permissions.
     */
    function addRole(
        mapping(bytes32 => Role) storage roles,
        bytes32 roleId,
        uint256 priority
    ) internal {
        roles[roleId].roleId = roleId;
        roles[roleId].priority = priority;
    }

    /**
     * @dev Assign role to user.
     */
    function assignRole(
        mapping(address => bytes32[]) storage userRoles,
        address user,
        bytes32 roleId
    ) internal {
        userRoles[user].push(roleId);
    }

    /**
     * @dev Check if user has role.
     */
    function hasRole(
        mapping(address => bytes32[]) storage userRoles,
        address user,
        bytes32 roleId
    ) internal view returns (bool) {
        bytes32[] storage roles = userRoles[user];
        for (uint256 i = 0; i < roles.length; i++) {
            if (roles[i] == roleId) return true;
        }
        return false;
    }

    /**
     * @dev Delegate role to another address.
     */
    function delegateRole(
        mapping(bytes32 => DelegatedAccess[]) storage delegations,
        address delegate,
        bytes32 roleId,
        uint256 duration
    ) internal {
        uint256 expiryTime = block.timestamp + duration;
        delegations[roleId].push(DelegatedAccess({
            delegator: msg.sender,
            delegate: delegate,
            roleId: roleId,
            expiryTime: expiryTime,
            active: true
        }));
    }

    /**
     * @dev Check if delegation is valid.
     */
    function isDelegationValid(
        bytes32 roleId,
        address delegate,
        DelegatedAccess[] storage delegations
    ) internal view returns (bool) {
        for (uint256 i = 0; i < delegations.length; i++) {
            DelegatedAccess storage d = delegations[i];
            if (d.delegate == delegate && d.roleId == roleId && d.active) {
                if (block.timestamp <= d.expiryTime) return true;
            }
        }
        return false;
    }

    /**
     * @dev Get user's effective roles including delegations.
     */
    function getEffectiveRoles(
        mapping(address => bytes32[]) storage userRoles,
        address user
    ) internal view returns (bytes32[] memory) {
        return userRoles[user];
    }

    /**
     * @dev Add rate limit to permission.
     */
    function setRateLimit(
        mapping(address => Permission[]) storage userPermissions,
        address user,
        bytes32 action,
        uint256 maxCalls,
        uint256 period
    ) internal {
        Permission[] storage perms = userPermissions[user];
        for (uint256 i = 0; i < perms.length; i++) {
            if (perms[i].action == action) {
                perms[i].rateLimit = maxCalls;
                perms[i].ratePeriod = period;
                return;
            }
        }
    }

    /**
     * @dev Check rate limit for action.
     */
    function checkRateLimit(
        mapping(address => uint256[]) storage callTimestamps,
        address user,
        bytes32 action,
        uint256 maxCalls,
        uint256 period
    ) internal view returns (bool) {
        if (maxCalls == 0) return true;
        
        uint256[] storage timestamps = callTimestamps[uint256(uint160(user)) ^ uint256(action)];
        uint256 cutoffTime = block.timestamp - period;
        uint256 recentCalls = 0;

        for (int256 i = int256(timestamps.length) - 1; i >= 0; i--) {
            if (timestamps[uint256(i)] >= cutoffTime) {
                recentCalls++;
            } else {
                break;
            }
        }
        return recentCalls < maxCalls;
    }

    /**
     * @dev Record action call for rate limiting.
     */
    function recordCall(
        mapping(address => uint256[]) storage callTimestamps,
        address user,
        bytes32 action
    ) internal {
        uint256 key = uint256(uint160(user)) ^ uint256(action);
        callTimestamps[key].push(block.timestamp);
    }
}
