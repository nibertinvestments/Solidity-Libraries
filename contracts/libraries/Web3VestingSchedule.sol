// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3VestingSchedule
 * @dev Token vesting library with cliff periods, linear release, and batch cliff support.
 * Manages vest schedules for employee equity, token lockups, and gradual distribution.
 */
library Web3VestingSchedule {
    struct VestSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 vestDuration; // Total vesting period from start
        uint256 lastReleaseTime;
        bool revocable;
        bool revoked;
    }

    error InvalidSchedule();
    error VestingNotStarted();
    error ZeroRelease();
    error AlreadyRevoked();
    error UnauthorizedRevocation();

    /**
     * @dev Create new vesting schedule.
     */
    function createSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestDuration,
        bool revocable
    ) internal pure returns (VestSchedule memory) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(totalAmount > 0, "Zero amount");
        require(cliffDuration <= vestDuration, "Cliff exceeds duration");
        require(vestDuration > 0, "Zero duration");

        return VestSchedule({
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: startTime,
            cliffTime: startTime + cliffDuration,
            vestDuration: vestDuration,
            lastReleaseTime: startTime,
            revocable: revocable,
            revoked: false
        });
    }

    /**
     * @dev Check if cliff period has passed.
     */
    function hasPassed(VestSchedule storage schedule) internal view returns (bool) {
        return block.timestamp >= schedule.cliffTime;
    }

    /**
     * @dev Get amount vested up to current time.
     */
    function getVestedAmount(VestSchedule storage schedule) internal view returns (uint256) {
        if (schedule.revoked) return schedule.releasedAmount;
        if (block.timestamp < schedule.cliffTime) return 0;
        if (block.timestamp >= schedule.startTime + schedule.vestDuration) {
            return schedule.totalAmount;
        }

        uint256 timeVested = block.timestamp - schedule.startTime;
        return (schedule.totalAmount * timeVested) / schedule.vestDuration;
    }

    /**
     * @dev Get amount available for release.
     */
    function getReleasableAmount(VestSchedule storage schedule) internal view returns (uint256) {
        uint256 vested = getVestedAmount(schedule);
        return vested > schedule.releasedAmount ? vested - schedule.releasedAmount : 0;
    }

    /**
     * @dev Release vested tokens.
     */
    function release(VestSchedule storage schedule) internal returns (uint256) {
        if (!hasPassed(schedule)) revert VestingNotStarted();

        uint256 unreleased = getReleasableAmount(schedule);
        if (unreleased == 0) revert ZeroRelease();

        schedule.releasedAmount += unreleased;
        schedule.lastReleaseTime = block.timestamp;
        return unreleased;
    }

    /**
     * @dev Revoke vesting (for revocable schedules).
     */
    function revoke(VestSchedule storage schedule) internal returns (uint256) {
        if (!schedule.revocable) revert UnauthorizedRevocation();
        if (schedule.revoked) revert AlreadyRevoked();

        schedule.revoked = true;
        uint256 remaining = schedule.totalAmount - schedule.releasedAmount;
        return remaining;
    }

    /**
     * @dev Get percentage vested (0-100).
     */
    function getVestingPercentage(VestSchedule storage schedule) internal view returns (uint256) {
        if (schedule.totalAmount == 0) return 0;
        return (getVestedAmount(schedule) * 100) / schedule.totalAmount;
    }

    /**
     * @dev Get remaining vesting duration (in seconds).
     */
    function getRemainingDuration(VestSchedule storage schedule) internal view returns (uint256) {
        uint256 endTime = schedule.startTime + schedule.vestDuration;
        return block.timestamp >= endTime ? 0 : endTime - block.timestamp;
    }

    /**
     * @dev Check if fully vested.
     */
    function isFullyVested(VestSchedule storage schedule) internal view returns (bool) {
        return getVestedAmount(schedule) >= schedule.totalAmount;
    }

    /**
     * @dev Get time until cliff (0 if already passed).
     */
    function getTimeUntilCliff(VestSchedule storage schedule) internal view returns (uint256) {
        if (block.timestamp >= schedule.cliffTime) return 0;
        return schedule.cliffTime - block.timestamp;
    }

    /**
     * @dev Calculate total vested across multiple schedules.
     */
    function getTotalVested(
        VestSchedule[] storage schedules
    ) internal view returns (uint256 total) {
        for (uint256 i = 0; i < schedules.length; i++) {
            total += getVestedAmount(schedules[i]);
        }
    }

    /**
     * @dev Calculate total releasable across multiple schedules.
     */
    function getTotalReleasable(
        VestSchedule[] storage schedules
    ) internal view returns (uint256 total) {
        for (uint256 i = 0; i < schedules.length; i++) {
            total += getReleasableAmount(schedules[i]);
        }
    }
}
