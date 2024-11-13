// contracts/UniswapV2LiquidityProvider.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IUniswapV2LiquidityProvider.sol";
import "../factory/IUniswapV2Factory.sol";
import "../pair/IUniswapV2Pair.sol";
import "../tokens/IERC20.sol";
import "../utils/Math.sol";
/**
 * @title UniswapV2LiquidityProvider
 * @dev 流动性提供者合约实现
 */
contract UniswapV2LiquidityProvider is IUniswapV2LiquidityProvider {
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

    // 防止过期交易的修饰器
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        _;
    }

    /**
     * @dev 安全转账函数
     */
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    /**
     * @dev 添加流动性
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
    ) external override ensure(deadline) returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    ) {
        // 获取或创建配对合约
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }

        // 获取当前储备量
        (uint256 reserveA, uint256 reserveB) = _getReserves(tokenA, tokenB);

        // 计算最优添加数量
        if (reserveA == 0 && reserveB == 0) {
            // 首次添加流动性
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 后续添加流动性，计算最优数量
            uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "UniswapV2: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired, "UniswapV2: EXCESSIVE_A_AMOUNT");
                require(amountAOptimal >= amountAMin, "UniswapV2: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        // 转移代币到配对合约
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);

        // 铸造流动性代币
        liquidity = IUniswapV2Pair(pair).mint(to);

        emit LiquidityAdded(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            liquidity
        );
    }

    /**
     * @dev 计算添加流动性的精确数量
     */
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view override returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    ) {
        // 获取当前储备量
        (uint256 reserveA, uint256 reserveB) = _getReserves(tokenA, tokenB);

        // 计算最优添加数量
        if (reserveA == 0 && reserveB == 0) {
            // 首次添加流动性
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - 1000; // 减去最小流动性
        } else {
            // 后续添加流动性，计算最优数量
            uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }

            // 计算将获得的流动性代币数量
            address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
            uint256 totalSupply = IERC20(pair).totalSupply();
            liquidity = Math.min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }
    }

    /**
     * @dev 获取配对合约的储备量
     */
    function _getReserves(
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            return (0, 0);
        }
        
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA < tokenB 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);
    }

    /**
     * @dev 根据储备量计算另一个代币的最优数量
     */
    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
}