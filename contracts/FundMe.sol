// SPDX-License-Identifier: MIT

// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH
pragma solidity ^0.6.6;

// Get the latest ETH/USD price from chainlink price feed
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // when you call a payable function you can add a wei value to it, the contract will be the owner of that amount of wei
    function fund() public payable {
        // set min price to $20
        uint256 minimumUSD = 20 * 10**18; // 20 * 10^18 per avere il numero a 18 cifre
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Minimum required: $20"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // to have price with 18 digits
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 20 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "tentativo di prelievo fallito");
        _; // run the rest of the code under the modifier
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}
