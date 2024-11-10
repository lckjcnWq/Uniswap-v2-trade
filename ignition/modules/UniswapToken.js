const hre = require("hardhat");
async function main() {
    //获取合约工厂
    const UniswapToken = await hre.ethers.getContractFactory("UniswapToken");

    console.log("Deploying UniswapToken...");

    //部署合约
    const token = await UniswapToken.deploy();
    await token.deployed();
    console.log("UniswapToken deployed to:", token.address);

    //验证合约部署
    console.log("Verifying contract...");
    await hre.run("verify:verify", {
      address: token.address,
      constructorArguments: [],
    });
    //铸造初始代币
    const [deployer] =await hre.ethers.getSigners;
    const mintAmount  = hre.ethers.utils.parseEther("1000000") //铸造100万代币
    await token.mint(deployer.address, mintAmount);
    console.log("Minted initial tokens to:", deployer.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });