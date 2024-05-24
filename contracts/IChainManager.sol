// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IChainManager {
    function sendPrintMessage(bytes32 print, uint256 value) external payable;
    function isIncomingPrintValid(bytes32 print, bytes calldata proof) external payable;
}