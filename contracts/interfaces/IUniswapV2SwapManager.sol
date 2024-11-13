// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IUniswapV2SwapManager
 * @dev Uniswap V2交易管理接口
 */
interface IUniswapV2SwapManager {
    /**
     * @dev 交易事件
     * @param sender 交易发起者
     * @param amountIn 输入代币数量
     * @param amountOut 输出代币数量
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param to 接收地址
     */
    event Swap(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        address indexed tokenIn,
        address indexed tokenOut,
        address to
    );

    /**
     * @dev 计算交易输出数量
     * @param amountIn 输入数量
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountOut 输出数量
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    /**
     * @dev 计算交易输入数量
     * @param amountOut 期望输出数量
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountIn 需要的输入数量
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    /**
     * @dev 执行代币交换
     * @param amountIn 确切的输入数量
     * @param amountOutMin 最小输出数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 截止时间
     * @return amounts 交易数量数组
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @dev 执行代币交换（指定输出数量）
     * @param amountOut 确切的输出数量
     * @param amountInMax 最大输入数量
     * @param path 交易路径
     * @param to 接收地址
     * @param deadline 截止时间
     * @return amounts 交易数量数组
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}