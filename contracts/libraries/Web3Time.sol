pragma solidity ^0.8.24;

library Web3Time {
    uint256 internal constant SECONDS_PER_MINUTE = 60;
    uint256 internal constant SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE;
    uint256 internal constant SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR;

    function nowPlus(uint256 seconds) internal view returns (uint256) {
        return block.timestamp + seconds;
    }

    function isExpired(uint256 timestamp) internal view returns (bool) {
        return block.timestamp >= timestamp;
    }

    function isWithin(uint256 start, uint256 end, uint256 checkpoint) internal pure returns (bool) {
        return checkpoint >= start && checkpoint <= end;
    }

    function daysFromNow(uint256 days) internal view returns (uint256) {
        return block.timestamp + (days * SECONDS_PER_DAY);
    }
}
