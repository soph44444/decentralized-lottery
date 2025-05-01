// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A basic decentralized lottery system.
contract DecentralizedLottery {
    
    uint256 public ticketPrice;      // Price for one lottery ticket.
    uint256 public roundEndTime;     // Time when the lottery round ends.
    address[] public players;        // List of players who've bought tickets.
    bool public roundActive;         // Indicates if a lottery round is active.

    mapping(address => uint256) public tickets; // Tracks number of tickets per player.

    // Events that help track contract actions.
    event TicketPurchased(address indexed player, uint256 ticketsBought);
    event WinnerSelected(address indexed winner, uint256 prizeAmount);
    event NewRoundStarted(uint256 roundEndTime);
    event RoundEnded();

    // Ensures functions only run if the lottery round is currently active.
    modifier isRoundActive() {
        require(roundActive && block.timestamp < roundEndTime, "No active round");
        _;
    }

    // Ensures a new round can only start if the previous round ended or hasn't started yet.
    modifier roundNotActiveOrExpired() {
        require(!roundActive || block.timestamp >= roundEndTime, "Previous round still active");
        _;
    }

    // Initializes the lottery contract with a ticket price.
    constructor(uint256 _ticketPrice) {
        ticketPrice = _ticketPrice;
    }

    // Players call this function to buy lottery tickets during an active round.
    function buyTicket(uint256 numTickets) external payable isRoundActive {
        require(msg.value == ticketPrice * numTickets, "Incorrect Ether sent");

        // Increase the ticket count for the player.
        tickets[msg.sender] += numTickets;

        // Add the player to the players array once per ticket.
        for (uint256 i = 0; i < numTickets; i++) {
            players.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, numTickets);
    }

    // Anyone can start a new round if the previous round is finished.
    function startNewRound(uint256 durationInMinutes) public roundNotActiveOrExpired {
        delete players;  // Clears the list of players from previous round.
        roundEndTime = block.timestamp + (durationInMinutes * 1 minutes); // Sets round duration.
        roundActive = true; // Activates new round.

        emit NewRoundStarted(roundEndTime);
    }

    // Ends the current round and picks a random winner.
    function endRoundAndPickWinner() public {
        require(roundActive, "No active round");
        require(block.timestamp >= roundEndTime, "Round still ongoing");
        require(players.length > 0, "No players");

        // Selects a winner using a simple random method (not truly secure).
        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))
        ) % players.length;

        address winner = players[winnerIndex]; // Winner's address.
        uint256 prizeAmount = address(this).balance; // Total prize pool.

        // Sends prize to winner.
        (bool sent, ) = payable(winner).call{value: prizeAmount}("");
        require(sent, "Failed to send Ether to winner");

        emit WinnerSelected(winner, prizeAmount);
        emit RoundEnded();

        roundActive = false; // Round officially ends.
    }

    // Utility function to retrieve all current players.
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    // Utility function to check how much time is left in the current round.
    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= roundEndTime) return 0;
        return roundEndTime - block.timestamp;
    }

    // Checks the balance of ETH currently stored in the contract (prize pool).
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

