// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    /**
     * @dev 初始化配对合约
     * @param _token0 代币0地址
     * @param _token1 代币1地址
     */
    function initialize(address _token0, address _token1) external;

    /**
     * @dev 获取代币0地址
     */
    function token0() external view returns (address);

    /**
     * @dev 获取代币1地址
     */
    function token1() external view returns (address);
}