// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IUniswapV2LiquidityManager
 * @dev 流动性管理接口，包含移除流动性的功能
 */
interface IUniswapV2LiquidityManager {
    /**
     * @dev 移除流动性事件
     * @param sender 调用者地址
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 移除的流动性数量
     * @param amountA 返还的代币A数量
     * @param amountB 返还的代币B数量
     * @param to 接收代币的地址
     */
    event LiquidityRemoved(
        address indexed sender,
        address indexed tokenA,
        address indexed tokenB,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB,
        address to
    );

    /**
     * @dev 移除流动性
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 要移除的流动性数量
     * @param amountAMin 最少接收的代币A数量
     * @param amountBMin 最少接收的代币B数量
     * @param to 接收代币的地址
     * @param deadline 截止时间
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @dev 查询移除流动性可获得的代币数量
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 要移除的流动性数量
     */
    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);
}