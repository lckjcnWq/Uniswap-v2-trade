//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;
import './IERC20.sol';

abstract contract ERC20Basic is IERC20{

    //代币名称（Ethereum）
    string private _name;

    //代币符号(比如ETH)
    string private _symbol;

    //代币精度(表示代币的最小单位，通用为18，分割到小数点后面18位)
    uint8 private _decimals;

    //代币的总供应量
    uint256   private _totalSupply;

    //存储每个地址的代币余额
    mapping(address => uint256) private _balances;

    //存储授权信息，记录每个地址授权给其它地址的代币数量
    mapping (address => mapping(address => uint256)) private _allowances; 

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view return (string memory){
        return _name;
    }

    function symbol() public view return (string memory){
        return _symbol;
    }

    function totalSupply() public view override  return (uint256){
        return _totalSupply;
    }

     /**
     * @dev 实现IERC20的balanceOf函数
     * @param account 要查询的账户地址
     * @return 返回账户的代币余额
     */
    function balanceOf(address account) external view override return (uint256) {
        return _balances[account];
    }
}