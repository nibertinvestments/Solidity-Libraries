pragma solidity ^0.8.24;

library Web3Oracle {
    error Web3Oracle__InvalidPrice();
    error Web3Oracle__StalePrice();

    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint8 decimals;
    }

    mapping(bytes32 => PriceData) private _prices;
    address private _oracle;

    function setPriceOracle(address oracle) internal {
        _oracle = oracle;
    }

    function updatePrice(bytes32 assetId, uint256 price, uint8 decimals) internal {
        if (price == 0) revert Web3Oracle__InvalidPrice();
        _prices[assetId] = PriceData({
            price: price,
            timestamp: block.timestamp,
            decimals: decimals
        });
    }

    function getPrice(bytes32 assetId) internal view returns (uint256 price, uint8 decimals) {
        PriceData storage data = _prices[assetId];
        if (data.price == 0) revert Web3Oracle__InvalidPrice();
        return (data.price, data.decimals);
    }

    function getPriceWithAge(bytes32 assetId, uint256 maxAge) internal view returns (uint256 price, uint8 decimals) {
        PriceData storage data = _prices[assetId];
        if (data.price == 0) revert Web3Oracle__InvalidPrice();
        if (block.timestamp - data.timestamp > maxAge) revert Web3Oracle__StalePrice();
        return (data.price, data.decimals);
    }
}
