pragma solidity ^0.8.24;

import "../interfaces/IERC20.sol";
import "../libraries/Web3SafeERC20.sol";

contract Web3Staking {
    using Web3SafeERC20 for address;

    error Web3Staking__InvalidAmount();
    error Web3Staking__InsufficientStake();
    error Web3Staking__Unauthorized();
    error Web3Staking__InsufficientFunds();
    error Web3Staking__OverflowProtection();

    IERC20 public immutable stakingToken;
    address public owner;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public totalReservedRewards;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MAX_UINT256_SAFE = type(uint256).max / 2;

    struct StakeRecord {
        uint256 amount;
        uint256 timestamp;
        uint256 rewards;
    }

    mapping(address => StakeRecord) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 previousRate, uint256 newRate);

    constructor(address token, uint256 initialRewardRate) {
        if (token == address(0) || token.code.length == 0) revert Web3Staking__InvalidAmount();
        stakingToken = IERC20(token);
        rewardRate = initialRewardRate;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Staking__Unauthorized();
        _;
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert Web3Staking__InvalidAmount();
        if (totalStaked + amount > MAX_UINT256_SAFE) revert Web3Staking__OverflowProtection();

        _updateRewards(msg.sender);

        if (!address(stakingToken).safeTransferFrom(msg.sender, address(this), amount)) {
            revert Web3Staking__InvalidAmount();
        }

        stakes[msg.sender].amount += amount;
        totalStaked += amount;
        stakes[msg.sender].timestamp = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0 || stakes[msg.sender].amount < amount) revert Web3Staking__InsufficientStake();

        _updateRewards(msg.sender);

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        if (!address(stakingToken).safeTransfer(msg.sender, amount)) {
            revert Web3Staking__InvalidAmount();
        }

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);

        uint256 rewards = stakes[msg.sender].rewards;
        if (rewards == 0) revert Web3Staking__InvalidAmount();
        if (rewards > totalReservedRewards) revert Web3Staking__InsufficientFunds();

        stakes[msg.sender].rewards = 0;
        totalReservedRewards -= rewards;

        if (!address(stakingToken).safeTransfer(msg.sender, rewards)) {
            revert Web3Staking__InvalidAmount();
        }

        emit RewardClaimed(msg.sender, rewards);
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        emit RewardRateUpdated(rewardRate, newRate);
        rewardRate = newRate;
    }

    function fundRewards(uint256 amount) external {
        if (amount == 0) revert Web3Staking__InvalidAmount();
        if (totalReservedRewards + amount > MAX_UINT256_SAFE) revert Web3Staking__OverflowProtection();

        if (!address(stakingToken).safeTransferFrom(msg.sender, address(this), amount)) {
            revert Web3Staking__InvalidAmount();
        }
        totalReservedRewards += amount;
    }

    function getClaimableRewards(address user) external view returns (uint256) {
        StakeRecord memory record = stakes[user];
        if (record.amount == 0) return record.rewards;

        uint256 timeElapsed = block.timestamp - record.timestamp;
        uint256 newRewards = _calculateRewards(record.amount, timeElapsed);
        return record.rewards + newRewards;
    }

    function _updateRewards(address user) private {
        StakeRecord storage record = stakes[user];
        if (record.amount != 0) {
            uint256 timeElapsed = block.timestamp - record.timestamp;
            uint256 newRewards = _calculateRewards(record.amount, timeElapsed);
            record.rewards += newRewards;
            totalReservedRewards += newRewards;
        }
        record.timestamp = block.timestamp;
    }

    function _calculateRewards(uint256 amount, uint256 timeElapsed) private view returns (uint256) {
        return (amount * rewardRate * timeElapsed) / (365 days * PRECISION);
    }
}
