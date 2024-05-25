// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IController.sol";
import "./IMiniAccount.sol";

abstract contract Controller is IController {
    mapping(uint256 => bytes32) public incomingPrints;
    mapping(uint256 => bytes32) public outgoingPrints;
    mapping(uint256 => uint256) public outgoingPrintsCount;

    mapping(uint256 => address) public controllers;
    mapping(uint256 => address) public chainManagers;

    address public manager;
    constructor() {
        manager = msg.sender;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "gg");
        _;
    }
    function setController(uint256 chainId, address controller) external onlyManager {
        controllers[chainId] = controller;
    }
    function setChainManager(uint256 chainId, address chainManager) external onlyManager {
        chainManagers[chainId] = chainManager;
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

        bytes memory print = abi.encodePacked(outgoingPrints[chainId], msg.sender, to, userOpHash);
        outgoingPrints[chainId] = keccak256(print);
        outgoingPrintsCount[chainId]++;

        emit OutgoingPrintUpdate(chainId, userOp);
    }

    function _sendPrintMessage(uint256 chainId, bytes32 print, uint256 value) internal {
        address chain = chainManagers[chainId];
        require(chain != address(0), "ic");

        (bool s,) = chain.delegatecall(abi.encodeWithSignature("sendPrintMessage(address,bytes32,uint256)", controllers[chainId], print, value));
        require(s);
    }

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

    function receivePrint(uint256 chainId, bytes32 print) external payable {
        require(msg.sender == controllers[chainId], "ws");
        require(incomingPrints[chainId] == bytes32(0), "qf");
        incomingPrints[chainId] = print;
    }

    function _isIncomingPrintValid(uint256 chainId, bytes32 print, bytes calldata proof) internal returns(bool) {
        address chain = chainManagers[chainId];
        if (chain == address(0)) {
            return false;
        }

        (bool s,) = chain.delegatecall(abi.encodeWithSignature("isIncomingPrintValid(address, bytes32,bytes)", controllers[chainId], print, proof));
        return s;
    }

    function revealUserOps(uint256 chainId, UserOpRequest[] calldata userOps, bytes calldata proof) external {
        bytes32 print;
        for (uint256 i = 0; i < userOps.length; i++) {
            UserOpRequest memory userOp = userOps[i];
            IMiniAccount(userOp.to).submit(userOp);
            print = keccak256(abi.encodePacked(print, userOp.from, userOp.to, userOp.userOpHash));
        }

        bytes32 supposedPrint = incomingPrints[chainId];
        if (supposedPrint != print) {
            require(_isIncomingPrintValid(chainId, print, proof), "ip");
        }

        (bool s,) = msg.sender.call{value: fee / 2 * userOps.length}("");
        require(s);
    }
}