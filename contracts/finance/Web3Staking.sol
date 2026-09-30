pragma solidity ^0.8.24;

contract Web3Staking {
    error Web3Staking__InvalidAmount();
    error Web3Staking__InsufficientStake();
    error Web3Staking__Unauthorized();

    interface IERC20 {
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function transfer(address to, uint256 amount) external returns (bool);
    }

    IERC20 public stakingToken;
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

    constructor(address _stakingToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3Staking__Unauthorized();
        _;
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert Web3Staking__InvalidAmount();

        _updateRewards(msg.sender);

        if (!stakingToken.transferFrom(msg.sender, address(this), amount)) revert Web3Staking__InvalidAmount();

        unchecked {
            stakes[msg.sender].amount += amount;
            totalStaked += amount;
        }

        stakes[msg.sender].timestamp = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) revert Web3Staking__InvalidAmount();
        if (stakes[msg.sender].amount < amount) revert Web3Staking__InsufficientStake();

        _updateRewards(msg.sender);

        if (!stakingToken.transfer(msg.sender, amount)) revert Web3Staking__InvalidAmount();

        unchecked {
            stakes[msg.sender].amount -= amount;
            totalStaked -= amount;
        }

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);

        uint256 rewards = stakes[msg.sender].rewards;
        if (rewards == 0) revert Web3Staking__InvalidAmount();

        stakes[msg.sender].rewards = 0;
        if (!stakingToken.transfer(msg.sender, rewards)) revert Web3Staking__InvalidAmount();

        emit RewardClaimed(msg.sender, rewards);
    }

    function _updateRewards(address user) private {
        uint256 stakedAmount = stakes[user].amount;
        if (stakedAmount == 0) return;

        uint256 timeElapsed = block.timestamp - stakes[user].timestamp;
        uint256 newRewards = (stakedAmount * rewardRate * timeElapsed) / (365 days * PRECISION);

        unchecked {
            stakes[user].rewards += newRewards;
        }
        stakes[user].timestamp = block.timestamp;
    }

    function getClaimableRewards(address user) external view returns (uint256) {
        uint256 stakedAmount = stakes[user].amount;
        if (stakedAmount == 0) return stakes[user].rewards;

        uint256 timeElapsed = block.timestamp - stakes[user].timestamp;
        uint256 newRewards = (stakedAmount * rewardRate * timeElapsed) / (365 days * PRECISION);

        return stakes[user].rewards + newRewards;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
    }
}
