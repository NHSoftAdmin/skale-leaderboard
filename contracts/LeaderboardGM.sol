// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LeaderboardGM is AccessControl {
    uint256 public constant MAX_LEADERBOARD_SIZE = 1000;
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    struct Player {
        uint256 score;
        address wallet;
        uint64 timestamp;
    }

    Player[] public leaderboard;

    event SubmitScore(address indexed user, uint256 highScore);
    event SubmitScoreAndAdd(address indexed user, uint256 score);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function submitScore(uint256 score) external onlyRole(WHITELIST_ROLE) {        
        require(score > 0, "Score must be positive");
        address user = msg.sender;
        uint64 currentTimestamp = uint64(block.timestamp);
        bool updated = false;

        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].wallet == user) {
                if (score > leaderboard[i].score) {
                    leaderboard[i].score = score;
                    leaderboard[i].timestamp = currentTimestamp;                    
                }
                emit SubmitScore(user, score);
                updated = true;
                break;
            }
        }

        if (!updated) {
            if (leaderboard.length < MAX_LEADERBOARD_SIZE) {
                leaderboard.push(Player(score, user, currentTimestamp));
            } else {
                uint256 minIndex = 0;
                for (uint256 i = 1; i < leaderboard.length; i++) {
                    if (leaderboard[i].score < leaderboard[minIndex].score) {
                        minIndex = i;
                    }
                }

                if (score > leaderboard[minIndex].score) {
                    leaderboard[minIndex] = Player(score, user, currentTimestamp);
                }
            }

            emit SubmitScoreAndAdd(user, score);
        }

        // 🔥 Auto-revoke WHITELIST_ROLE
        _revokeRole(WHITELIST_ROLE, user);
    }

    function getLeaderboard() external view returns (Player[] memory) {
        return leaderboard;
    }
} 
