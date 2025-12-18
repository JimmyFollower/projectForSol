// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyNFT {
    // Token metadata
    string private _name;
    string private _symbol;

    // Token ownership tracking
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token URI storage
    mapping(uint256 => string) private _tokenURIs;
    uint256 private _currentTokenId;

    // Events (compliant with ERC721)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // Main minting function
    function mintNFT(address to, string memory tokenURI) public returns (uint256) {
        require(to != address(0), "Mint to zero address");

        _currentTokenId++;
        uint256 newTokenId = _currentTokenId;

        _balances[to] += 1;
        _owners[newTokenId] = to;
        _tokenURIs[newTokenId] = tokenURI;

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    // ERC721 Standard Functions
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Additional ERC721 Functions (minimal implementation)
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    // Internal helper functions
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_owners[tokenId] != address(0), "Operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("Transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from,uint256 tokenId, bytes calldata data) external returns (bytes4);
}
