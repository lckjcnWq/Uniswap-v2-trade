// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IUniswapV2SwapManager.sol";
import "../interfaces/IUniswapV2LiquidityManager.sol";
import "../interfaces/IUniswapV2LiquidityProvider.sol";
import "../pair/IUniswapV2Pair.sol";
import "../factory/IUniswapV2Factory.sol";
import "../tokens/IERC20.sol";
import "../utils/Math.sol";

/**
 * @title UniswapV2SwapManager
 * @dev 实现代币交换功能
 */
contract UniswapV2SwapManager is IUniswapV2SwapManager {
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
     * @dev 计算交易输出数量
     * 包含 0.3% 手续费
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * 997; // 0.3% 手续费
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev 计算交易输入数量
     * 包含 0.3% 手续费
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @dev 获取所有交易数量
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @dev 获取所有交易数量（反向计算）
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) public view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @dev 执行代币交换（确切输入数量）
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);

        emit Swap(
            msg.sender,
            amounts[0],
            amounts[amounts.length - 1],
            path[0],
            path[path.length - 1],
            to
        );
    }

    /**
     * @dev 执行代币交换（确切输出数量）
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "UniswapV2: EXCESSIVE_INPUT_AMOUNT");
        _safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);

        emit Swap(
            msg.sender,
            amounts[0],
            amounts[amounts.length - 1],
            path[0],
            path[path.length - 1],
            to
        );
    }

    /**
     * @dev 内部函数：获取配对合约的储备量
     */
    function getReserves(
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(
            pairFor(tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /**
     * @dev 内部函数：对代币地址进行排序
     */
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
    }

    /**
     * @dev 内部函数：获取配对合约地址
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "UniswapV2: PAIR_NOT_FOUND");
    }

    /**
     * @dev 内部函数：执行代币交换
     */
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to_ = i < path.length - 2
                ? pairFor(path[i + 1], path[i + 2])
                : to;
            IUniswapV2Pair(pairFor(input, output)).swap(
                amount0Out,
                amount1Out,
                to_,
                new bytes(0)
            );
        }
    }

    /**
     * @dev 内部函数：安全转账
     */
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
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
}