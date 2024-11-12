// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title UQ112x112
 * @dev 定点数计算库，用于价格累积计算
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    /**
     * @dev 将uint112编码为UQ112x112
     * @param y 要编码的数字
     * @return z 编码后的数字
     */
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    /**
     * @dev 使用UQ112x112除法
     * @param x 被除数
     * @param y 除数
     * @return z 结果
     */
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}