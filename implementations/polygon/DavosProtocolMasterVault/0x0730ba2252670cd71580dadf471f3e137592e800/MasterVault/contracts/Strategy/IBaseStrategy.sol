//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseStrategy {

// to deposit funds to a destination contract
function deposit(uint256 amount) external returns(uint256);

// to withdraw funds from the destination contract
function withdraw(uint256 amount) external returns(uint256);

// claim or collect rewards functions
function harvest() external;

// disable deposit
function pause() external;

// enable deposit
function unpause() external;

// calculate the total underlying token in the strategy contract and destination contract
function balanceOf() external view returns(uint256);

// calculate the total amount of tokens in the strategy contract
function balanceOfWant() external view returns(uint256);

// calculate the total amount of tokens in the destination contract
function balanceOfPool() external view returns(uint256);

// set the recipient address of the collected fee
function setFeeRecipient(address newFeeRecipient) external;

function canDeposit(uint256 amount) external view returns(bool);
}