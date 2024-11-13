// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IUniswapV2LiquidityProvider
 * @dev 流动性提供者接口
 */
interface IUniswapV2LiquidityProvider {
    //流动性事件

     /**
     * @dev 添加流动性事件
     * @param provider 流动性提供者地址
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountA 代币A数量
     * @param amountB 代币B数量
     * @param liquidity 获得的流动性代币数量
     */
    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @dev 添加流动性
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountADesired 期望添加的代币A数量
     * @param amountBDesired 期望添加的代币B数量
     * @param amountAMin 最小接受的代币A数量
     * @param amountBMin 最小接受的代币B数量
     * @param to 接收流动性代币的地址
     * @param deadline 截止时间
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    /**
     * @dev 计算添加流动性需要的精确数量
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountADesired 期望添加的代币A数量
     * @param amountBDesired 期望添加的代币B数量
     */
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
}