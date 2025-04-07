// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LeaderboardGM {
    struct Entry {
        address user;
        uint256 score;
    }

    Entry[] public leaderboard;
    mapping(address => uint256) public userScores;
    mapping(address => bool) public isWhitelisted;

    uint256 public constant MAX_PLAYERS = 1000;
    bool public submissionsPaused = false;
    address public owner;

    event ScoreSubmitted(address indexed user, uint256 score);

    constructor() {
        owner = msg.sender;
        isWhitelisted[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!submissionsPaused, "Score submission is paused");
        _;
    }

    function pauseSubmissions(bool _pause) external onlyOwner {
        submissionsPaused = _pause;
    }

    function addToWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = true;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = false;
    }

    function submitScore(uint256 score) external whenNotPaused {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        require(score > 0, "Score must be positive");
        uint256 currentScore = userScores[msg.sender];
        if (score <= currentScore) return;

        userScores[msg.sender] = score;
        bool updated = false;

        for (uint i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].user == msg.sender) {
                leaderboard[i].score = score;
                updated = true;
                break;
            }
        }

        if (!updated) {
            if (leaderboard.length < MAX_PLAYERS) {
                leaderboard.push(Entry(msg.sender, score));
            } else if (score > leaderboard[leaderboard.length - 1].score) {
                leaderboard.push(Entry(msg.sender, score));
            } else {
                return;
            }
        }

        // sort descending
        for (uint i = 0; i < leaderboard.length; i++) {
            for (uint j = i + 1; j < leaderboard.length; j++) {
                if (leaderboard[j].score > leaderboard[i].score) {
                    Entry memory temp = leaderboard[i];
                    leaderboard[i] = leaderboard[j];
                    leaderboard[j] = temp;
                }
            }
        }

        // trim
        if (leaderboard.length > MAX_PLAYERS) {
            leaderboard.pop();
        }
        emit ScoreSubmitted(msg.sender, score);
    }

    function getLeaderboard() external view onlyOwner returns (Entry[] memory) {
        return leaderboard;
    }

    function getLeaderboardLength() external view onlyOwner returns (uint256) {
        return leaderboard.length;
    }
}
