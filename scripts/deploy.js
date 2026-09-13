const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const bertdropper = await hre.ethers.deployContract("Bertdropper");

  await bertdropper.waitForDeployment();

  console.log("Bertdropper deployed to " + bertdropper.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
