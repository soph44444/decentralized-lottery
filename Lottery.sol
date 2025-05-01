// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedLottery {
    address public owner;
    uint256 public ticketPrice;
    uint256 public roundEndTime;
    address[] public players;
    bool public roundActive;

    mapping(address => uint256) public tickets;

    event TicketPurchased(address indexed player, uint256 ticketsBought);
    event WinnerSelected(address indexed winner, uint256 prizeAmount);
    event NewRoundStarted(uint256 roundEndTime);
    event RoundEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier isRoundActive() {
        require(roundActive && block.timestamp < roundEndTime, "No active round");
        _;
    }

    constructor(uint256 _ticketPrice, uint256 _durationInMinutes) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        startNewRound(_durationInMinutes);
    }

    function buyTicket(uint256 numTickets) external payable isRoundActive {
        require(msg.value == ticketPrice * numTickets, "Incorrect Ether sent");

        tickets[msg.sender] += numTickets;

        for (uint256 i = 0; i < numTickets; i++) {
            players.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, numTickets);
    }

    function startNewRound(uint256 durationInMinutes) public onlyOwner {
        require(!roundActive || block.timestamp >= roundEndTime, "Previous round still active");

        delete players;
        roundEndTime = block.timestamp + (durationInMinutes * 1 minutes);
        roundActive = true;

        emit NewRoundStarted(roundEndTime);
    }

    function endRoundAndPickWinner() public onlyOwner {
        require(roundActive, "No active round");
        require(block.timestamp >= roundEndTime, "Round still ongoing");
        require(players.length > 0, "No players");

        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))
        ) % players.length;

        address winner = players[winnerIndex];
        uint256 prizeAmount = address(this).balance;

        (bool sent, ) = payable(winner).call{value: prizeAmount}("");
        require(sent, "Failed to send Ether to winner");

        emit WinnerSelected(winner, prizeAmount);
        emit RoundEnded();
        roundActive = false;
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= roundEndTime) return 0;
        return roundEndTime - block.timestamp;
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
