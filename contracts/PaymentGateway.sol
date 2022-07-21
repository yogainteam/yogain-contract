pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./common/Withdrawable.sol";

contract PaymentGateway is Withdrawable, EIP712 {
    using SafeERC20 for IERC20;

    struct ChannelData {
        address orderSigner;
        address cashier;
        mapping(uint256 => bool) usedInvoices;
    }

    mapping(uint256 => ChannelData) public paymentChannels;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PAYMENT_TYPEHASH =
    keccak256("Payment(uint256 channelId,uint256 invoiceNo,uint256 deadline,IERC20 tokenContract,uint256 amount)");

    bytes32 public immutable _WITHDRAW_TYPEHASH =
    keccak256("Withdraw(uint256 channelId,uint256 invoiceNo,uint256 deadline,IERC20 tokenContract,address recipient,uint256 amount)");

    event PaymentChannelChanged(uint256 indexed channelId, address oldOrderSigner, address oldCashier, address indexed newOrderSigner, address indexed newCashier);

    event Payment(uint256 indexed channelId, uint256 indexed invoiceNo, IERC20 tokenContract, address indexed sender, address recipient, uint256 amount);

    event Withdrawal(uint256 indexed channelId, uint256 indexed invoiceNo, IERC20 tokenContract, address sender, address indexed recipient, uint256 amount);


    bytes32 public constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE");

    constructor(string memory name) EIP712(name, "1") {
        _setupRole(PAYMENT_MANAGER_ROLE, _msgSender());
    }

    function setPaymentChannel(uint256 channelId, address newOrderSigner, address newCashier) external onlyRole(PAYMENT_MANAGER_ROLE) {
        require((newOrderSigner != address(0) && newCashier != address(0))
            || (newOrderSigner == address(0) && newCashier == address(0)), "PaymentGateway: newOrderSigner is address(0) while newCashier is not, and vice versa");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address oldOrderSigner = paymentChannel.orderSigner;
        address oldCashier = paymentChannel.cashier;
        paymentChannel.orderSigner = newOrderSigner;
        paymentChannel.cashier = newCashier;
        emit PaymentChannelChanged(channelId, oldOrderSigner, oldCashier, newOrderSigner, newCashier);
    }

    function payment(uint256 channelId, uint256 invoiceNo, uint256 deadline, IERC20 tokenContract, uint256 amount, bytes memory signature) external {
        require(block.timestamp <= deadline, "PaymentGateway: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "PaymentGateway: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "PaymentGateway: order already paid");

        bytes32 structHash = keccak256(abi.encode(_PAYMENT_TYPEHASH, channelId, invoiceNo, deadline, tokenContract, amount));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "PaymentGateway: invalid signature");

        address sender = _msgSender();
        paymentChannel.usedInvoices[invoiceNo] = true;
        tokenContract.safeTransferFrom(sender, cashier, amount);
        emit Payment(channelId, invoiceNo, tokenContract, sender, cashier, amount);
    }

    function withdraw(uint256 channelId, uint256 invoiceNo, uint256 deadline, IERC20 tokenContract, address recipient, uint256 amount, bytes memory signature) external {
        require(block.timestamp <= deadline, "PaymentGateway: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "PaymentGateway: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "PaymentGateway: order already paid");
        bytes32 structHash = keccak256(abi.encode(_WITHDRAW_TYPEHASH, channelId, invoiceNo, deadline, tokenContract, recipient, amount));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "PaymentGateway: invalid signature");

        paymentChannel.usedInvoices[invoiceNo] = true;
        if (cashier == address(this)) {
            tokenContract.safeTransfer(recipient, amount);
        } else {
            tokenContract.safeTransferFrom(cashier, recipient, amount);
        }
        emit Withdrawal(channelId, invoiceNo, tokenContract, cashier, recipient, amount);
    }

    function isSettled(uint256 channelId, uint256 invoiceNo) external view returns (bool) {
        return paymentChannels[channelId].usedInvoices[invoiceNo];
    }
}
