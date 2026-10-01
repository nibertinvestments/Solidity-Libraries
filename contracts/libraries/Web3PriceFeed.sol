// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3PriceFeed
 * @dev Oracle price feed library with time-weighted averaging, staleness detection,
 * and multi-source aggregation. Provides price data resilience and freshness guarantees.
 */
library Web3PriceFeed {
    struct PricePoint {
        uint256 price;
        uint256 timestamp;
        uint256 confidence; // Confidence interval / deviation
    }

    struct PriceFeed {
        PricePoint[] history;
        uint256 maxAge; // Maximum acceptable age in seconds
        uint256 maxDeviation; // Maximum acceptable deviation from median
    }

    error StalePrice();
    error NoValidPrices();
    error PriceTooDeviated();
    error InvalidPriceRange();
    error EmptyHistory();

    /**
     * @dev Get current price if fresh enough.
     */
    function getPrice(PriceFeed storage feed) internal view returns (uint256) {
        if (feed.history.length == 0) revert EmptyHistory();
        
        PricePoint storage latest = feed.history[feed.history.length - 1];
        if (block.timestamp - latest.timestamp > feed.maxAge) {
            revert StalePrice();
        }
        return latest.price;
    }

    /**
     * @dev Get time-weighted average price over specified duration.
     */
    function getTimeWeightedAveragePrice(
        PriceFeed storage feed,
        uint256 timeWindow
    ) internal view returns (uint256 twap) {
        if (feed.history.length == 0) revert EmptyHistory();

        uint256 currentTime = block.timestamp;
        uint256 startTime = currentTime > timeWindow ? currentTime - timeWindow : 0;
        uint256 weightedSum = 0;
        uint256 totalWeight = 0;

        for (int256 i = int256(feed.history.length) - 1; i >= 0; i--) {
            PricePoint storage point = feed.history[uint256(i)];
            if (point.timestamp < startTime) break;

            uint256 nextTime = uint256(i) < feed.history.length - 1
                ? feed.history[uint256(i) + 1].timestamp
                : currentTime;
            
            uint256 duration = nextTime - point.timestamp;
            weightedSum += point.price * duration;
            totalWeight += duration;
        }

        require(totalWeight > 0, "Insufficient history");
        return weightedSum / totalWeight;
    }

    /**
     * @dev Get median price from recent history.
     */
    function getMedianPrice(
        PriceFeed storage feed,
        uint256 windowSize
    ) internal view returns (uint256) {
        if (feed.history.length == 0) revert EmptyHistory();

        uint256 count = windowSize > feed.history.length ? feed.history.length : windowSize;
        uint256[] memory prices = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 idx = feed.history.length - count + i;
            prices[i] = feed.history[idx].price;
        }

        // Bubble sort for median (acceptable for small windows)
        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = 0; j < count - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }

        return count % 2 == 1 ? prices[count / 2] : (prices[count / 2 - 1] + prices[count / 2]) / 2;
    }

    /**
     * @dev Add new price point to feed.
     */
    function addPrice(
        PriceFeed storage feed,
        uint256 price,
        uint256 confidence
    ) internal {
        require(price > 0, "Invalid price");
        feed.history.push(PricePoint({price: price, timestamp: block.timestamp, confidence: confidence}));
    }

    /**
     * @dev Check if price deviation from median is acceptable.
     */
    function validatePrice(
        PriceFeed storage feed,
        uint256 price,
        uint256 maxDeviation
    ) internal view returns (bool) {
        if (feed.history.length == 0) return true;
        
        uint256 median = getMedianPrice(feed, feed.history.length);
        if (price > median) {
            return (price - median) * 1e18 <= median * maxDeviation;
        } else {
            return (median - price) * 1e18 <= median * maxDeviation;
        }
    }

    /**
     * @dev Aggregate prices from multiple sources using median.
     */
    function aggregatePrices(
        uint256[] calldata prices
    ) internal pure returns (uint256) {
        require(prices.length > 0, "No prices");
        
        uint256[] memory sorted = new uint256[](prices.length);
        for (uint256 i = 0; i < prices.length; i++) {
            sorted[i] = prices[i];
        }

        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = 0; j < sorted.length - i - 1; j++) {
                if (sorted[j] > sorted[j + 1]) {
                    (sorted[j], sorted[j + 1]) = (sorted[j + 1], sorted[j]);
                }
            }
        }

        return sorted.length % 2 == 1
            ? sorted[sorted.length / 2]
            : (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2;
    }

    /**
     * @dev Get price volatility (standard deviation approximation).
     */
    function getVolatility(
        PriceFeed storage feed,
        uint256 windowSize
    ) internal view returns (uint256) {
        if (feed.history.length < 2) return 0;

        uint256 count = windowSize > feed.history.length ? feed.history.length : windowSize;
        uint256 sumSquaredDev = 0;
        uint256 sum = 0;

        for (uint256 i = 0; i < count; i++) {
            uint256 idx = feed.history.length - count + i;
            sum += feed.history[idx].price;
        }
        uint256 avg = sum / count;

        for (uint256 i = 0; i < count; i++) {
            uint256 idx = feed.history.length - count + i;
            uint256 price = feed.history[idx].price;
            uint256 dev = price > avg ? price - avg : avg - price;
            sumSquaredDev += dev * dev;
        }

        // Approximate sqrt using bit operations
        return sqrt(sumSquaredDev / count);
    }

    /**
     * @dev Internal square root calculation using Newton's method.
     */
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @dev Get oldest price point in history.
     */
    function getOldest(PriceFeed storage feed) internal view returns (PricePoint memory) {
        require(feed.history.length > 0, "Empty history");
        return feed.history[0];
    }

    /**
     * @dev Prune old prices beyond retention period.
     */
    function pruneOldPrices(
        PriceFeed storage feed,
        uint256 retentionPeriod
    ) internal {
        uint256 cutoffTime = block.timestamp - retentionPeriod;
        uint256 removeCount = 0;

        for (uint256 i = 0; i < feed.history.length; i++) {
            if (feed.history[i].timestamp < cutoffTime) {
                removeCount++;
            } else {
                break;
            }
        }

        for (uint256 i = 0; i < removeCount; i++) {
            for (uint256 j = 0; j < feed.history.length - 1; j++) {
                feed.history[j] = feed.history[j + 1];
            }
            feed.history.pop();
        }
    }

    /**
     * @dev Get number of prices in history.
     */
    function historyLength(PriceFeed storage feed) internal view returns (uint256) {
        return feed.history.length;
    }
}
