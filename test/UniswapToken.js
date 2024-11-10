const { expect } = require('chai');
const { ethers} = require('hardhat')

describe('UniswapToken', function () {
    let UniswapToken;
    let token;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    before(async function (){
        //获取合约工厂
        UniswapToken = await ethers.getContractFactory("UniswapToken")
        //获取测试账号
        [owner, addr1, addr2] = await ethers.getSigners()
        console.log("owner:", owner.address, addr1.address, addr2.address)
        //部署合约
        token = await UniswapToken.deploy()
        //等待部署完成
        await token.deployed()
    })
})