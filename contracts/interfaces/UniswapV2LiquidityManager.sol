// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IUniswapV2LiquidityManager.sol";
import "../factory/IUniswapV2Factory.sol";
import "../pair/IUniswapV2Pair.sol";
import "../tokens/IERC20.sol";
import "../utils/Math.sol";

contract UniswapV2LiquidityManager is IUniswapV2LiquidityManager {
    // Uniswap V2 工厂合约地址
    address public immutable factory;
    
    /**
     * @dev 构造函数
     * @param _factory 工厂合约地址
     */
    constructor(address _factory) {
        require(_factory != address(0), "UniswapV2: ZERO_FACTORY_ADDRESS");
        factory = _factory;
    }

    /**
     * @dev 防止过期交易的修饰器
     */
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        _;
    }

    /**
     * @dev 安全的代币转账函数
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    /**
     * @dev 移除流动性
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        // 获取配对地址，确保配对存在
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "UniswapV2: PAIR_NOT_FOUND");

        // 将LP代币转入配对合约
        IERC20(pair).transferFrom(msg.sender, pair, liquidity);

        // 调用配对合约的burn函数销毁LP代币
        (amountA, amountB) = IUniswapV2Pair(pair).burn(to);

        // 确保返还的代币数量满足最小要求
        require(amountA >= amountAMin, "UniswapV2: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "UniswapV2: INSUFFICIENT_B_AMOUNT");

        // 触发移除流动性事件
        emit LiquidityRemoved(
            msg.sender,
            tokenA,
            tokenB,
            liquidity,
            amountA,
            amountB,
            to
        );
    }

    /**
     * @dev 查询移除流动性可获得的代币数量
     */
    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity
    ) external view override returns (uint256 amountA, uint256 amountB) {
        // 获取配对地址
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "UniswapV2: PAIR_NOT_FOUND");

        // 获取当前储备量和总供应量
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 totalSupply = IERC20(pair).totalSupply();
        
        // 确保数据有效
        require(totalSupply > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY");
        
        // 根据流动性代币占比计算可获得的代币数量
        amountA = (liquidity * uint256(reserve0)) / totalSupply;
        amountB = (liquidity * uint256(reserve1)) / totalSupply;
    }
    
    /**
     * @dev 紧急取回误发送的代币
     * @param token 代币地址
     * @param to 接收地址
     */
    function emergencyWithdraw(address token, address to) external {
        require(to != address(0), "UniswapV2: ZERO_ADDRESS");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            _safeTransfer(token, to, balance);
        }
    }
}