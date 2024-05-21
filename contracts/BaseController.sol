// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./node_modules/@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";
import "./IController.sol";
import "./IMiniAccount.sol";

abstract contract BaseController is IController {
    mapping(uint256 => bytes32) public incomingPrints;
    mapping(uint256 => bytes32) public outgoingPrints;
    mapping(uint256 => uint256) public outgoingPrintsCount;
    mapping(uint256 => address) public knownControllers;

    address public manager;
    constructor() {
        manager = msg.sender;
    }
    modifier onlyManager {
        require(msg.sender == manager, "gg");
    }
    function setKnownController(uint256 chainId, address controller) external onlyManager {
        knownControllers[chainId] = controller;
    }
    function setFee(uint256 _fee) external onlyManager {
        fee = _fee;
    }
    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }

    uint256 public fee = 0.001 ether;

    function submit(uint256 chainId, address to, bytes32 userOpHash) external payable {
        require(msg.value == fee, "iv");

        UserOpRequest memory userOp = UserOpRequest({ from: msg.sender, to: to, userOpHash: userOpHash });

        bytes memory print = abi.encodePacked(outgoingPrints[chainId], userOp);
        outgoingPrints[chainId] = keccak256(print);
        outgoingPrintsCount[chainId]++;

        emit OutgoingPrintUpdate(chainId, userOp);
    }

    function _sendPrintMessage(uint256 destinationChainId, bytes32 print, uint256 value) internal;

    function drop(uint256 chainId) external {
        bytes32 print = outgoingPrints[chainId];
        uint256 userOpsCount = outgoingPrintsCount[chainId];

        uint256 feeToPay = fee / 2 * userOpsCount;
        _sendPrintMessage(chainId, print, feeToPay);

        emit OutgoingPrintDropped(chainId, print, userOpsCount);

        delete outgoingPrints[chainId];
        delete outgoingPrintsCount[chainId];

        (bool s,) = msg.sender.call{value: feeToPay}("");
        require(s);
    }

    // one of these functions must be defined
    // for L2 controller it'll probably be first, for L1 controller - second
    function _receivePrint(uint256 chainId, bytes32 print) external payable;
    function _isIncomingPrintValid(uint256 chainId, bytes32 print, bytes calldata proof) internal;

    function revealUserOps(uint256 chainId, UserOpRequest[] calldata userOps, bytes calldata proof) external {
        bytes32 print;
        for (uint256 i = 0; i < userOps.length; i++) {
            UserOpRequest userOp = userOps[i];
            IMiniAccount(userOp.to).submit(userOp);
            print = keccak256(abi.encodePacked(print, userOp));
        }

        bytes32 supposedPrint = incomingPrints[chainId];
        require(supposedPrint == 0 || supposedPrint == print, "ip");

        _isIncomingPrintValid(chainId, print, proof);

        (bool s,) = msg.sender.call{value: fee / 2 * userOps.length}("");
        require(s);
    }
}