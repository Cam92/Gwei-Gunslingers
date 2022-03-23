const { ethers } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config();

async function main() {

  const Game = await hre.ethers.getContractFactory("GweiGunslingers");
  const game = await Game.deploy(300000, 2, 1, 1);
  //const game = await Game.deploy(600000, 10, 3, 2);

  await game.deployed();
  console.log("Gwei Gunslingers deployed to: " + game.address);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
