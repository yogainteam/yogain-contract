# smart-contract

#### Contracts

| Contract           | Description                |
|--------------------|----------------------------|
| **WYOG**           | a wrapped native token YOG |
| **PaymentGateway** | payment gateway contract   |

##### WYOG
This contract is similar to WBNB Contract
##### PaymentGateway
_function payment(uint256 channelId, uint256 invoiceNo, uint256 expiredAt, IERC20 tokenContract, uint256 amount, bytes memory signature)_

The function let user perform a payment by ECR20 in Yogain Ecosystem

_function withdraw(uint256 channelId, uint256 invoiceNo, uint256 expiredAt, address recipient, IERC20 tokenContract, uint256 amount, bytes memory signature)_

The function let user perform an ERC20 withdrawal in Yogain Ecosystem

