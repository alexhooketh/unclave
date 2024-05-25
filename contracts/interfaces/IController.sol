// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IController {
    struct UserOpRequest {
        address from;
        address to;
        bytes32 userOpHash;
    }

    event OutgoingPrintUpdate(uint256 indexed chainId, UserOpRequest userOp);
    event OutgoingPrintDropped(uint256 indexed chainId, bytes32 print, uint256 userOpsCount);

    function incomingPrints(uint256) external returns(bytes32);
    function outgoingPrints(uint256) external returns(bytes32);
    function outgoingPrintsCount(uint256) external returns(uint256);
    function knownControllers(uint256) external returns(address);

    function submit(uint256 chainId, address to, bytes32 userOpHash) external payable;
    function drop(uint256 chainId) external;
    function _receivePrint(uint256 chainId, bytes32 print) external payable;
    function revealUserOps(uint256 chainId, UserOpRequest[] calldata userOps, bytes calldata proof) external;
}