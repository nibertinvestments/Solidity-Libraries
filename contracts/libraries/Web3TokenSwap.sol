// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3TokenSwap
 * @dev Advanced token swapping library with slippage protection, batching,
 * and multi-hop routing. Provides safe token exchange with price impact mitigation.
 */
library Web3TokenSwap {
    struct SwapRoute {
        address[] path;
        uint256[] amounts;
        uint256 minOut;
    }

    struct SwapPool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 fee; // Fee in basis points (e.g., 3000 = 0.3%)
    }

    error InsufficientOutput();
    error InvalidPath();
    error ZeroAmount();
    error DuplicateToken();
    error PoolNotFound();
    error InvalidFee();

    /**
     * @dev Calculate output amount for given input (constant product formula).
     * Accounts for fee: amountOut = (amountIn * (10000 - fee) * reserveOut) / (reserveIn * 10000 + amountIn * (10000 - fee))
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256) {
        if (amountIn == 0) revert ZeroAmount();
        if (reserveIn == 0 || reserveOut == 0) revert PoolNotFound();
        if (fee >= 10000) revert InvalidFee();

        uint256 amountInWithFee = amountIn * (10000 - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 10000) + amountInWithFee;
        return numerator / denominator;
    }

    /**
     * @dev Calculate input amount required to receive specified output.
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256) {
        if (amountOut == 0) revert ZeroAmount();
        if (amountOut >= reserveOut) revert InsufficientOutput();
        if (fee >= 10000) revert InvalidFee();

        uint256 numerator = reserveIn * amountOut * 10000;
        uint256 denominator = (reserveOut - amountOut) * (10000 - fee);
        return (numerator / denominator) + 1;
    }

    /**
     * @dev Calculate all intermediate amounts for multi-hop swap.
     */
    function getAmountsOut(
        uint256 amountIn,
        SwapPool[] memory pools,
        address[] memory path
    ) internal pure returns (uint256[] memory) {
        require(path.length >= 2, "Invalid path");
        require(pools.length == path.length - 1, "Pool count mismatch");

        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < pools.length; i++) {
            amounts[i + 1] = getAmountOut(
                amounts[i],
                pools[i].reserveA,
                pools[i].reserveB,
                pools[i].fee
            );
        }
        return amounts;
    }

    /**
     * @dev Calculate input amounts needed for multi-hop swap to exact output.
     */
    function getAmountsIn(
        uint256 amountOut,
        SwapPool[] memory pools,
        address[] memory path
    ) internal pure returns (uint256[] memory) {
        require(path.length >= 2, "Invalid path");
        require(pools.length == path.length - 1, "Pool count mismatch");

        uint256[] memory amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (int256 i = int256(pools.length) - 1; i >= 0; i--) {
            amounts[uint256(i)] = getAmountIn(
                amounts[uint256(i) + 1],
                pools[uint256(i)].reserveA,
                pools[uint256(i)].reserveB,
                pools[uint256(i)].fee
            );
        }
        return amounts;
    }

    /**
     * @dev Calculate price impact of swap (how much price moves due to trade size).
     * Returns percentage in basis points (e.g., 500 = 5%).
     */
    function getPriceImpact(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256) {
        require(amountIn > 0, "Zero amount");

        uint256 executionPrice = (amountIn * reserveOut) / reserveIn;
        uint256 spotPrice = reserveOut / reserveIn;
        
        if (executionPrice >= spotPrice) return 0;
        
        return ((spotPrice - executionPrice) * 10000) / spotPrice;
    }

    /**
     * @dev Validate swap path (no duplicate tokens).
     */
    function validatePath(address[] memory path) internal pure returns (bool) {
        if (path.length < 2) return false;
        for (uint256 i = 0; i < path.length; i++) {
            if (path[i] == address(0)) return false;
            for (uint256 j = i + 1; j < path.length; j++) {
                if (path[i] == path[j]) return false;
            }
        }
        return true;
    }

    /**
     * @dev Find optimal pool from multiple options for given token pair.
     */
    function selectBestPool(
        SwapPool[] memory pools,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal pure returns (uint256 poolIdx) {
        require(pools.length > 0, "No pools available");

        uint256 bestOutput = 0;
        poolIdx = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            if (!_poolConnects(pools[i], tokenIn, tokenOut)) continue;

            (uint256 reserveIn, uint256 reserveOut) = _getReserves(pools[i], tokenIn, tokenOut);
            uint256 output = getAmountOut(amountIn, reserveIn, reserveOut, pools[i].fee);

            if (output > bestOutput) {
                bestOutput = output;
                poolIdx = i;
            }
        }
        require(bestOutput > 0, "No valid pool");
    }

    /**
     * @dev Apply slippage protection - ensure output meets minimum threshold.
     */
    function checkSlippage(
        uint256 actualOutput,
        uint256 minOutput,
        uint256 maxSlippageBps
    ) internal pure returns (bool) {
        if (actualOutput < minOutput) return false;
        uint256 allowedSlippage = (actualOutput * maxSlippageBps) / 10000;
        return (actualOutput - minOutput) <= allowedSlippage;
    }

    /**
     * @dev Calculate minimum output with slippage tolerance.
     */
    function calculateMinimumOutput(
        uint256 expectedOutput,
        uint256 slippageToleranceBps
    ) internal pure returns (uint256) {
        require(slippageToleranceBps <= 10000, "Invalid slippage");
        return (expectedOutput * (10000 - slippageToleranceBps)) / 10000;
    }

    /**
     * @dev Calculate output with maximum price impact constraint.
     */
    function getAmountOutWithImpactLimit(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee,
        uint256 maxImpactBps
    ) internal pure returns (uint256) {
        uint256 impact = getPriceImpact(amountIn, reserveIn, reserveOut, fee);
        require(impact <= maxImpactBps, "Price impact too high");
        return getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }

    /**
     * @dev Batch calculate outputs for multiple input amounts (for UI preview).
     */
    function getAmountsOutBatch(
        uint256[] memory amountsIn,
        SwapPool memory pool
    ) internal pure returns (uint256[] memory) {
        uint256[] memory outputs = new uint256[](amountsIn.length);
        for (uint256 i = 0; i < amountsIn.length; i++) {
            outputs[i] = getAmountOut(
                amountsIn[i],
                pool.reserveA,
                pool.reserveB,
                pool.fee
            );
        }
        return outputs;
    }

    /**
     * @dev Check if pool connects two tokens.
     */
    function _poolConnects(
        SwapPool memory pool,
        address tokenIn,
        address tokenOut
    ) private pure returns (bool) {
        return (pool.tokenA == tokenIn && pool.tokenB == tokenOut) ||
               (pool.tokenA == tokenOut && pool.tokenB == tokenIn);
    }

    /**
     * @dev Get reserves in correct order for swap direction.
     */
    function _getReserves(
        SwapPool memory pool,
        address tokenIn,
        address tokenOut
    ) private pure returns (uint256 reserveIn, uint256 reserveOut) {
        if (pool.tokenA == tokenIn) {
            return (pool.reserveA, pool.reserveB);
        } else {
            return (pool.reserveB, pool.reserveA);
        }
    }

    /**
     * @dev Calculate execution price (price per input token in output tokens).
     */
    function getExecutionPrice(
        uint256 amountIn,
        uint256 amountOut
    ) internal pure returns (uint256) {
        require(amountIn > 0, "Zero input");
        return (amountOut * 1e18) / amountIn;
    }

    /**
     * @dev Compare two execution prices.
     */
    function comparePrices(
        uint256 price1,
        uint256 price2
    ) internal pure returns (int8) {
        if (price1 < price2) return -1;
        if (price1 > price2) return 1;
        return 0;
    }
}
