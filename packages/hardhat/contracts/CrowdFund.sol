// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./FundingRecipient.sol";

contract CrowdFund {
    mapping(address => uint256) public balances;

    /////////////////
    /// Errors //////
    /////////////////

    error NotOpenToWithdraw();
    error WithdrawTransferFailed(address to, uint256 amount);

    //////////////////////
    /// State Variables //
    //////////////////////

    FundingRecipient public fundingRecipient;
    bool public openToWithdraw; 
    uint256 public deadline = block.timestamp + 30 seconds;
    uint256 public constant threshold = 1 ether;
    error TooEarly(uint256 deadline, uint256 currentTimestamp);

    ////////////////
    /// Events /////
    ////////////////

    event Contribution(address, uint256);

    ///////////////////
    /// Modifiers /////
    ///////////////////

    modifier notCompleted() {
        _;
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address fundingRecipientAddress) {
        fundingRecipient = FundingRecipient(fundingRecipientAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function contribute() public payable {
        balances[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function withdraw() public {
        if (!openToWithdraw) revert NotOpenToWithdraw();
        
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        
        (bool success,) = msg.sender.call{value: balance}("");
        if (!success) revert WithdrawTransferFailed(msg.sender, balance);
    }

    function execute() public {
        if (block.timestamp <= deadline) revert TooEarly(deadline, block.timestamp);
        
        if (address(this).balance >= threshold) {
            fundingRecipient.complete{value: address(this).balance}();
        } else {
            openToWithdraw = true;
        }
    }

    receive() external payable {
        contribute();
    }    

    ////////////////////////
    /// View Functions /////
    ////////////////////////

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
