const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Web3 production primitives", function () {
  async function deployToken() {
    const Token = await ethers.getContractFactory("Web3ERC20");
    return Token.deploy("Web3 Test Token", "W3T", 18, 1_000_000);
  }

  it("supports ERC20 transfers and allowances", async function () {
    const [owner, user] = await ethers.getSigners();
    const token = await deployToken();
    await token.transfer(user.address, ethers.parseEther("100"));
    expect(await token.balanceOf(user.address)).to.equal(ethers.parseEther("100"));
    await token.connect(user).approve(owner.address, ethers.parseEther("25"));
    await token.transferFrom(user.address, owner.address, ethers.parseEther("25"));
    expect(await token.allowance(user.address, owner.address)).to.equal(0);
  });

  it("keeps vault balances isolated by depositor", async function () {
    const [owner, user] = await ethers.getSigners();
    const token = await deployToken();
    const Vault = await ethers.getContractFactory("Web3Vault");
    const vault = await Vault.deploy();
    await vault.allowToken(await token.getAddress());
    await token.transfer(user.address, ethers.parseEther("10"));
    await token.connect(user).approve(await vault.getAddress(), ethers.parseEther("10"));
    await vault.connect(user).deposit(await token.getAddress(), ethers.parseEther("10"));
    expect(await vault.tokenBalances(await token.getAddress(), user.address)).to.equal(ethers.parseEther("10"));
    expect(await vault.tokenBalances(await token.getAddress(), owner.address)).to.equal(0);
  });

  it("enforces the timelock before execution", async function () {
    const [owner] = await ethers.getSigners();
    const Timelock = await ethers.getContractFactory("Web3Timelock");
    const timelock = await Timelock.deploy();
    await timelock.setLockPeriod(3600);
    const hash = await timelock.queueTransaction.staticCall(owner.address, 0, "0x");
    await timelock.queueTransaction(owner.address, 0, "0x");
    await expect(timelock.executeTransaction(hash)).to.be.revertedWithCustomError(timelock, "Web3Timelock__LockPeriodNotPassed");
  });
});
