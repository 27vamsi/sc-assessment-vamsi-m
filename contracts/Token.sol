pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  mapping(address => mapping(address => uint256)) private _allowance;
  address[] private holders;
  mapping(address => bool) private isHolder;
  mapping(address => uint256) private dividends;

  function _addHolder(address holder) private {
    if (!isHolder[holder] && balanceOf[holder] > 0) {
      isHolder[holder] = true;
      holders.push(holder);
    }
  }

  function _removeHolder(address holder) private {
    if (isHolder[holder] && balanceOf[holder] == 0) {
      isHolder[holder] = false;
      for (uint256 i = 0; i < holders.length; i++) {
        if (holders[i] == holder) {
          holders[i] = holders[holders.length - 1];
          holders.pop();
          break;
        }
      }
    }
  }

  function _updateHolder(address holder) private {
    if (balanceOf[holder] > 0) {
      _addHolder(holder);
    } else {
      _removeHolder(holder);
    }
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowance[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(to != address(0), "Transfer to zero address");
    require(balanceOf[msg.sender] >= value, "Insufficient balance");
    
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    
    _updateHolder(msg.sender);
    _updateHolder(to);
    
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    _allowance[msg.sender][spender] = value;
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(to != address(0), "Transfer to zero address");
    require(balanceOf[from] >= value, "Insufficient balance");
    require(_allowance[from][msg.sender] >= value, "Insufficient allowance");
    
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
    
    _updateHolder(from);
    _updateHolder(to);
    
    return true;
  }

  function mint() external payable override {
    require(msg.value > 0, "Must send ETH to mint");
    
    balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
    totalSupply = totalSupply.add(msg.value);
    
    _addHolder(msg.sender);
  }

  function burn(address payable dest) external override {
    require(balanceOf[msg.sender] > 0, "No balance to burn");
    
    uint256 amount = balanceOf[msg.sender];
    balanceOf[msg.sender] = 0;
    totalSupply = totalSupply.sub(amount);
    
    _removeHolder(msg.sender);
    
    dest.transfer(amount);
  }

  function getNumTokenHolders() external view override returns (uint256) {
    return holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    if (index == 0 || index > holders.length) {
      return address(0);
    }
    return holders[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0, "Must send ETH to record dividend");
    require(totalSupply > 0, "No token holders");
    
    for (uint256 i = 0; i < holders.length; i++) {
      address holder = holders[i];
      uint256 holderBalance = balanceOf[holder];
      if (holderBalance > 0) {
        uint256 share = msg.value.mul(holderBalance).div(totalSupply);
        dividends[holder] = dividends[holder].add(share);
      }
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = dividends[msg.sender];
    require(amount > 0, "No dividend to withdraw");
    
    dividends[msg.sender] = 0;
    dest.transfer(amount);
  }
}

