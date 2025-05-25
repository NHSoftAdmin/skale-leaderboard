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
        uint64 timestamp;
        string username;
    }

    Player[] public leaderboard;

    mapping(address => string) public usernames;

    mapping(address => uint256) public userScores;

    event SubmitScore(address indexed user, uint256 highScore); // Event emitted when a score is submitted but not added to the leaderboard
    event SubmitScoreAndAdd(address indexed user, uint256 score); // Event emitted when a score is submitted and added to the leaderboard
    event Whitelist(address indexed user); // User wallet whitelisted    

    function setUsername(string calldata _username) external {
        usernames[msg.sender] = _username;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function addToWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        grantRole(WHITELIST_ROLE, user);
        emit Whitelist(msg.sender);
    }

    function removeFromWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        revokeRole(WHITELIST_ROLE, user);
    }

    function submitScore(uint256 score, string memory username) external onlyRole(WHITELIST_ROLE) {
        require(score > 0, "Score must be positive");

        // Update user score if higher than previous
        if (score > userScores[msg.sender]) {
            userScores[msg.sender] = score;
            _updateLeaderboard(msg.sender, score, username);  
            emit SubmitScoreAndAdd(msg.sender, score);      
        } else {
            emit SubmitScore(msg.sender, score);
        }

        
    }

    function _updateLeaderboard(address user, uint256 score, string memory username) internal {
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
                leaderboard.push(Player(user, score, uint64(block.timestamp), username));
            } else {
                // Find the lowest score
                uint256 minIndex = 0;
                for (uint256 i = 1; i < leaderboard.length; i++) {
                    if (leaderboard[i].score < leaderboard[minIndex].score) {
                        minIndex = i;
                    }
                }

                if (score > leaderboard[minIndex].score) {
                    leaderboard[minIndex] = Player(user, score, uint64(block.timestamp), username);
                }
            }
        }
    }

    function getLeaderboard() external view returns (Player[] memory) {
        return leaderboard;
    }
}
