// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IChainManager.sol";
import "./node_modules/@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";

contract ZksyncManager is IChainManager {
    IZkSync constant zksync = IZkSync(0x32400084C286CF3E17e7B677ea9583e60a000324);

    // address alias must already be applied to the input controller!
    function sendPrintMessage(address controller, bytes32 print, uint256 value, bytes calldata txData) external payable {
        uint256 id;
        assembly {
            id := chainid()
        }
        
        (
            uint256 _l2GasLimit,
            uint256 _l2GasPerPubdataByteLimit,
            bytes[] _factoryDeps
        ) = abi.decode(txData);
        zksync.requestL2Transaction(controller, value, abi.encodeWithSignature("receivePrint(uint256,bytes32)", id, print), _l2GasLimit, _l2GasPerPubdataByteLimit, _factoryDeps, controller);
    }

    function isIncomingPrintValid(address controller, bytes32 print, bytes calldata proof) external {
        (
            uint256 _l2BlockNumber,
            uint256 _index,
            uint16 _l2TxNumberInBlock,
            bytes32[] memory _proof
        ) = abi.decode(proof);
        bytes memory message = bytes(print);
        L2Message memory message = L2Message({sender: controller, data: message, txNumberInBlock: _l2TxNumberInBlock});

        bool success = zksync.proveL2MessageInclusion(
            _l2BlockNumber,
            _index,
            message,
            _proof
        );
        require(success);

    }
}