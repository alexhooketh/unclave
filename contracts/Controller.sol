// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./node_modules/@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";

contract Controller {
    mapping(uint256=>bool) public userOpPrints;

    address constant inboxContract = 0x19A5bFCBE15f98Aa073B9F81b58466521479DF8D;
    IZkSync constant zksync = IZkSync(0x32400084C286CF3E17e7B677ea9583e60a000324);

    function receiveInbox(uint256 _l2BlockNumber, uint256 _index, uint16 _l2TxNumberInBlock, bytes calldata _message, bytes32[] calldata _proof, uint256[] calldata prints) external {

        L2Message memory message = L2Message({sender: inboxContract, data: _message, txNumberInBlock:_l2TxNumberInBlock});
        bool success = zksync.proveL2MessageInclusion(
          _l2BlockNumber,
          _index,
          message,
          _proof
        );
        require(success, "ip");

        uint256 reconstructedPrint;
        for (uint256 i; i < prints.length; i++) {
            uint256 userOpPrint = prints[i];
            userOpPrints[userOpPrint] = true;
            reconstructedPrint += userOpPrint;
        }
        require(reconstructedPrint == uint256(bytes32(_message)), "is");

        (bool s,) = msg.sender.call{value:address(this).balance}.call("");
        require(s);

    }
}
