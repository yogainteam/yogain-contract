pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Withdrawable is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    event ERC20Withdrawal(IERC20 token, address recipient, uint256 amount);

    event ERC721Withdrawal(IERC721 nft, address recipient, uint256 tokenId);

    event ERC1155Withdrawal(IERC1155 nft, address recipient, uint256 tokenId, uint256 amount);

    event NativeTokenWithdrawal(address recipient, uint256 amount);

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /**
     * @dev Initializes the role for contract owner.
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAWER_ROLE, _msgSender());
    }

    /**
     * @notice Withdraws any tokens ERC20 in the contract.
     */
    function withdrawERC20(IERC20 token, address recipient, uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
        token.safeTransfer(recipient, amount);
        emit ERC20Withdrawal(token, recipient, amount);
    }

    /**
     * @notice Withdraws any nft ERC721 in the contract.
     */
    function withdrawERC721(IERC721 nft, address recipient, uint256 tokenId) external onlyRole(WITHDRAWER_ROLE) {
        nft.safeTransferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawal(nft, recipient, tokenId);
    }

    /**
     * @notice Withdraws any nft ERC1155 in the contract.
     */
    function withdrawERC1155(IERC1155 nft, address recipient, uint256 tokenId, uint256 amount, bytes calldata data) external onlyRole(WITHDRAWER_ROLE) {
        nft.safeTransferFrom(address(this), recipient, tokenId, amount, data);
        emit ERC1155Withdrawal(nft, recipient, tokenId, amount);
    }

    function withdrawNativeToken(address payable recipient, uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
        recipient.sendValue(amount);
        emit NativeTokenWithdrawal(recipient, amount);
    }
}
