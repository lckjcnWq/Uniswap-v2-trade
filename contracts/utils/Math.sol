// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Math
 * @dev 数学库，提供一些常用的数学函数
 */
library Math {

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /**
     * @dev 计算一个数的平方根，使用牛顿迭代法
     * @param y 要计算平方根的数
     * @return z 平方根结果
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
