const hre = require("hardhat");

async function main() {
    console.log("Deploying UniswapV2Factory...");

    // 获取部署账户
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 部署工厂合约
    const UniswapV2Factory = await hre.ethers.getContractFactory("UniswapV2Factory");
    const factory = await UniswapV2Factory.deploy(deployer.address);
    await factory.deployed();

    console.log("UniswapV2Factory deployed to:", factory.address);
    console.log("FeeTo Setter:", await factory.feeToSetter());

    return factory;
}

if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = main;