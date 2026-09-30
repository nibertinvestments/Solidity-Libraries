pragma solidity ^0.8.24;

contract Web3DynamicNFT {
    error Web3DynamicNFT__NotOwner();
    error Web3DynamicNFT__TokenNotFound();
    error Web3DynamicNFT__Unauthorized();

    struct NFTMetadata {
        string name;
        string description;
        string imageURI;
        mapping(string => string) attributes;
    }

    address public owner;
    uint256 private _tokenCounter = 1;

    mapping(uint256 => address) public tokenOwners;
    mapping(uint256 => NFTMetadata) public tokenMetadata;
    mapping(address => uint256) public balances;

    event MetadataUpdated(uint256 indexed tokenId);
    event TokenMinted(uint256 indexed tokenId, address indexed to);
    event TokenBurned(uint256 indexed tokenId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Web3DynamicNFT__Unauthorized();
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (tokenOwners[tokenId] != msg.sender) revert Web3DynamicNFT__Unauthorized();
        _;
    }

    function mint(address to, string calldata name, string calldata description, string calldata imageURI) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenCounter;
        tokenOwners[tokenId] = to;
        tokenMetadata[tokenId].name = name;
        tokenMetadata[tokenId].description = description;
        tokenMetadata[tokenId].imageURI = imageURI;
        balances[to]++;
        unchecked {
            _tokenCounter++;
        }
        emit TokenMinted(tokenId, to);
        return tokenId;
    }

    function setAttribute(uint256 tokenId, string calldata key, string calldata value) external onlyTokenOwner(tokenId) {
        if (tokenOwners[tokenId] == address(0)) revert Web3DynamicNFT__TokenNotFound();
        tokenMetadata[tokenId].attributes[key] = value;
        emit MetadataUpdated(tokenId);
    }

    function getAttribute(uint256 tokenId, string calldata key) external view returns (string memory) {
        if (tokenOwners[tokenId] == address(0)) revert Web3DynamicNFT__TokenNotFound();
        return tokenMetadata[tokenId].attributes[key];
    }

    function burn(uint256 tokenId) external onlyTokenOwner(tokenId) {
        address owner = tokenOwners[tokenId];
        if (owner == address(0)) revert Web3DynamicNFT__TokenNotFound();

        delete tokenOwners[tokenId];
        delete tokenMetadata[tokenId];
        balances[owner]--;

        emit TokenBurned(tokenId);
    }

    function getMetadata(uint256 tokenId) external view returns (string memory name, string memory description, string memory imageURI) {
        if (tokenOwners[tokenId] == address(0)) revert Web3DynamicNFT__TokenNotFound();
        return (tokenMetadata[tokenId].name, tokenMetadata[tokenId].description, tokenMetadata[tokenId].imageURI);
    }
}
