// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3BondCurve
 * @dev Bonding curve library for continuous token supply/demand curves.
 * Supports linear, exponential, and polynomial curves for fair price discovery.
 */
library Web3BondCurve {
    enum CurveType { LINEAR, QUADRATIC, EXPONENTIAL, LOGARITHMIC, POLYNOMIAL }

    struct CurveParams {
        CurveType curveType;
        uint256 scale; // Scaling factor for price
        uint256 exponent; // For polynomial/exponential
        uint256 collateralBalance;
        uint256 tokenSupply;
        uint256 feePercentage; // In basis points
    }

    error InvalidInput();
    error CurveFailure();
    error InsufficientReserves();

    /**
     * @dev Calculate price for next token via bonding curve.
     * Price = scale * f(supply)
     */
    function getMintPrice(
        CurveParams storage curve,
        uint256 amount
    ) internal view returns (uint256) {
        if (amount == 0) revert InvalidInput();

        uint256 price = 0;
        if (curve.curveType == CurveType.LINEAR) {
            price = _getLinearPrice(curve, curve.tokenSupply, amount);
        } else if (curve.curveType == CurveType.QUADRATIC) {
            price = _getQuadraticPrice(curve, curve.tokenSupply, amount);
        } else if (curve.curveType == CurveType.EXPONENTIAL) {
            price = _getExponentialPrice(curve, curve.tokenSupply, amount);
        } else if (curve.curveType == CurveType.LOGARITHMIC) {
            price = _getLogarithmicPrice(curve, curve.tokenSupply, amount);
        } else if (curve.curveType == CurveType.POLYNOMIAL) {
            price = _getPolynomialPrice(curve, curve.tokenSupply, amount);
        }
        return price;
    }

    /**
     * @dev Calculate collateral returned for burning tokens.
     */
    function getBurnPrice(
        CurveParams storage curve,
        uint256 amount
    ) internal view returns (uint256) {
        if (amount == 0) revert InvalidInput();
        if (amount > curve.tokenSupply) revert InsufficientReserves();

        uint256 supply = curve.tokenSupply - amount;
        uint256 priceAtNewSupply = 0;
        if (curve.curveType == CurveType.LINEAR) {
            priceAtNewSupply = _getLinearPrice(curve, supply, 1);
        } else if (curve.curveType == CurveType.QUADRATIC) {
            priceAtNewSupply = _getQuadraticPrice(curve, supply, 1);
        }
        return priceAtNewSupply;
    }

    /**
     * @dev Get collateral amount for target supply increase.
     * Integrates price function over supply range.
     */
    function getCollateralNeeded(
        CurveParams storage curve,
        uint256 targetTokens
    ) internal view returns (uint256) {
        if (targetTokens <= curve.tokenSupply) return 0;

        uint256 amount = targetTokens - curve.tokenSupply;
        uint256 total = 0;
        for (uint256 i = 0; i < amount; i++) {
            total += getMintPrice(curve, 1);
            curve.tokenSupply++;
        }
        curve.tokenSupply = curve.tokenSupply - amount; // Restore
        return total;
    }

    /**
     * @dev Execute mint: pay collateral, receive tokens.
     */
    function mint(
        CurveParams storage curve,
        uint256 collateralAmount
    ) internal returns (uint256 tokensReceived) {
        require(collateralAmount > 0, "Zero amount");

        // Binary search for token amount we can mint with collateral
        uint256 low = 0;
        uint256 high = collateralAmount / (curve.scale > 0 ? curve.scale : 1);
        
        while (low < high) {
            uint256 mid = low + (high - low + 1) / 2;
            uint256 costOfMint = getMintPrice(curve, mid);
            if (costOfMint <= collateralAmount) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        
        tokensReceived = low;
        require(tokensReceived > 0, "Insufficient collateral");

        curve.collateralBalance += collateralAmount;
        curve.tokenSupply += tokensReceived;
        return tokensReceived;
    }

    /**
     * @dev Execute burn: send tokens, receive collateral.
     */
    function burn(
        CurveParams storage curve,
        uint256 tokenAmount
    ) internal returns (uint256 collateralReturned) {
        require(tokenAmount > 0, "Zero amount");
        require(tokenAmount <= curve.tokenSupply, "Insufficient supply");

        collateralReturned = getBurnPrice(curve, tokenAmount);
        require(collateralReturned <= curve.collateralBalance, "Insufficient reserves");

        curve.collateralBalance -= collateralReturned;
        curve.tokenSupply -= tokenAmount;
        return collateralReturned;
    }

    /**
     * @dev Internal: linear price function (y = mx + b).
     */
    function _getLinearPrice(
        CurveParams storage curve,
        uint256 supply,
        uint256 amount
    ) private view returns (uint256) {
        return curve.scale * (supply + amount / 2);
    }

    /**
     * @dev Internal: quadratic price function (y = ax^2 + bx + c).
     */
    function _getQuadraticPrice(
        CurveParams storage curve,
        uint256 supply,
        uint256 amount
    ) private view returns (uint256) {
        uint256 nextSupply = supply + amount;
        uint256 price = curve.scale * nextSupply * nextSupply / 1e18;
        return price > 0 ? price : 1;
    }

    /**
     * @dev Internal: exponential price function (y = a * b^x).
     */
    function _getExponentialPrice(
        CurveParams storage curve,
        uint256 supply,
        uint256 amount
    ) private view returns (uint256) {
        uint256 nextSupply = supply + amount;
        if (nextSupply == 0) return curve.scale;
        uint256 base = 2; // e^x approximated with base 2
        uint256 exp = (nextSupply * curve.exponent) / 1e18;
        uint256 price = curve.scale * (1 << (exp > 64 ? 64 : exp)) / (1 << 64);
        return price > 0 ? price : 1;
    }

    /**
     * @dev Internal: logarithmic price function (y = a * ln(x)).
     */
    function _getLogarithmicPrice(
        CurveParams storage curve,
        uint256 supply,
        uint256 amount
    ) private view returns (uint256) {
        uint256 nextSupply = supply + amount;
        if (nextSupply <= 1) return curve.scale;
        uint256 logValue = _ln(nextSupply * 1e18) / 1e18;
        return curve.scale * logValue / 100;
    }

    /**
     * @dev Internal: polynomial price function (y = ax^n).
     */
    function _getPolynomialPrice(
        CurveParams storage curve,
        uint256 supply,
        uint256 amount
    ) private view returns (uint256) {
        uint256 nextSupply = supply + amount;
        uint256 price = curve.scale * _pow(nextSupply, curve.exponent) / 1e36;
        return price > 0 ? price : 1;
    }

    /**
     * @dev Internal: compute x^n.
     */
    function _pow(uint256 x, uint256 n) private pure returns (uint256) {
        if (n == 0) return 1;
        if (n == 1) return x;
        uint256 result = 1;
        for (uint256 i = 0; i < n; i++) {
            result = (result * x) / 1e18;
        }
        return result;
    }

    /**
     * @dev Internal: natural logarithm approximation.
     */
    function _ln(uint256 x) private pure returns (uint256) {
        if (x <= 1e18) return 0;
        uint256 result = 0;
        uint256 t = (x - 1e18) * 1e18 / (x + 1e18);
        uint256 t2 = t * t / 1e18;
        uint256 term = t;
        for (uint256 i = 1; i < 20; i++) {
            result += term / i;
            term = term * t2 / 1e18;
        }
        return result * 2;
    }
}
