// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LeaderboardGM is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    uint256 public constant MAX_LEADERBOARD_SIZE = 1000;

    struct Player {
        address wallet;
        uint256 score;
    }

    Player[] public leaderboard;

    mapping(address => uint256) public userScores;

    event ScoreSubmitted(address indexed user, uint256 score);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function addToWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        grantRole(WHITELIST_ROLE, user);
    }

    function removeFromWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        revokeRole(WHITELIST_ROLE, user);
    }

    function submitScore(uint256 score) external onlyRole(WHITELIST_ROLE) {
        require(score > 0, "Score must be positive");

        // Update user score if higher than previous
        if (score > userScores[msg.sender]) {
            userScores[msg.sender] = score;
            _updateLeaderboard(msg.sender, score);
            emit ScoreSubmitted(msg.sender, score);
        }
    }

    function _updateLeaderboard(address user, uint256 score) internal {
        bool updated = false;

        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].wallet == user) {
                leaderboard[i].score = score;
                updated = true;
                break;
            }
        }

        if (!updated) {
            if (leaderboard.length < MAX_LEADERBOARD_SIZE) {
                leaderboard.push(Player(user, score));
            } else {
                // Find the lowest score
                uint256 minIndex = 0;
                for (uint256 i = 1; i < leaderboard.length; i++) {
                    if (leaderboard[i].score < leaderboard[minIndex].score) {
                        minIndex = i;
                    }
                }

                if (score > leaderboard[minIndex].score) {
                    leaderboard[minIndex] = Player(user, score);
                }
            }
        }
    }

    function getLeaderboard() external view returns (Player[] memory) {
        return leaderboard;
    }
}
