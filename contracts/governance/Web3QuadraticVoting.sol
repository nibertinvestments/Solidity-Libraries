pragma solidity ^0.8.24;

library Web3QuadraticVoting {
    error Web3QuadraticVoting__InvalidWeight();
    error Web3QuadraticVoting__AlreadyVoted();

    struct Proposal {
        uint256 id;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
    }

    struct Voter {
        mapping(uint256 => bool) hasVoted;
        mapping(uint256 => uint256) voterWeight;
    }

    function calculateQuadraticWeight(uint256 tokens) internal pure returns (uint256) {
        return sqrt(tokens);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }

    function addVote(
        Proposal storage proposal,
        Voter storage voter,
        uint256 proposalId,
        uint256 weight,
        uint8 support
    ) internal {
        if (weight == 0) revert Web3QuadraticVoting__InvalidWeight();
        if (voter.hasVoted[proposalId]) revert Web3QuadraticVoting__AlreadyVoted();

        uint256 quadraticWeight = calculateQuadraticWeight(weight);
        voter.hasVoted[proposalId] = true;
        voter.voterWeight[proposalId] = quadraticWeight;

        if (support == 0) {
            proposal.againstVotes += quadraticWeight;
        } else if (support == 1) {
            proposal.forVotes += quadraticWeight;
        } else if (support == 2) {
            proposal.abstainVotes += quadraticWeight;
        }
    }
}
