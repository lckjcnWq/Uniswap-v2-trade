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

    // 获取指定代币对的配对地址
    function getPair(address token0, address token1) external view returns (address pair);
    // 获取所有配对地址数量
    function allPairsLength() external view returns (uint256);
    // 创建新的配对
    function createPair(address tokenA, address tokenB) external returns (address pair);
    // 设置收费地址
    function setFeeTo(address) external;
    // 设置收费地址的设置权限
    function setFeeToSetter(address) external;
}
