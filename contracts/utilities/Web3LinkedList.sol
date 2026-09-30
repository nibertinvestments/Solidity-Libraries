pragma solidity ^0.8.24;

library Web3LinkedList {
    error Web3LinkedList__NodeNotFound();
    error Web3LinkedList__InvalidOperation();

    struct Node {
        bytes32 next;
        bytes32 prev;
        uint256 value;
    }

    struct LinkedList {
        bytes32 head;
        bytes32 tail;
        mapping(bytes32 => Node) nodes;
        uint256 length;
    }

    function push(LinkedList storage list, bytes32 key, uint256 value) internal {
        if (list.nodes[key].value != 0) revert Web3LinkedList__InvalidOperation();

        Node memory newNode = Node({next: bytes32(0), prev: list.tail, value: value});

        if (list.tail != bytes32(0)) {
            list.nodes[list.tail].next = key;
        } else {
            list.head = key;
        }

        list.nodes[key] = newNode;
        list.tail = key;
        unchecked {
            list.length++;
        }
    }

    function remove(LinkedList storage list, bytes32 key) internal {
        Node storage node = list.nodes[key];
        if (node.value == 0 && list.head != key) revert Web3LinkedList__NodeNotFound();

        if (node.prev != bytes32(0)) {
            list.nodes[node.prev].next = node.next;
        } else {
            list.head = node.next;
        }

        if (node.next != bytes32(0)) {
            list.nodes[node.next].prev = node.prev;
        } else {
            list.tail = node.prev;
        }

        delete list.nodes[key];
        unchecked {
            list.length--;
        }
    }

    function get(LinkedList storage list, bytes32 key) internal view returns (uint256) {
        return list.nodes[key].value;
    }

    function exists(LinkedList storage list, bytes32 key) internal view returns (bool) {
        return list.nodes[key].value != 0 || list.head == key;
    }
}
