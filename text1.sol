// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HistoryQuizBattle {
    address public owner;

    // Structs to represent players and battles
    struct Player {
        address playerAddress;
        uint256 points;
        bool isInBattle;
    }

    struct Battle {
        uint256 battleId;
        address player1;
        address player2;
        uint256 player1Score;
        uint256 player2Score;
        bool isCompleted;
        address winner;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Battle) public battles;
    uint256 public battleCount;

    event BattleStarted(uint256 battleId, address player1, address player2);
    event BattleEnded(uint256 battleId, address winner);
    event PointsAwarded(address player, uint256 points);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier notInBattle(address _player) {
        require(!players[_player].isInBattle, "Player is already in a battle");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerPlayer() external {
        require(players[msg.sender].playerAddress == address(0), "Player already registered");

        players[msg.sender] = Player({
            playerAddress: msg.sender,
            points: 0,
            isInBattle: false
        });
    }

    function startBattle(address _opponent) external notInBattle(msg.sender) notInBattle(_opponent) {
        battleCount++;

        address player1 = msg.sender;
        address player2 = _opponent;

        players[player1].isInBattle = true;
        players[player2].isInBattle = true;

        battles[battleCount] = Battle({
            battleId: battleCount,
            player1: player1,
            player2: player2,
            player1Score: 0,
            player2Score: 0,
            isCompleted: false,
            winner: address(0)
        });

        emit BattleStarted(battleCount, player1, player2);
    }

    function submitAnswer(uint256 _battleId, uint256 _playerAnswer, uint256 _correctAnswer) external {
        Battle storage battle = battles[_battleId];

        require(battle.isCompleted == false, "Battle already completed");
        require(msg.sender == battle.player1 || msg.sender == battle.player2, "You are not in this battle");

        uint256 score = (_playerAnswer == _correctAnswer) ? 10 : 0;

        if (msg.sender == battle.player1) {
            battle.player1Score = score;
        } else {
            battle.player2Score = score;
        }

        // Check if both players have answered
        if (battle.player1Score > 0 && battle.player2Score > 0) {
            completeBattle(_battleId);
        }
    }

    function completeBattle(uint256 _battleId) private {
        Battle storage battle = battles[_battleId];

        battle.isCompleted = true;

        if (battle.player1Score > battle.player2Score) {
            battle.winner = battle.player1;
            players[battle.player1].points += 10;
        } else if (battle.player2Score > battle.player1Score) {
            battle.winner = battle.player2;
            players[battle.player2].points += 10;
        }

        emit BattleEnded(_battleId, battle.winner);
    }

    function getPlayerPoints(address _player) external view returns (uint256) {
        return players[_player].points;
    }

    function getBattleDetails(uint256 _battleId) external view returns (Battle memory) {
        return battles[_battleId];
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
