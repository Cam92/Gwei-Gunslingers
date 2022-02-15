const { ethers } = require("ethers");

const GAME_ADDRESS = "";
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider(URL);

async function main(shoot) {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);

  const tx = await game.play(shoot);
  const receipt = await tx.wait();

  console.log(receipt);

  console.log(await game.Entry());
  console.log(await game.Duel());
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
