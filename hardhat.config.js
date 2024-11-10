require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-gas-reporter");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  // solidity 版本配置
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  // 网络配置
  networks: {
    // Hardhat 本地网络配置
    hardhat: {
      chainId: 31337, // 默认 chainId
      mining: {
        auto: true, // 自动挖矿
        interval: 0 // 立即挖矿
      }
    },
    // Hardhat 本地外部网络
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  },
  // Gas 报告配置
  gasReporter: {
    enabled: true,
    currency: 'USD',
    excludeContracts: [],
    src: "./contracts"
  }
};