// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IUniswapV2Pair.sol";

/**
 * @title UniswapV2Pair
 * @dev 最小化的配对合约实现，完整功能将在关卡3实现
 */
contract UniswapV2Pair is IUniswapV2Pair {
    // 代币地址
    address public override token0;
    address public override token1;

    // 防止重复初始化
    bool private initialized;

    /**
     * @dev 初始化函数，只能调用一次
     * @param _token0 代币0地址
     * @param _token1 代币1地址
     */
    function initialize(address _token0, address _token1) external override {
        // 确保只能初始化一次
        require(!initialized, "UniswapV2: ALREADY_INITIALIZED");
        require(_token0 != address(0) && _token1 != address(0), "UniswapV2: ZERO_ADDRESS");
        token0 = _token0;
        token1 = _token1;
        initialized = true;
    }
}