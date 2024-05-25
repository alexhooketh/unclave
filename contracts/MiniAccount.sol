// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./node_modules/@account-abstraction/contracts/core/BaseAccount.sol";
import "./node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./node_modules/@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./interfaces/IMiniAccount.sol";
import "./interfaces/IController.sol";

contract MiniAccount is BaseAccount, IMiniAccount {
    mapping(bytes32 => bool) pendingActions;

    address public controller;
    address public parent;
    address public authorizedSender;
    constructor(address _controller, address _parent, address _authorizedSender) {
        controller = _controller;
        parent = _parent;
        authorizedSender = _authorizedSender;
        _;
    }

    function submit(IController.UserOpRequest calldata userOp) external {
        require(msg.sender == controller, "gg");
        require(userOp.from == parent, "is");

        pendingActions[userOp.userOpHash] = true;
    }

    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        if !pendingActions[userOpHash] {
            bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
            if (owner != ECDSA.recover(hash, userOp.signature))
                return 1;
        }
        return 0;
    }

    function changeAuthorizedSender(address _authorizedSender) external {
        require(msg.sender == address(this), "gg");
        authorizedSender == _authorizedSender;
    }
}