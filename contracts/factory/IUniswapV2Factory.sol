// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IUniswapV2Factory
 * @dev Uniswap V2工厂合约接口
 */
interface IUniswapV2Factory {
    //创建配对时触发的事件
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairLength);

    //获取收费地址
    function feeTo() external view returns (address);

    //获取收费地址设置者
    function feeToSetter() external view returns (address);
}
