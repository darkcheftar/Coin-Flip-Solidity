//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CoinFlip {
    mapping (address => uint) balance;
    mapping (address => bool) existingUser;
    mapping (address => bool) isBetting;
    struct Bet{
        address user;
        uint amount;
        uint choice;
        bool completed;
        bool won;
    }
    Bet[] public bets;
    uint count;
    event Win(address winner, uint amount);

    function getBalance(address user) public view returns (uint){
        if(existingUser[user]==true){
            return balance[user];
        }
        return 100;
    }
    function setBet(uint _amount, uint _choice) public{
        require(isBetting[msg.sender] == false, "Already Betting");
        require(_choice==1 || _choice==0, "Wrong Choice");

        if(existingUser[msg.sender] == false){
            existingUser[msg.sender] = true;
            balance[msg.sender] = 100;
        }
        require(balance[msg.sender]>=_amount,"Insufficent Balance");
        balance[msg.sender] -= _amount;

        isBetting[msg.sender] = true;
        bets.push(Bet(msg.sender, _amount, _choice, false, false));
    }

    function flipingCoin() public view returns (bytes32 result) {
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
        uint secret = uint(flipingCoin())%2;

        for(uint i = count;i < bets.length; i++){
            Bet memory bet = bets[i];
            if(bet.choice == secret){
                balance[bet.user] += bet.amount*2;
                emit Win(bet.user, bet.amount);
                bets[i].won = true;
            }
            bets[i].completed = true;
            isBetting[bet.user] = false;
        }

        count = bets.length;
    }
}
