pragma solidity ^0.8.24;

contract Web3Oracle {
    error Web3Oracle__Unauthorized();
    error Web3Oracle__InvalidPrice();
    error Web3Oracle__StalePrice();
    error Web3Oracle__InvalidAsset();
    error Web3Oracle__NonMonotonicUpdate();

    struct PriceData {
        uint256 price;
        uint256 updatedAt;
        uint8 decimals;
    }

    address public owner;
    mapping(bytes32 => PriceData) private _prices;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PriceUpdated(bytes32 indexed assetId, uint256 price, uint8 decimals, uint256 updatedAt);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Oracle__Unauthorized();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Web3Oracle__InvalidAsset();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function updatePrice(bytes32 assetId, uint256 price, uint8 decimals) external onlyOwner {
        if (assetId == bytes32(0) || price == 0 || decimals > 36) revert Web3Oracle__InvalidPrice();
        PriceData memory previous = _prices[assetId];
        if (previous.updatedAt > 0 && previous.updatedAt >= block.timestamp) revert Web3Oracle__NonMonotonicUpdate();
        _prices[assetId] = PriceData(price, block.timestamp, decimals);
        emit PriceUpdated(assetId, price, decimals, block.timestamp);
    }

    function getPrice(bytes32 assetId) external view returns (uint256 price, uint8 decimals, uint256 updatedAt) {
        PriceData memory data = _prices[assetId];
        if (data.price == 0) revert Web3Oracle__InvalidPrice();
        return (data.price, data.decimals, data.updatedAt);
    }

    function getPriceWithAge(bytes32 assetId, uint256 maxAge) external view returns (uint256 price, uint8 decimals) {
        PriceData memory data = _prices[assetId];
        if (data.price == 0) revert Web3Oracle__InvalidPrice();
        if (block.timestamp - data.updatedAt > maxAge) revert Web3Oracle__StalePrice();
        return (data.price, data.decimals);
    }
}
