// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract Lottery is VRFV2WrapperConsumerBase{

    address public owner;

    address payable[] public players;

    uint public lotteryId;

    uint public randomId;

    mapping (uint => address payable) public lotteryHistory; //array holding previous lottery wiiners

    uint internal fee = 2 * 10 ** 18; // VRF fee

    uint256 public randomResult;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 50000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

 constructor()
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        owner = msg.sender;
        lotteryId = 1;
    }

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    //note: VRF requires the gaslimit on the requestRandomness() call to be 400,000
    function getRandomNumber() public returns (uint256 requestId) {

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");

         requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        return requestId;
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords) internal override {
        randomResult = _randomWords[0];
    }

    function getRandomResult() public view returns (uint256) {
        return randomResult;
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        // address of player entering lottery
        players.push(payable(msg.sender));
    }

    function pickWinner() public onlyowner {
        getRandomNumber();
    }

    function payWinner() public {

        require(randomResult > 0, "Must have a source of randomness before choosing winner");

        uint index = randomResult % players.length;

        players[index].transfer(address(this).balance);


        lotteryHistory[lotteryId] = players[index];

        lotteryId++;

        // reset the state of the contract
        players = new address payable[](0);
        randomResult = 0;
    }
}
