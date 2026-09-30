pragma solidity ^0.8.24;

library Web3RateLimiter {
    error Web3RateLimiter__RateLimitExceeded();

    struct RateLimitConfig {
        uint256 maxRequests;
        uint256 window;
        mapping(address => uint256[]) timestamps;
    }

    function checkLimit(RateLimitConfig storage config, address user) internal {
        uint256 currentTime = block.timestamp;
        uint256 windowStart = currentTime - config.window;

        uint256[] storage userTimestamps = config.timestamps[user];
        uint256 validCount = 0;

        for (uint256 i = 0; i < userTimestamps.length; ++i) {
            if (userTimestamps[i] > windowStart) {
                validCount++;
            }
        }

        if (validCount >= config.maxRequests) revert Web3RateLimiter__RateLimitExceeded();

        userTimestamps.push(currentTime);
    }

    function setLimit(RateLimitConfig storage config, uint256 maxRequests, uint256 window) internal {
        config.maxRequests = maxRequests;
        config.window = window;
    }

    function getRequestCount(RateLimitConfig storage config, address user) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 windowStart = currentTime - config.window;
        uint256 count = 0;

        uint256[] storage userTimestamps = config.timestamps[user];
        for (uint256 i = 0; i < userTimestamps.length; ++i) {
            if (userTimestamps[i] > windowStart) {
                count++;
            }
        }

        return count;
    }
}
