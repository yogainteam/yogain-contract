pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract ERC20Payable is ERC20, ERC20Permit, AccessControlEnumerable {
    struct ChannelData {
        address orderSigner;
        address cashier;
        mapping(uint256 => bool) usedInvoices;
    }

    mapping(uint256 => ChannelData) public paymentChannels;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant _PAYMENT_TYPEHASH =
    keccak256("Payment(uint256 channelId,uint256 invoiceNo,uint256 amount,uint256 deadline)");

    event PaymentChannelChanged(uint256 indexed channelId, address oldOrderSigner, address oldCashier, address indexed newOrderSigner, address indexed newCashier);

    event Payment(uint256 indexed channelId, uint256 indexed invoiceNo, address indexed sender, address recipient, uint256 amount);

    bytes32 public constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAYMENT_MANAGER_ROLE, _msgSender());
    }

    function setPaymentChannel(uint256 channelId, address newOrderSigner, address newCashier) external onlyRole(PAYMENT_MANAGER_ROLE) {
        require((newOrderSigner != address(0) && newCashier != address(0))
            || (newOrderSigner == address(0) && newCashier == address(0)), "WoM20Payable: newOrderSigner is address(0) while newCashier is not, and vice versa");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address oldOrderSigner = paymentChannel.orderSigner;
        address oldCashier = paymentChannel.cashier;
        paymentChannel.orderSigner = newOrderSigner;
        paymentChannel.cashier = newCashier;
        emit PaymentChannelChanged(channelId, oldOrderSigner, oldCashier, newOrderSigner, newCashier);
    }

    function payment(uint256 channelId, uint256 invoiceNo, uint256 amount, uint256 deadline, bytes memory signature) external {
        require(block.timestamp <= deadline, "WoM20Payable: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "WoM20Payable: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "WoM20Payable: order already paid");

        bytes32 structHash = keccak256(abi.encode(_PAYMENT_TYPEHASH, channelId, invoiceNo, amount, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "WoM20Payable: invalid signature");

        address sender = _msgSender();
        paymentChannel.usedInvoices[invoiceNo] = true;
        _transfer(sender, cashier, amount);
        emit Payment(channelId, invoiceNo, sender, cashier, amount);
    }

    function isSettled(uint256 channelId, uint256 invoiceNo) external view returns (bool) {
        return paymentChannels[channelId].usedInvoices[invoiceNo];
    }
}
