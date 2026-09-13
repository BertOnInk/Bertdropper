// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Bertdropper
 * @dev A batch distribution contract for Ink L2 (ERC20, ERC721, ERC1155, and Native ETH)
 * @author InkDropper
 */

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Bertdropper {
    
    // --- NATIVE ASSET (ETH/BERT) ---

    /**
     * @notice Distribute native ETH/BERT to multiple recipients
     * @param recipients Array of recipient addresses
     * @param values Array of amounts for each recipient
     */
    function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
        require(recipients.length == values.length, "Bertdropper: Array mismatch");
        
        // Calculate exact total needed first
        uint256 total = 0;
        for (uint256 i = 0; i < values.length; i++) {
            total += values[i];
        }
        
        // Ensure user sent enough
        require(msg.value >= total, "Bertdropper: Insufficient value sent");

        // Distribute
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: values[i]}("");
            require(success, "Bertdropper: ETH transfer failed");
        }
        
        // Refund only the specific change from THIS transaction
        uint256 change = msg.value - total;
        if (change > 0) {
            (bool success, ) = msg.sender.call{value: change}("");
            require(success, "Bertdropper: Refund failed");
        }
    }

    // --- ERC20 ---

    /**
     * @notice Distribute ERC20 tokens to multiple recipients
     * @dev Requires approve() from msg.sender first
     * @param token The ERC20 token contract address
     * @param recipients Array of recipient addresses
     * @param values Array of amounts for each recipient
     */
    function disperseERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        require(recipients.length == values.length, "Bertdropper: Array mismatch");

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }

        // Pull total amount first (Gas optimization + Safety)
        require(token.transferFrom(msg.sender, address(this), total), "Bertdropper: TransferFrom failed");

        // Distribute
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]), "Bertdropper: Transfer failed");
        }
    }

    // --- ERC721 (NFTs) ---

    /**
     * @notice Distribute ERC721 NFTs to multiple recipients
     * @dev Requires setApprovalForAll() or approve() from msg.sender
     * @param token The ERC721 contract address
     * @param recipients Array of recipient addresses
     * @param tokenIds Array of Token IDs to send (one per recipient)
     */
    function disperseERC721(IERC721 token, address[] calldata recipients, uint256[] calldata tokenIds) external {
        require(recipients.length == tokenIds.length, "Bertdropper: Array mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    // --- ERC1155 (Semi-Fungible / Editions) ---

    /**
     * @notice Distribute ERC1155 tokens to multiple recipients
     * @dev Requires setApprovalForAll() from msg.sender
     * @param token The ERC1155 contract address
     * @param recipients Array of recipient addresses
     * @param ids Array of Token IDs to send (one per recipient)
     * @param values Array of amounts to send to each recipient
     */
    function disperseERC1155(IERC1155 token, address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values) external {
        require(recipients.length == ids.length && ids.length == values.length, "Bertdropper: Array mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], ids[i], values[i], "");
        }
    }
}