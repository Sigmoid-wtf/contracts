// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OlasManager
 * @dev OlasManager contract for managing staking and unstaking of OLAS tokens.
 */
contract OlasManager is ERC20, Ownable {
    using SafeERC20 for IERC20;

    /// @dev Constant representing the denominator for percentage calculations.
    uint256 public constant DENOMINATOR = 1e18;

    /// @dev Constant representing the reward fee percentage.
    uint256 public constant REWARD_FEE_PERCENTAGE = 10;

    /// @dev Percentage of the reward fee that goes to the treasury.
    uint256 public treasuryFeePercentage = 5;

    /// @dev Percentage of the reward fee that goes to the emergency treasury.
    uint256 public emergencyTreasuryFeePercentage = 5;

    /// @dev The OLAS token contract.
    IERC20 public olasToken;

    /// @dev Address of the admin.
    address public admin;

    /// @dev Address of the relayer.
    address public relayer;

    /// @dev Address of the treasury.
    address public treasury;

    /// @dev Address of the emergency treasury.
    address public emergencyTreasury;

    /// @dev Address of the hosting protocol.
    address public hostingProtocol;

    /// @dev Maximum threshold for non-staked OLAS tokens.
    uint256 public maxThreshold;

    /// @dev Total amount of staked OLAS tokens.
    uint256 public olasStaked;

    /// @dev Structure to store unstake request information.
    struct UnstakeRequestInfo {
        address user;
        bool isClaimed;
        uint128 amount;
        uint128 amountFilled;
    }

    /// @dev Mapping from unstake request ID to unstake request information.
    mapping(uint256 => UnstakeRequestInfo) public unstakeRequests;

    /// @dev ID for the next unstake request.
    uint256 public nextUnstakeRequestId;

    /**
     * @dev Emitted when a user stakes OLAS tokens.
     * @param user Address of the user who staked.
     * @param amount Amount of OLAS tokens staked.
     * @param sigOlasAmount Amount of sigOLAS tokens minted.
     */
    event Stake(address indexed user, uint256 amount, uint256 sigOlasAmount);

    /**
     * @dev Emitted when a user creates an unstake request.
     * @param user Address of the user who created the unstake request.
     * @param amount Amount of sigOLAS tokens to unstake.
     * @param unstakeRequestId ID of the created unstake request.
     */
    event UnstakeRequest(address indexed user, uint256 amount, uint256 unstakeRequestId);

    /**
     * @dev Emitted when a user claims an unstake request.
     * @param user Address of the user who claimed the unstake request.
     * @param unstakeRequestId ID of the claimed unstake request.
     * @param amount Amount of OLAS tokens transferred.
     */
    event ClaimUnstakeRequest(address indexed user, uint256 unstakeRequestId, uint256 amount);

    /**
     * @dev Emitted when the admin address is updated.
     * @param newAdmin Address of the new admin.
     */
    event AdminUpdated(address indexed newAdmin);

    /**
     * @dev Emitted when the relayer address is updated.
     * @param newRelayer Address of the new relayer.
     */
    event RelayerUpdated(address indexed newRelayer);

    /**
     * @dev Emitted when the treasury address is updated.
     * @param newTreasury Address of the new treasury.
     */
    event TreasuryUpdated(address indexed newTreasury);

    /**
     * @dev Emitted when the emergency treasury address is updated.
     * @param newEmergencyTreasury Address of the new emergency treasury.
     */
    event EmergencyTreasuryUpdated(address indexed newEmergencyTreasury);

    /**
     * @dev Emitted when the hosting protocol address is updated.
     * @param newHostingProtocol Address of the new hosting protocol.
     */
    event HostingProtocolUpdated(address indexed newHostingProtocol);

    /**
     * @dev Emitted when the maximum threshold for non-staked OLAS tokens is updated.
     * @param newMaxThreshold The new maximum threshold.
     */
    event MaxThresholdUpdated(uint256 newMaxThreshold);

    /**
     * @dev Emitted when an unstake request is updated.
     * @param unstakeRequestId ID of the unstake request.
     * @param amountStored Amount of non-staked OLAS tokens used.
     * @param amountTransferred Amount of tokens transferred to the contract.
     * @param amountFilled Amount of the unstake request filled.
     */
    event UnstakeRequestUpdated(uint256 indexed unstakeRequestId, uint256 amountStored, uint256 amountTransferred, uint256 amountFilled);

    /**
     * @dev Emitted when rewarded OLAS tokens are added to the contract.
     * @param amount Total amount of rewarded OLAS tokens.
     * @param rewardFee Total reward fee deducted.
     * @param treasuryAmount Amount transferred to the treasury.
     * @param emergencyTreasuryAmount Amount transferred to the emergency treasury.
     */
    event RewardedOlasAdded(uint256 amount, uint256 rewardFee, uint256 treasuryAmount, uint256 emergencyTreasuryAmount);

    error OnlyAdmin();
    error OnlyRelayer();
    error InvalidAddress();
    error InvalidUnstakeRequestId();
    error UnstakeRequestFulfilled();
    error NotOwnerOfUnstakeRequest();
    error UnstakeRequestNotFulfilled();
    error InsufficientOlasBalance();
    error AllowanceNotSet();
    error TreasuryBalanceNotZero();
    error EmergencyTreasuryBalanceNotZero();
    error InsufficientSigOlasBalance();
    error InsufficientOlasStaked();

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyRelayer() {
        if (msg.sender != relayer) {
            revert OnlyRelayer();
        }
        _;
    }

    modifier onlyAdminOrRelayer() {
        if (msg.sender != admin && msg.sender != relayer) {
            revert OnlyAdminOrRelayer();
        }
        _;
    }

    /**
     * @dev Constructor initializes the contract with the specified parameters.
     * @param _olasToken Address of the OLAS token contract.
     * @param _admin Address of the admin.
     * @param _relayer Address of the relayer.
     * @param _treasury Address of the treasury.
     * @param _emergencyTreasury Address of the emergency treasury.
     * @param _hostingProtocol Address of the hosting protocol.
     * @param _maxThreshold Maximum threshold for non-staked OLAS tokens.
     */
    constructor(
        address _olasToken,
        address _admin,
        address _relayer,
        address _treasury,
        address _emergencyTreasury,
        address _hostingProtocol,
        uint256 _maxThreshold
    ) ERC20("SigOlas", "sigOLAS") {
        if (
            _olasToken == address(0) ||
            _admin == address(0) ||
            _relayer == address(0) ||
            _treasury == address(0) ||
            _emergencyTreasury == address(0) ||
            _hostingProtocol == address(0)
        ) {
            revert InvalidAddress();
        }
        olasToken = IERC20(_olasToken);
        admin = _admin;
        relayer = _relayer;
        treasury = _treasury;
        emergencyTreasury = _emergencyTreasury;
        hostingProtocol = _hostingProtocol;
        maxThreshold = _maxThreshold;
        nextUnstakeRequestId = 1;
    }

    /**
     * @dev Sets the admin address.
     * @param _admin Address of the new admin.
     */
    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) {
            revert InvalidAddress();
        }
        admin = _admin;
        emit AdminUpdated(_admin);
    }

    /**
     * @dev Sets the relayer address.
     * @param _relayer Address of the new relayer.
     */
    function setRelayer(address _relayer) external onlyAdmin {
        if (_relayer == address(0)) {
            revert InvalidAddress();
        }
        relayer = _relayer;
        emit RelayerUpdated(_relayer);
    }

    /**
     * @dev Sets the treasury address.
     * @param _treasury Address of the new treasury.
     */
    function setTreasury(address _treasury) external onlyAdmin {
        if (_treasury == address(0)) {
            revert InvalidAddress();
        }
        if (treasury != address(0) && balanceOf(treasury) != 0) {
            revert TreasuryBalanceNotZero();
        }
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @dev Sets the emergency treasury address.
     * @param _emergencyTreasury Address of the new emergency treasury.
     */
    function setEmergencyTreasury(address _emergencyTreasury) external onlyAdmin {
        if (_emergencyTreasury == address(0)) {
            revert InvalidAddress();
        }
        if (emergencyTreasury != address(0) && balanceOf(emergencyTreasury) != 0) {
            revert EmergencyTreasuryBalanceNotZero();
        }
        emergencyTreasury = _emergencyTreasury;
        emit EmergencyTreasuryUpdated(_emergencyTreasury);
    }

    /**
     * @dev Sets the hosting protocol address.
     * @param _hostingProtocol Address of the new hosting protocol.
     */
    function setHostingProtocol(address _hostingProtocol) external onlyAdmin {
        if (_hostingProtocol == address(0)) {
            revert InvalidAddress();
        }
        hostingProtocol = _hostingProtocol;
        emit HostingProtocolUpdated(_hostingProtocol);
    }

    /**
     * @dev Updates the maximum threshold of non-staked OLAS tokens.
     * @param newMaxThreshold The new maximum threshold.
     */
    function updateMaxThreshold(uint256 newMaxThreshold) external onlyAdmin {
        maxThreshold = newMaxThreshold;
        emit MaxThresholdUpdated(newMaxThreshold);
    }

    /**
     * @dev Stakes a specified amount of OLAS tokens and mints corresponding sigOLAS tokens.
     * @param amount Amount of OLAS tokens to stake.
     */
    function stakeToken(uint256 amount) external {
        if (olasToken.balanceOf(msg.sender) < amount) {
            revert InsufficientOlasBalance();
        }
        if (olasToken.allowance(msg.sender, address(this)) < amount) {
            revert AllowanceNotSet();
        }

        uint256 sigOlasAmount = amount * (olasStaked + DENOMINATOR) / (totalSupply() + olasStaked);

        olasStaked += amount;
        olasToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, sigOlasAmount);

        emit Stake(msg.sender, amount, sigOlasAmount);
    }

    /**
     * @dev Creates an unstake request.
     * @param amount Amount of sigOLAS tokens to unstake.
     */
    function unstakeRequest(uint256 amount) external {
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientSigOlasBalance();
        }

        uint256 unstakeRequestId = nextUnstakeRequestId++;
        unstakeRequests[unstakeRequestId] = UnstakeRequestInfo(msg.sender, false, uint128(amount), 0);

        emit UnstakeRequest(msg.sender, amount, unstakeRequestId);
    }

    /**
     * @dev Updates an unstake request by filling it with available tokens.
     * @param unstakeRequestId ID of the unstake request.
     * @param amountStored Amount of non-staked OLAS tokens used.
     * @param amountTransferred Amount of tokens transferred to the contract.
     */
    function updateUnstakeRequest(uint256 unstakeRequestId, uint256 amountStored, uint256 amountTransferred) external onlyAdminOrRelayer {
        UnstakeRequestInfo storage request = unstakeRequests[unstakeRequestId];
        if (request.user == address(0)) {
            revert InvalidUnstakeRequestId();
        }
        if (request.amountFilled >= request.amount) {
            revert UnstakeRequestFulfilled();
        }

        uint256 amountToFill = request.amount - request.amountFilled;

        if (amountTransferred > 0) {
            olasToken.safeTransferFrom(msg.sender, address(this), amountTransferred);
        }

        uint256 totalAmount = amountTransferred + amountStored;
        uint256 amountToTransfer = totalAmount < amountToFill ? totalAmount : amountToFill;

        if (amountToTransfer > amountStored) {
            olasToken.safeTransfer(request.user, amountToTransfer - amountStored);
        }

        request.amountFilled += uint128(amountToTransfer);

        if (request.amountFilled >= request.amount) {
            request.isClaimed = true;
        }

        emit UnstakeRequestUpdated(unstakeRequestId, amountStored, amountTransferred, request.amountFilled);
    }

    /**
     * @dev Claims an unstake request.
     * @param unstakeRequestId ID of the unstake request.
     */
    function claimUnstakeRequest(uint256 unstakeRequestId) external {
        UnstakeRequestInfo storage request = unstakeRequests[unstakeRequestId];
        if (request.user != msg.sender) {
            revert NotOwnerOfUnstakeRequest();
        }
        if (!request.isClaimed) {
            revert UnstakeRequestNotFulfilled();
        }

        uint256 olasAmount = request.amount * olasStaked / (totalSupply() + DENOMINATOR);

        olasStaked -= olasAmount;
        _burn(msg.sender, request.amount);

        olasToken.safeTransfer(request.user, olasAmount);

        emit ClaimUnstakeRequest(msg.sender, unstakeRequestId, olasAmount);
    }

    /**
     * @dev Locks a specified amount of OLAS tokens and transfers them to the relayer.
     * @param amount Amount of OLAS tokens to lock.
     */
    function lockStaking(uint256 amount) external onlyRelayer {
        if (olasStaked < amount) {
            revert InsufficientOlasStaked();
        }
        olasStaked -= amount;
        olasToken.safeTransfer(relayer, amount);
    }

    /**
     * @dev Puts rewarded OLAS tokens into the contract, deducting fees for treasury and emergency treasury.
     * @param amount Amount of OLAS tokens rewarded.
     */
    function putRewardedOlas(uint256 amount) external onlyAdminOrRelayer {
        uint256 rewardFee = amount * REWARD_FEE_PERCENTAGE / DENOMINATOR;
        uint256 treasuryAmount = rewardFee * treasuryFeePercentage / REWARD_FEE_PERCENTAGE;
        uint256 emergencyTreasuryAmount = rewardFee * emergencyTreasuryFeePercentage / REWARD_FEE_PERCENTAGE;

        olasToken.safeTransferFrom(msg.sender, address(this), amount);
        olasToken.safeTransfer(treasury, treasuryAmount);
        olasToken.safeTransfer(emergencyTreasury, emergencyTreasuryAmount);

        olasStaked += amount - rewardFee;

        emit RewardedOlasAdded(amount, rewardFee, treasuryAmount, emergencyTreasuryAmount);
    }
}
