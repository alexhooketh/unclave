// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IController.sol";

interface IMiniAccount {
    function submit(IController.UserOpRequest calldata userOp) external;
}