// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solmate/auth/Owned.sol";

/// @notice Base contract for sigmoid hosting protocol
contract HostingProtocol is Owned {
    using SafeERC20 for IERC20;

    error Forbidden();

    enum NodeStatus {
        QUEUED,
        RUNNING,
        STOPPING,
        DOWN,
        ERROR
    }

    struct Node {
        uint256 amount;
        string nodeType;
        NodeStatus status;
    }

    mapping(uint256 => Node) public nodes;

    /// @notice Address of a relayer
    address public relayer;

    /// @notice Address of manager contract
    address public managerContract;

    /// @notice Address of the admin
    address public admin;

    /// @notice Last issued Node ID
    uint32 public counter;

    constructor (address relayer_, address managerContract_) Owned(msg.sender) {
        relayer = relayer_;
        managerContract = managerContract_;
    }

    function runNode(IERC20 targetToken, uint256 amount, string memory nodeType) public returns (uint256) {
        if (msg.sender != managerContract) {
            revert Forbidden();
        }
        targetToken.safeTransferFrom(msg.sender, address(this), amount);
        nodes[++counter] = Node(amount, nodeType, NodeStatus.QUEUED);
        emit NodeCreated(counter, targetToken, amount, nodeType);
        emit StatusUpdated(counter, NodeStatus.QUEUED);
        return counter;
    }

    function updateStatus(uint32 nodeId, NodeStatus status) public {
        if (msg.sender != relayer) {
            revert Forbidden();
        }
        require(nodeId < counter, "Invalid node ID");
        nodes[nodeId].status = status;
        emit StatusUpdated(nodeId, status);
    }

    function stopNode(uint32 nodeId) public {
        if (msg.sender != managerContract || msg.sender != relayer) {
            revert Forbidden();
        }
        require(nodeId < counter, "Invalid node ID");
        nodes[nodeId].status = NodeStatus.STOPPING;
        emit StatusUpdated(nodeId, NodeStatus.STOPPING);
    }

    function setRelayer(address relayer_) public onlyOwner {
        relayer = relayer_;
    }

    function setManagerContract(address managerContract_) public onlyOwner {
        managerContract = managerContract_;
    }

    // --------------------------  EVENTS  --------------------------
    event NodeCreated(uint32 indexed nodeId, IERC20 targetToken, uint256 amount, string nodeType);
    event StatusUpdated(uint32 indexed nodeId, NodeStatus status);
}
