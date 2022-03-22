const { ethers } = require("hardhat");

const GAME_ADDRESS = process.env.GAME_ADDRESS;
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");


const account = 0;
// const account = 1;
// const account = 2;



async function main() {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  const accounts = await ethers.getSigners();

 // console.log(await game.getGunslinger(accounts[account].address));

// console.log(await provider.getBalance(accounts[account].address));

//  console.log(await provider.isGunslingerDead(accounts[account].address));

  console.log(await game.getGraveyard());
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
