pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./common/ERC20Payable.sol";
import "./common/Withdrawable.sol";

contract Yogain is ERC20Payable, ERC20Burnable, Withdrawable {
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10 ** 18;

    constructor(string memory name, string memory symbol) public ERC20Payable(name, symbol) {
        _mint(_msgSender(), TOTAL_SUPPLY);
    }
}
