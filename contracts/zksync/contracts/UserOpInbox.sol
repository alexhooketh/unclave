//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import "@matterlabs/zksync-contracts/l2/contracts/bridge/interfaces/IL2Bridge.sol";

// userop inbox collects userop hashes, builds uint256 userop "prints" from them and adds these prints to a single inbox print.
// every userop request has to carry 0.0001 eth fee, 50% of which will be sent to the one who initiated the sending to the L1 controller contract,
// and the rest will be withdrawn to the controller as a fee for the revealing initiator
// revealing - the process where the controller contracts gets all userop prints that were used to construct the inbox print.
// this contract is specifically designed for efficiency within era VM - it doesn't hash anything, only uses two storage slots and emits two kinds of events.

contract UserOpInbox {
    uint256 public inboxPrint;
    uint256 public totalPrints;

    uint256 constant printFee = 0.0001 ether;
    address constant l1Operator = 0x11f943b2c77b743AB90f4A0Ae7d5A4e7FCA3E102; // todo
    IL2Bridge constant bridge = IL2Bridge(0x11f943b2c77b743AB90f4A0Ae7d5A4e7FCA3E102);

    event NewPrint(uint256 print);
    event InboxPrintSent(uint256 inboxPrint, uint256 totalPrints);

    function submit(bytes32 userOpHash) external payable {
        // each submit has to carry 0.0001 eth fee
        require(msg.value >= printFee, "if");

        // build the userop print with last 12 bytes of the hash and sender address
        uint256 print = (uint256(userOpHash) << 160) | uint256(uint160(msg.sender));
        inboxPrint += print;
        totalPrints++;

        // for builders
        emit NewPrint(print);
    }

    function drop() external returns (bytes32 messageHash) {
        // reimburse the caller with 50% of total fees
        (bool s,) = msg.sender.call{value: printFee / 2 * totalPrints}("");
        require(s);

        // send the inbox print to L1 and withdraw all remaining fees to the controller contract
        messageHash = L1_MESSENGER_CONTRACT.sendToL1(abi.encode(inboxPrint));
        bridge.withdraw(l1Operator, address(ETH_TOKEN_SYSTEM_CONTRACT), address(this).balance);

        // for builders
        emit InboxPrintSent(inboxPrint, totalPrints);

        // nullify everything
        inboxPrint = 0;
        totalPrints = 0;
    }
}
