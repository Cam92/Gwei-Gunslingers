const { ethers } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config();

async function main() {

  const Game = await hre.ethers.getContractFactory("GweiGunslingers");
  const game = await Game.deploy(600000, 3, 2, 2);

  game.on('Deployed', () => {
    console.log("Gwei Gunslingers deployed to: " + game.address);
  });
}

main();
