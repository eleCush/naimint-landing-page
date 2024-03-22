// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./LibDiamond.sol";

contract TokenFacet is IERC20, IERC20Metadata, Context {
    function diamondStorage() internal pure returns (LibDiamond.DiamondStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function name() public view virtual override returns (string memory) {
        return "NAIMINT Token";
    }

    function symbol() public view virtual override returns (string memory) {
        return "NAIM";
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return diamondStorage().totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return diamondStorage().balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return diamondStorage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = diamondStorage().allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        LibDiamond.DiamondStorage storage ds = diamondStorage();
        uint256 senderBalance = ds.balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ds.balances[sender] = senderBalance - amount;
        }
        ds.balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        diamondStorage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == LibDiamond.contractOwner(), "Only contract owner can mint tokens");
        require(account != address(0), "ERC20: mint to the zero address");

        LibDiamond.DiamondStorage storage ds = diamondStorage();
        ds.totalSupply += amount;
        ds.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        LibDiamond.DiamondStorage storage ds = diamondStorage();
        uint256 accountBalance = ds.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            ds.balances[account] = accountBalance - amount;
        }
        ds.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function initialize() external {
        require(diamondStorage().totalSupply == 0, "TokenFacet: already initialized");
        mint(address(this), 88888 * 10**decimals());
    }
}