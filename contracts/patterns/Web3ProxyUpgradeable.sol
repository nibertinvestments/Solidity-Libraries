pragma solidity ^0.8.24;

contract Web3ProxyUpgradeable {
    error Web3ProxyUpgradeable__NotAdmin();
    error Web3ProxyUpgradeable__InvalidImplementation();
    error Web3ProxyUpgradeable__AlreadyInitialized();

    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 private constant INITIALIZED_SLOT = bytes32(uint256(keccak256("eip1967.proxy.initialized")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address initialImplementation, bytes memory initData) {
        if (initialImplementation == address(0)) revert Web3ProxyUpgradeable__InvalidImplementation();
        if (initialImplementation.code.length == 0) revert Web3ProxyUpgradeable__InvalidImplementation();

        _setAdmin(msg.sender);
        _setImplementation(initialImplementation);

        if (initData.length > 0) {
            _setInitialized();
            (bool success, ) = initialImplementation.delegatecall(initData);
            require(success, "Web3ProxyUpgradeable: initialization failed");
        }
    }

    fallback() external payable { _delegate(_getImplementation()); }
    receive() external payable {}

    function upgradeTo(address newImplementation) external {
        if (msg.sender != _getAdmin()) revert Web3ProxyUpgradeable__NotAdmin();
        if (newImplementation == address(0)) revert Web3ProxyUpgradeable__InvalidImplementation();
        if (newImplementation.code.length == 0) revert Web3ProxyUpgradeable__InvalidImplementation();
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external {
        if (msg.sender != _getAdmin()) revert Web3ProxyUpgradeable__NotAdmin();
        if (newAdmin == address(0)) revert Web3ProxyUpgradeable__InvalidImplementation();
        address previousAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(previousAdmin, newAdmin);
    }

    function getAdmin() external view returns (address) { return _getAdmin(); }
    function getImplementation() external view returns (address) { return _getImplementation(); }

    function _getAdmin() internal view returns (address admin) {
        assembly { admin := sload(ADMIN_SLOT) }
    }

    function _setAdmin(address newAdmin) internal {
        assembly { sstore(ADMIN_SLOT, newAdmin) }
    }

    function _getImplementation() internal view returns (address implementation) {
        assembly { implementation := sload(IMPLEMENTATION_SLOT) }
    }

    function _setImplementation(address newImplementation) internal {
        assembly { sstore(IMPLEMENTATION_SLOT, newImplementation) }
    }

    function _setInitialized() internal {
        assembly { sstore(INITIALIZED_SLOT, 1) }
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
