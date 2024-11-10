// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    
    // 当代币从一个账户转移到另一个账户时触发
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 当一个账户授权另一个账户使用其代币时触发
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // 返回代币的总供应量
    function totalSupply() external view returns (uint256);

    // 返回指定账户的代币余额
    function balanceOf(address account) external view returns (uint256);

    // 向指定地址转账代币
    function transfer(address to, uint256 value) external returns (bool);

    // 返回授权额度
    function allowance(address owner, address spender) external view returns (uint256);

    // 授权指定地址使用代币
    function approve(address spender, uint256 value) external returns (bool);

    // 通过授权转账代币
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
