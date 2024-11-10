const hre = require("hardhat");

async function main() {
    console.log("Starting local network...");

    // 获取网络中的账户
    const accounts = await hre.ethers.getSigners();

    console.log("Available accounts:");
    for (const account of accounts) {
        const balance = await account.getBalance();
        console.log(
            account.address,
            "Balance:",
            hre.ethers.utils.formatEther(balance)
        );
    }

    // 部署 UniswapToken 合约
    const UniswapToken = await hre.ethers.getContractFactory("UniswapToken");
    console.log("Deploying UniswapToken...");

    const token = await UniswapToken.deploy();
    await token.deployed();

    console.log("UniswapToken deployed to:", token.address);

    // 铸造一些代币用于测试
    const mintAmount = hre.ethers.utils.parseEther("1000000");
    await token.mint(accounts[0].address, mintAmount);
    console.log("Minted", hre.ethers.utils.formatEther(mintAmount), "tokens to", accounts[0].address);

    // 转一些代币给其他账户用于测试
    const transferAmount = hre.ethers.utils.parseEther("1000");
    await token.transfer(accounts[1].address, transferAmount);
    console.log("Transferred", hre.ethers.utils.formatEther(transferAmount), "tokens to", accounts[1].address);

    // 打印当前状态
    const totalSupply = await token.totalSupply();
    console.log("Total supply:", hre.ethers.utils.formatEther(totalSupply));

    const owner = await token.owner();
    console.log("Contract owner:", owner);

    return { token, accounts };
}

// 如果直接运行此脚本则执行 main
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = main;  // 导出 main 函数供其他脚本使用