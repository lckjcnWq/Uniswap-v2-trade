// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/**
 * @title IUniswapV2FlashLoan
 * @dev 闪电贷接口定义
 */
interface IUniswapV2FlashLoan {

     /**
     * @dev 闪电贷回调接口
     * @param sender 调用者地址
     * @param amount0 代币0借出数量
     * @param amount1 代币1借出数量
     * @param data 附加数据
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /**
     * @dev 闪电贷事件
     * @param sender 调用者地址
     * @param recipient 接收者地址
     * @param amount0 代币0数量
     * @param amount1 代币1数量
     */
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );
}
