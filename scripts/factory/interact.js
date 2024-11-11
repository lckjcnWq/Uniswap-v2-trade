const hre = require("hardhat");

async function main() {
    // 获取部署的工厂合约地址
    const FACTORY_ADDRESS = "YOUR_FACTORY_ADDRESS";
    const factory = await hre.ethers.getContractAt("UniswapV2Factory", FACTORY_ADDRESS);

    // 部署两个测试代币
    const ERC20Basic = await hre.ethers.getContractFactory("ERC20Basic");
    const token1 = await ERC20Basic.deploy("Token1", "TK1");
    const token2 = await ERC20Basic.deploy("Token2", "TK2");

    await token1.deployed();
    await token2.deployed();

    console.log("Token1 deployed to:", token1.address);
    console.log("Token2 deployed to:", token2.address);

    // 创建交易对
    console.log("Creating pair...");
    const tx = await factory.createPair(token1.address, token2.address);
    await tx.wait();

    // 获取创建的配对地址
    const pairAddress = await factory.getPair(token1.address, token2.address);
    console.log("Pair created at:", pairAddress);

    // 获取配对数量
    const pairLength = await factory.allPairsLength();
    console.log("Total pairs:", pairLength.toString());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });