// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

/**
 * @title Web3Auction
 * @dev Sealed-bid and open auction library with Dutch auction support.
 * Handles bidding, price discovery, settlement, and anti-shill mechanisms.
 */
library Web3Auction {
    enum AuctionType { ENGLISH, DUTCH, SEALED_BID, VICKREY }
    enum AuctionState { PENDING, ACTIVE, ENDED, SETTLED }

    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice;
        AuctionType auctionType;
        AuctionState state;
        uint256 totalBids;
        bool settled;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
        bool withdrawn;
    }

    struct DutchParams {
        uint256 startPrice;
        uint256 endPrice;
        uint256 priceDecayPerSecond;
    }

    error AuctionNotActive();
    error BidTooLow();
    error InvalidAuction();
    error AlreadySettled();
    error UnauthorizedWithdrawal();
    error AuctionNotEnded();

    /**
     * @dev Get current Dutch auction price based on elapsed time.
     */
    function getDutchPrice(
        DutchParams memory params,
        uint256 currentTime,
        uint256 startTime
    ) internal pure returns (uint256) {
        uint256 elapsed = currentTime > startTime ? currentTime - startTime : 0;
        uint256 priceDecrement = params.priceDecayPerSecond * elapsed;
        uint256 currentPrice = params.startPrice > priceDecrement
            ? params.startPrice - priceDecrement
            : params.endPrice;
        return currentPrice >= params.endPrice ? currentPrice : params.endPrice;
    }

    /**
     * @dev Check if auction is currently active.
     */
    function isActive(Auction storage auction) internal view returns (bool) {
        return auction.state == AuctionState.ACTIVE &&
               block.timestamp >= auction.startTime &&
               block.timestamp <= auction.endTime;
    }

    /**
     * @dev Check if auction has ended.
     */
    function hasEnded(Auction storage auction) internal view returns (bool) {
        return block.timestamp > auction.endTime || auction.state == AuctionState.ENDED;
    }

    /**
     * @dev Place bid in English auction.
     */
    function placeBid(
        Auction storage auction,
        uint256 bidAmount
    ) internal returns (bool) {
        if (!isActive(auction)) revert AuctionNotActive();
        if (bidAmount <= auction.highestBid) revert BidTooLow();
        if (bidAmount < auction.reservePrice) revert BidTooLow();

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;
        auction.totalBids++;
        return true;
    }

    /**
     * @dev Place sealed bid (hash commitment).
     */
    function placeSealedBid(
        bytes32 bidCommitment,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(msg.sender, bidCommitment, nonce));
    }

    /**
     * @dev Reveal sealed bid (check commitment matches).
     */
    function revealBid(
        bytes32 commitment,
        uint256 bidAmount,
        uint256 nonce
    ) internal pure returns (bool) {
        bytes32 computed = keccak256(abi.encode(msg.sender, bidAmount, nonce));
        return computed == commitment;
    }

    /**
     * @dev Calculate Vickrey auction winner payment (second-highest bid).
     */
    function calculateVickreyPayment(
        uint256[] memory bids
    ) internal pure returns (uint256) {
        if (bids.length < 2) return 0;
        
        uint256 max = bids[0];
        uint256 secondMax = 0;

        for (uint256 i = 1; i < bids.length; i++) {
            if (bids[i] > max) {
                secondMax = max;
                max = bids[i];
            } else if (bids[i] > secondMax) {
                secondMax = bids[i];
            }
        }
        return secondMax;
    }

    /**
     * @dev Get time remaining in auction (in seconds).
     */
    function timeRemaining(Auction storage auction) internal view returns (uint256) {
        if (block.timestamp >= auction.endTime) return 0;
        return auction.endTime - block.timestamp;
    }

    /**
     * @dev Check if auction minimum is met.
     */
    function isReserveMet(Auction storage auction) internal view returns (bool) {
        return auction.highestBid >= auction.reservePrice;
    }

    /**
     * @dev Extend auction end time (for last-minute bids).
     */
    function extendAuction(
        Auction storage auction,
        uint256 additionalTime
    ) internal {
        require(msg.sender == auction.seller, "Unauthorized");
        auction.endTime += additionalTime;
    }

    /**
     * @dev Cancel auction if no valid bids.
     */
    function cancelAuction(Auction storage auction) internal returns (bool) {
        if (msg.sender != auction.seller) revert UnauthorizedWithdrawal();
        if (auction.settled) revert AlreadySettled();
        if (isReserveMet(auction)) return false;
        
        auction.state = AuctionState.ENDED;
        return true;
    }

    /**
     * @dev Settle auction and determine winner.
     */
    function settleAuction(Auction storage auction) internal returns (address winner, uint256 payment) {
        if (!hasEnded(auction)) revert AuctionNotEnded();
        if (auction.settled) revert AlreadySettled();

        auction.state = AuctionState.SETTLED;
        auction.settled = true;

        if (!isReserveMet(auction)) {
            return (address(0), 0);
        }
        return (auction.highestBidder, auction.highestBid);
    }

    /**
     * @dev Check if address was a bidder.
     */
    function wasBidder(
        Auction storage auction,
        address bidder
    ) internal view returns (bool) {
        return bidder == auction.highestBidder || auction.totalBids > 0;
    }
}
