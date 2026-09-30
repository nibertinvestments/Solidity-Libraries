pragma solidity ^0.8.24;

contract Web3LibraryDatabase {
    error Web3LibraryDatabase__Unauthorized();
    error Web3LibraryDatabase__InvalidLibrary();

    struct LibraryRecord {
        string name;
        string category;
        string version;
        string description;
        address implementation;
        bool active;
        uint256 createdAt;
        uint256 updatedAt;
    }

    address public owner;
    mapping(string => LibraryRecord) private _libraries;
    mapping(string => bool) private _registered;
    string[] private _libraryNames;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3LibraryDatabase__Unauthorized();
        _;
    }

    function registerLibrary(
        string calldata name,
        string calldata category,
        string calldata version,
        string calldata description,
        address implementation,
        bool active
    ) external onlyOwner {
        require(bytes(name).length > 0, "Web3LibraryDatabase: name required");
        require(implementation != address(0), "Web3LibraryDatabase: invalid implementation");

        if (!_registered[name]) {
            _libraryNames.push(name);
            _registered[name] = true;
        }

        _libraries[name] = LibraryRecord({
            name: name,
            category: category,
            version: version,
            description: description,
            implementation: implementation,
            active: active,
            createdAt: _registered[name] && _libraries[name].createdAt == 0 ? block.timestamp : _libraries[name].createdAt,
            updatedAt: block.timestamp
        });
    }

    function getLibrary(string calldata name) external view returns (LibraryRecord memory record) {
        if (!_registered[name]) revert Web3LibraryDatabase__InvalidLibrary();
        return _libraries[name];
    }

    function libraryCount() external view returns (uint256) {
        return _libraryNames.length;
    }

    function listLibraries() external view returns (string[] memory names, LibraryRecord[] memory records) {
        names = new string[](_libraryNames.length);
        records = new LibraryRecord[](_libraryNames.length);

        for (uint256 i = 0; i < _libraryNames.length; ++i) {
            string memory name = _libraryNames[i];
            names[i] = name;
            records[i] = _libraries[name];
        }
    }

    function isRegistered(string calldata name) external view returns (bool) {
        return _registered[name];
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Web3LibraryDatabase: zero address");
        owner = newOwner;
    }
}
