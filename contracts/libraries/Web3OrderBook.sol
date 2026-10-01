// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3OrderBook
 * @dev Efficient order book library for DEX/AMM matching with order lifecycle.
 * Supports limit orders, market orders, partial fills, and cancel-replace.
 */
library Web3OrderBook {
    enum OrderType { LIMIT, MARKET, STOP, STOP_LIMIT }
    enum OrderSide { BUY, SELL }
    enum OrderStatus { PENDING, FILLED, PARTIALLY_FILLED, CANCELLED, EXPIRED }

    struct Order {
        uint256 orderId;
        address trader;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 minAmountOut; // For limit orders
        uint256 maxAmountIn;  // For exact output orders
        OrderType orderType;
        OrderSide side;
        OrderStatus status;
        uint256 filledAmount;
        uint256 createdAt;
        uint256 expiryTime;
        uint256 nonce;
    }

    struct OrderBook {
        mapping(uint256 => Order) orders;
        uint256 orderCount;
        uint256[] buyOrders;
        uint256[] sellOrders;
    }

    error InvalidOrder();
    error OrderNotFound();
    error OrderExpired();
    error InsufficientLiquidity();
    error UnauthorizedCancellation();

    /**
     * @dev Create new order.
     */
    function createOrder(
        OrderBook storage book,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        OrderType orderType,
        OrderSide side,
        uint256 expiryTime
    ) internal returns (uint256 orderId) {
        require(tokenIn != address(0) && tokenOut != address(0), "Invalid tokens");
        require(amountIn > 0 && amountOut > 0, "Zero amounts");
        require(tokenIn != tokenOut, "Same token");

        orderId = ++book.orderCount;
        Order storage order = book.orders[orderId];
        order.orderId = orderId;
        order.trader = msg.sender;
        order.tokenIn = tokenIn;
        order.tokenOut = tokenOut;
        order.amountIn = amountIn;
        order.amountOut = amountOut;
        order.minAmountOut = amountOut;
        order.orderType = orderType;
        order.side = side;
        order.status = OrderStatus.PENDING;
        order.createdAt = block.timestamp;
        order.expiryTime = expiryTime;
        order.nonce = orderId;

        if (side == OrderSide.BUY) {
            book.buyOrders.push(orderId);
        } else {
            book.sellOrders.push(orderId);
        }
    }

    /**
     * @dev Get order details.
     */
    function getOrder(OrderBook storage book, uint256 orderId) internal view returns (Order storage) {
        require(book.orders[orderId].orderId != 0, "Order not found");
        return book.orders[orderId];
    }

    /**
     * @dev Check if order is active.
     */
    function isActive(Order storage order) internal view returns (bool) {
        if (order.status != OrderStatus.PENDING && order.status != OrderStatus.PARTIALLY_FILLED) {
            return false;
        }
        if (order.expiryTime > 0 && block.timestamp > order.expiryTime) {
            return false;
        }
        return true;
    }

    /**
     * @dev Fill order (partial or complete).
     */
    function fillOrder(
        Order storage order,
        uint256 amount
    ) internal returns (bool) {
        require(isActive(order), "Order not active");
        require(amount > 0, "Zero fill");

        uint256 remaining = order.amountIn - order.filledAmount;
        uint256 fillAmount = amount > remaining ? remaining : amount;

        order.filledAmount += fillAmount;

        if (order.filledAmount >= order.amountIn) {
            order.status = OrderStatus.FILLED;
        } else {
            order.status = OrderStatus.PARTIALLY_FILLED;
        }
        return true;
    }

    /**
     * @dev Get remaining unfilled amount.
     */
    function getRemainingAmount(Order storage order) internal view returns (uint256) {
        return order.amountIn > order.filledAmount ? order.amountIn - order.filledAmount : 0;
    }

    /**
     * @dev Cancel order.
     */
    function cancelOrder(Order storage order) internal returns (bool) {
        require(msg.sender == order.trader, "Unauthorized");
        require(isActive(order), "Cannot cancel");
        order.status = OrderStatus.CANCELLED;
        return true;
    }

    /**
     * @dev Update order (cancel-replace).
     */
    function updateOrder(
        Order storage order,
        uint256 newAmountIn,
        uint256 newAmountOut
    ) internal returns (bool) {
        require(msg.sender == order.trader, "Unauthorized");
        require(order.status == OrderStatus.PENDING, "Cannot update");
        
        order.amountIn = newAmountIn;
        order.amountOut = newAmountOut;
        order.minAmountOut = newAmountOut;
        order.filledAmount = 0;
        return true;
    }

    /**
     * @dev Get best bid price (highest buy order).
     */
    function getBestBid(
        OrderBook storage book
    ) internal view returns (uint256) {
        uint256 bestPrice = 0;
        for (uint256 i = 0; i < book.buyOrders.length; i++) {
            uint256 orderId = book.buyOrders[i];
            Order storage order = book.orders[orderId];
            if (!isActive(order)) continue;
            
            uint256 price = (order.amountOut * 1e18) / order.amountIn;
            if (price > bestPrice) bestPrice = price;
        }
        return bestPrice;
    }

    /**
     * @dev Get best ask price (lowest sell order).
     */
    function getBestAsk(
        OrderBook storage book
    ) internal view returns (uint256) {
        uint256 bestPrice = type(uint256).max;
        for (uint256 i = 0; i < book.sellOrders.length; i++) {
            uint256 orderId = book.sellOrders[i];
            Order storage order = book.orders[orderId];
            if (!isActive(order)) continue;
            
            uint256 price = (order.amountOut * 1e18) / order.amountIn;
            if (price < bestPrice) bestPrice = price;
        }
        return bestPrice == type(uint256).max ? 0 : bestPrice;
    }

    /**
     * @dev Find matching orders for execution.
     */
    function findMatches(
        OrderBook storage book,
        OrderSide side
    ) internal view returns (uint256[] memory) {
        uint256[] memory matchingOrders = new uint256[](100);
        uint256 matchCount = 0;

        uint256[] storage ordersToSearch = side == OrderSide.BUY ? book.sellOrders : book.buyOrders;
        for (uint256 i = 0; i < ordersToSearch.length && matchCount < 100; i++) {
            uint256 orderId = ordersToSearch[i];
            Order storage order = book.orders[orderId];
            if (isActive(order)) {
                matchingOrders[matchCount++] = orderId;
            }
        }

        uint256[] memory results = new uint256[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            results[i] = matchingOrders[i];
        }
        return results;
    }

    /**
     * @dev Get order spread (bid-ask gap).
     */
    function getSpread(OrderBook storage book) internal view returns (uint256) {
        uint256 bid = getBestBid(book);
        uint256 ask = getBestAsk(book);
        if (bid == 0 || ask == 0) return 0;
        return ask > bid ? ask - bid : 0;
    }

    /**
     * @dev Get mid price (average of bid and ask).
     */
    function getMidPrice(OrderBook storage book) internal view returns (uint256) {
        uint256 bid = getBestBid(book);
        uint256 ask = getBestAsk(book);
        if (bid == 0 || ask == 0) return 0;
        return (bid + ask) / 2;
    }
}
