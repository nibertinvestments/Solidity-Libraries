pragma solidity ^0.8.24;

library Web3RateLimiter {
    error Web3RateLimiter__RateLimitExceeded();

    struct RateLimitConfig {
        uint256 maxRequests;
        uint256 window;
        mapping(address => uint256) requestCount;
        mapping(address => uint256) windowStart;
    }

    function checkLimit(RateLimitConfig storage config, address user) internal {
        uint256 currentTime = block.timestamp;

        if (config.windowStart[user] == 0 || currentTime > config.windowStart[user] + config.window) {
            config.windowStart[user] = currentTime;
            config.requestCount[user] = 1;
        } else {
            config.requestCount[user]++;
            if (config.requestCount[user] > config.maxRequests) {
                revert Web3RateLimiter__RateLimitExceeded();
            }
        }
    }

    function setLimit(RateLimitConfig storage config, uint256 maxRequests, uint256 window) internal {
        config.maxRequests = maxRequests;
        config.window = window;
    }

    function getRequestCount(RateLimitConfig storage config, address user) internal view returns (uint256) {
        if (config.windowStart[user] == 0 || block.timestamp > config.windowStart[user] + config.window) {
            return 0;
        }
        return config.requestCount[user];
    }
}
