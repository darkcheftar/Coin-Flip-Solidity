//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CoinFlip {
    mapping (address => uint) balance;                                      // to keep track of balance of a given user
    mapping (address => bool) existingUser;                                 // to keep track of previous users
    mapping (address => bool) isBetting;                                    // to keep track of current betting users
    struct Bet{
        address user;    
        uint amount;                                                        // bet amount
        uint choice;                                                        // choice either 0=>heads or 1=>tails
        bool completed;                                                     // to know if the bet is rewarded or not
        bool won;                                                           // to know if the bet lead to win
    }
    Bet[] public bets;                                                      // to keep track of all the bets that are placed so far
    uint count;                                                             // the count of bets that are rewarded
    event Win(address winner, uint amount);                                 // event to be emitted when user wins the bet

    function getBalance(address user) public view returns (uint){           // to get the balance of any user
        if(existingUser[user]==true){
            return balance[user];
        }
        return 100;
    }
    function setBet(uint _amount, uint _choice) public{                     // enables the user to place bet
        require(isBetting[msg.sender] == false, "Already Betting");         // Disallow if already betting
        require(_choice==1 || _choice==0, "Wrong Choice");                  // Disallow if the choice is other than heads or tails

        if(existingUser[msg.sender] == false){                              // give default 100 balance if the user is new
            existingUser[msg.sender] = true;
            balance[msg.sender] = 100;
        }
        require(balance[msg.sender]>=_amount,"Insufficent Balance");        // Disallow if the bet amount is greater than balance
        balance[msg.sender] -= _amount;                                     // Deduct the bet amount from balance

        isBetting[msg.sender] = true;                                       // keeping track of betting to avoid multiple bets by same user
        bets.push(Bet(msg.sender, _amount, _choice, false, false));
    }

    function flipingCoin() public view returns (bytes32 result) {           // Harmony VRF used to get a 0=>heads or 1=>tail
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
        let memPtr := mload(0x40)
        if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
            invalid()
        }
        result := mload(memPtr)
        }
  }
    function rewardBets() public {
        require(count < bets.length, "No Bets placed");
        uint secret = uint(flipingCoin())%2;                                 // Actually coin flip simulation using Harmony VRF

        for(uint i = count;i < bets.length; i++){
            Bet memory bet = bets[i];
            if(bet.choice == secret){
                balance[bet.user] += bet.amount*2;
                emit Win(bet.user, bet.amount);                             // Emitting the win event
                bets[i].won = true;
            }
            bets[i].completed = true;
            isBetting[bet.user] = false;                                    // Marking the bet completed so as to let the user bet again
        }

        count = bets.length;                                                // updating count of bets that are resolved
    }
}
