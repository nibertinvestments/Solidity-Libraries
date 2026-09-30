pragma solidity ^0.8.24;

import "../interfaces/IERC20Minimal.sol";
import "../libraries/Web3SafeERC20.sol";

contract Web3Staking {
    using Web3SafeERC20 for IERC20Minimal;

    error Web3Staking__InvalidAmount();
    error Web3Staking__InsufficientStake();
    error Web3Staking__Unauthorized();
    error Web3Staking__InvalidToken();

    IERC20Minimal public immutable stakingToken;
    address public owner;
    uint256 public rewardRate;
    uint256 public constant PRECISION = 1e18;

    struct StakeRecord {
        uint256 amount;
        uint256 timestamp;
        uint256 rewards;
    }

    mapping(address => StakeRecord) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 previousRate, uint256 newRate);

    constructor(address token, uint256 initialRewardRate) {
        if (token == address(0) || token.code.length == 0) revert Web3Staking__InvalidToken();
        stakingToken = IERC20Minimal(token);
        rewardRate = initialRewardRate;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Staking__Unauthorized();
        _;
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert Web3Staking__InvalidAmount();
        _updateRewards(msg.sender);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
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
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);
        uint256 rewards = stakes[msg.sender].rewards;
        if (rewards == 0) revert Web3Staking__InvalidAmount();
        stakes[msg.sender].rewards = 0;
        stakingToken.safeTransfer(msg.sender, rewards);
        emit RewardClaimed(msg.sender, rewards);
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        emit RewardRateUpdated(rewardRate, newRate);
        rewardRate = newRate;
    }

    function getClaimableRewards(address user) external view returns (uint256) {
        StakeRecord memory record = stakes[user];
        if (record.amount == 0) return record.rewards;
        return record.rewards + (record.amount * rewardRate * (block.timestamp - record.timestamp)) / (365 days * PRECISION);
    }

    function _updateRewards(address user) private {
        StakeRecord storage record = stakes[user];
        if (record.amount != 0) {
            record.rewards += (record.amount * rewardRate * (block.timestamp - record.timestamp)) / (365 days * PRECISION);
        }
        record.timestamp = block.timestamp;
    }
}
