/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../proxy/Clones.sol";
import "../access/AccessControl.sol";

/**
 *
 * @title PayableFactory                                     *
 *                                                           *
 * @notice Clone factory pattern contract                    *
 *                                                           *
 * @custom:security-contact tech@ninfa.io                    *
 *
 */
contract CuratedFactory is AccessControl {
    using Clones for address;

    /**
     * @dev MINTER_ROLE is needed for deploying new instances of the whitelisted collections,
     * it is equivalent to a whitelist of allowed deployers, it can be set by the CURATOR_ROLE or made payable by
     * derived contracts
     */
    bytes32 internal constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE");
    /**
     * @dev CURATOR_ROLE is needed particularly for the curated factory derived contract, in order for already
     * whitelisted minters (MINTER_ROLE),
     * to be able to whitelist other minters, e.g. a gallery whitelisting artists, without having to pay in order to
     * whitelist them,
     * by using off-chain signatures and delegating the task to a backend service (using a CURATOR_ROLE private key).
     * This minimizes security risks by not having to expose the admin private key to the backend service.
     */
    bytes32 internal constant CURATOR_ROLE = 0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")

    // whitelisted implementations' addresses; i.e. allowlist of clonable contracts
    mapping(address => bool) internal _masterImplementations;
    // cloned instances' addresses, needed by external contracts for access control
    mapping(address => bool) private _cloneInstances;

    // owner is needed in order to keep a local database of owners to instance addresses; this avoids keeping track of
    // them on-chain via a mapping
    event NewClone(address master, address instance, address owner);

    modifier onlyMasterImplementations(address _instance) {
        require(_masterImplementations[_instance]);
        _;
    }

    function clone(
        address _instance,
        bytes32 _salt,
        bytes calldata _data
    )
        external
        onlyRole(MINTER_ROLE)
        onlyMasterImplementations(_instance)
        returns (address clone_)
    {
        clone_ = _clone(_instance, _salt, _data);
    }

    /**
     * @param _salt _salt is a random number of our choice. generated with
     * https://web3js.readthedocs.io/en/v1.2.11/web3-utils.html#randomhex
     * _salt could also be dynamically calculated in order to avoid duplicate
     * clones and for a way of finding
     * predictable clones if salt the parameters are known, for example:
     * `address _clone =
     * erc1155Minter.cloneDeterministic(†bytes32(keccak256(abi.encode(_name,
     * _symbol,
     * _msgSender))));`
     * @dev "Using the same implementation and salt multiple time will revert,
     * since the clones cannot be cloneed twice
     * at the same address." -
     * https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones-cloneDeterministic-address-bytes32-
     * @param _implementation MUST be one of this factory's whhitelisted collections
     *
     */
    function _clone(address _implementation, bytes32 _salt, bytes calldata _data) internal returns (address clone_) {
        clone_ = _implementation.cloneDeterministic(_salt);

        // bytes4(keccak256('initialize(bytes)')) == 0x439fab91
        (bool success,) = clone_.call(abi.encodeWithSelector(0x439fab91, _data));
        require(success);

        _cloneInstances[clone_] = true;

        emit NewClone(_implementation, clone_, msg.sender);
    }

    /**
     *
     * @notice whitelist or unwhitelist a master implementation
     * @dev external visibility because it is meant to be needed by all derived contracts,
     * i.e. no point in having a public getter for it, to avoid extra code
     * @param _implementation address of the master implementation to whitelist
     * @param _isWhitelisted bool to set the implementation as whitelisted or not
     */
    function setImplementation(address _implementation, bool _isWhitelisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // safety check, expects the master to be deployed before it can be whitelisted
        require(_implementation.code.length > 0);
        _masterImplementations[_implementation] = _isWhitelisted;
    }

    /**
     * @notice needed by other contracts for access control,
     * i.e. a marketplace like contract using this factory as a source of truth for whitelisted collections
     * @param _instance address of the instance to check
     */
    function exists(address _instance) external view returns (bool) {
        return _cloneInstances[_instance];
    }

    /**
     * @notice derived contracts require more than just an owner role, for security and usability reasons
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);
        _grantRole(CURATOR_ROLE, msg.sender);
    }
}
