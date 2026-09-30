pragma solidity ^0.8.24;

import "../interfaces/IERC721.sol";

contract Web3ERC721 is IERC721 {
    error Web3ERC721__InvalidAddress();
    error Web3ERC721__TokenNotFound();
    error Web3ERC721__NotAuthorized();
    error Web3ERC721__InvalidReceiver();

    string public name;
    string public symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _tokenIdCounter = 1;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert Web3ERC721__InvalidAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert Web3ERC721__TokenNotFound();
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Web3ERC721__NotAuthorized();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert Web3ERC721__TokenNotFound();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert Web3ERC721__InvalidAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert Web3ERC721__InvalidAddress();
        address owner = ownerOf(tokenId);
        if (from != owner) revert Web3ERC721__NotAuthorized();
        if (msg.sender != owner && msg.sender != _tokenApprovals[tokenId] && !isApprovedForAll(owner, msg.sender)) {
            revert Web3ERC721__NotAuthorized();
        }

        _tokenApprovals[tokenId] = address(0);
        unchecked {
            _balances[from]--;
            _balances[to]++;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        _ensureERC721Receiver(from, to, tokenId, "");
    }

    function mint(address to) public returns (uint256) {
        if (to == address(0)) revert Web3ERC721__InvalidAddress();
        uint256 tokenId = _tokenIdCounter;
        _owners[tokenId] = to;
        unchecked {
            _balances[to]++;
        }
        _tokenIdCounter++;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Web3ERC721__NotAuthorized();
        }
        _tokenApprovals[tokenId] = address(0);
        unchecked {
            _balances[owner]--;
        }
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _ensureERC721Receiver(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert Web3ERC721__InvalidReceiver();
                }
            } catch {
                revert Web3ERC721__InvalidReceiver();
            }
        }
    }
}
