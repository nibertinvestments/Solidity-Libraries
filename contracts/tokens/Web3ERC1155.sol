pragma solidity ^0.8.24;

import "../interfaces/IERC1155.sol";

contract Web3ERC1155 is IERC1155 {
    error Web3ERC1155__InvalidAddress();
    error Web3ERC1155__InvalidAmount();
    error Web3ERC1155__InsufficientBalance();
    error Web3ERC1155__LengthMismatch();
    error Web3ERC1155__InvalidReceiver();
    error Web3ERC1155__Unauthorized();

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        if (account == address(0)) revert Web3ERC1155__InvalidAddress();
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) public view returns (uint256[] memory) {
        if (accounts.length != ids.length) revert Web3ERC1155__LengthMismatch();
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert Web3ERC1155__InvalidAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        if (to == address(0)) revert Web3ERC1155__InvalidAddress();
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert Web3ERC1155__Unauthorized();
        if (_balances[id][from] < amount) revert Web3ERC1155__InsufficientBalance();

        unchecked {
            _balances[id][from] -= amount;
            _balances[id][to] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);
        _ensureERC1155Receiver(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        if (ids.length != amounts.length) revert Web3ERC1155__LengthMismatch();
        if (to == address(0)) revert Web3ERC1155__InvalidAddress();
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert Web3ERC1155__Unauthorized();

        for (uint256 i = 0; i < ids.length; ++i) {
            if (_balances[ids[i]][from] < amounts[i]) revert Web3ERC1155__InsufficientBalance();
            unchecked {
                _balances[ids[i]][from] -= amounts[i];
                _balances[ids[i]][to] += amounts[i];
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _ensureERC1155BatchReceiver(msg.sender, from, to, ids, amounts, data);
    }

    function mint(address to, uint256 id, uint256 amount) internal {
        if (to == address(0)) revert Web3ERC1155__InvalidAddress();
        unchecked {
            _balances[id][to] += amount;
        }
        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function batchMint(address to, uint256[] calldata ids, uint256[] calldata amounts) internal {
        if (to == address(0)) revert Web3ERC1155__InvalidAddress();
        if (ids.length != amounts.length) revert Web3ERC1155__LengthMismatch();
        for (uint256 i = 0; i < ids.length; ++i) {
            unchecked {
                _balances[ids[i]][to] += amounts[i];
            }
        }
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function burn(address from, uint256 id, uint256 amount) internal {
        if (_balances[id][from] < amount) revert Web3ERC1155__InsufficientBalance();
        unchecked {
            _balances[id][from] -= amount;
        }
        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function batchBurn(address from, uint256[] calldata ids, uint256[] calldata amounts) internal {
        if (ids.length != amounts.length) revert Web3ERC1155__LengthMismatch();
        for (uint256 i = 0; i < ids.length; ++i) {
            if (_balances[ids[i]][from] < amounts[i]) revert Web3ERC1155__InsufficientBalance();
            unchecked {
                _balances[ids[i]][from] -= amounts[i];
            }
        }
        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _ensureERC1155Receiver(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 retval) {
                if (retval != IERC1155Receiver.onERC1155Received.selector) {
                    revert Web3ERC1155__InvalidReceiver();
                }
            } catch {
                revert Web3ERC1155__InvalidReceiver();
            }
        }
    }

    function _ensureERC1155BatchReceiver(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 retval) {
                if (retval != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert Web3ERC1155__InvalidReceiver();
                }
            } catch {
                revert Web3ERC1155__InvalidReceiver();
            }
        }
    }
}
