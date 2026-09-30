const { ethers } = require("hardhat");

async function main() {
  const Web3LibraryDatabase = await ethers.getContractFactory("Web3LibraryDatabase");
  const database = await Web3LibraryDatabase.deploy();
  await database.waitForDeployment();

  console.log("Web3LibraryDatabase deployed to:", await database.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
