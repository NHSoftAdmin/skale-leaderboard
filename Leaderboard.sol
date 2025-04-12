// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Leaderboard is AccessControl {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /// @dev Struct representing a user entry in the leaderboard
    struct User {
        address user; // The user's Ethereum address
        uint64 highScore; // The user's high score
        uint64 timestamp; // The timestamp when the score was submitted
        uint32 index; // The index of the user in the sorted leaderboard
    }

    uint32 resetIndex; // Variable used for incremental reset
    User[] public leaderboard; // The leaderboard array of User structs
    uint32 public maxLength; // The maximum length of the leaderboard
    bool public paused; // Flag indicating whether score submission is paused
    uint256 public amount = 0.00001 ether; //Amount to be distributed on sFUEL distribution

    event IncrementalReset(uint32 indexed amount); // Event emitted when an incremental reset is performed
    event Reset(); // Event emitted when the leaderboard is completely reset
    event Whitelist(address indexed user); // User wallet whitelisted
    event SubmitScore(address indexed user, uint64 indexed highScore); // Event emitted when a score is submitted but not added to the leaderboard
    event SubmitScoreAndAdd(address indexed user, uint64 indexed highScore); // Event emitted when a score is submitted and added to the leaderboard

    /// @notice Constructor to initialize the contract
    /// @param _maxLength The maximum length of the leaderboard
    constructor(uint32 _maxLength) {
        maxLength = _maxLength;
        paused = false;
    }

    /// @notice Function for the manager backend wallet to provide whitelist role to the user wallet
    /// The goal of this function is to control who can access the sbmitScore function and avoid that the function is spammed
    /// @param to User wallet address
    function concedeWhitelistRole(address to) external onlyRole(MANAGER_ROLE) {       
        require(!hasRole(WHITELIST_ROLE, to), "Already with whitelist role");
  
        //The sFUEL distribution can be done like this or with other sFUEL  distribution solution 
        if(to.balance < 0.000005 ether){            
            require(address(this).balance >= amount, "ContractOutOfSFuel");
            payable(to).transfer(amount);            
            emit Whitelist(to);
        }
        _grantRole(WHITELIST_ROLE, to);
    }


    /// @notice Submit a new high score for a user    
    /// @param highScore The new high score to be submitted
    /// @dev Only callable by the SERVER_ROLE
    function submitScore(uint64 highScore) public virtual onlyRole(WHITELIST_ROLE) {
        if (paused) revert("Submitted Scores is Paused");
        if (length() >= maxLength && highScore <= leaderboard[length() - 1].highScore) {
            emit SubmitScore(msg.sender, highScore);
            return;
        }
        _addToLeaderboard(msg.sender, highScore, length() >= maxLength ? length() - 1 : length());
        _sort(leaderboard, 0, int32(length()));

        _revokeRole(WHITELIST_ROLE, msg.sender);

    }


    /// @dev Internal function to add a new user to the leaderboard
    /// @param user The Ethereum address of the user
    /// @param highScore The new high score to be added
    /// @param index The index at which the new user should be inserted
    function _addToLeaderboard(address user, uint64 highScore, uint32 index) internal virtual {
        leaderboard.push(User(user, highScore, uint64(block.timestamp), index));
        emit SubmitScoreAndAdd(user, highScore);
    }

    /// @notice Reset the entire leaderboard
    /// @dev Only callable by the MANAGER_ROLE
    /// @dev Will revert if the leaderboard length is greater than 25,000
    function reset() external onlyRole(MANAGER_ROLE) {
        if (length() < 25_000) {
            delete leaderboard;
            emit Reset();
        }
        revert("Reset must be done in increments");
    }

    /// @notice Perform an incremental reset of the leaderboard
    /// @dev Only callable by the MANAGER_ROLE
    /// @dev Removes up to 1,500 entries from the leaderboard
    function incrementalReset() public virtual onlyRole(MANAGER_ROLE) {
        if (!paused) paused = true;
        uint32 removalAmount = length() > 1500 ? 1500 : length();
        for (uint32 i = 0; i < removalAmount; i++) {
            leaderboard.pop();
        }
        emit IncrementalReset(removalAmount);
    }

    /// @dev Internal function to get the leaderboard length
    function length() internal view returns (uint32) {
        return uint32(leaderboard.length);
    }    

    /// @dev Internal function to sort the leaderboard array using the quicksort algorithm
    /// @param arr The leaderboard array to be sorted
    /// @param left The left index of the subarray to be sorted
    /// @param right The right index of the subarray to be sorted
    function _sort(User[] memory arr, int256 left, int256 right) internal virtual {
        int256 i = left;
        int256 j = right;
        if (i == j) return;

        uint256 pivot = arr[uint256(left + (right - left) / 2)].index;
        while (i <= j) {
            while (arr[uint256(i)].index > pivot) i++;
            while (pivot > arr[uint256(j)].index) j--;
            if (i <= j) {
                (arr[uint256(i)].index, arr[uint256(i)].index) = (arr[uint256(i)].index, arr[uint256(i)].index);
                i++;
                j--;
            }
        }

        if (left < j)
            _sort(arr, left, j);
        if (i < right)
            _sort(arr, i, right);
    }

    /// @notice Required if the sFUEL distribution is done through the contract
    receive() external payable {}
}