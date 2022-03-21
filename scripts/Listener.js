const { ethers } = require("hardhat");
const GAME_ADDRESS = process.env.GAME_ADDRESS;
const hre = require("hardhat");
require('dotenv').config();
let game;

main();

async function main() {
  game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  console.log('Listening to ' + game.address + '...');

  registrationListener();
  entryListener();
  gunslingerActionListener();
  woundedListener();
  killedListener();
  readyForConsequencesListener();
  outcomeMessageListener();
  forceResetDuelListener();
  punishListener();
  resetListener();
  peacefulVictoryListener();
}

async function registrationListener() {
  game.on('Registration', (name) => {
    console.log(name, " wanders into town!");
  });
}

async function entryListener() {
  game.on('Entry', (entry) => {
    console.log(entry);
  });
}

async function gunslingerActionListener() {
  game.on('GunslingerAction', (name, shoots) => {
    if(shoots)
      console.log(name + " shoots!");
    else
      console.log(name + " holds their fire.")
  });
}

async function woundedListener() {
  game.on('Wounded', (name) => {
    console.log(name, " has been wounded!");
  });
}

async function killedListener() {
  game.on('Killed', (name) => {
    console.log(name, " has been killed!");
  });
}

async function readyForConsequencesListener() {
  game.on('ReadyForConsequences', () => {
    console.log("The dust has settled, and the gunslingers can face the consequences...");
  });
}

async function outcomeMessageListener() {
  game.on('OutcomeMessage', (gunslinger1, gunslinger2, outcome) => {
    console.log("The outcome of the duel:");

    switch(outcome) {
      case 0:
        console.log(gunslinger1 + " and " + gunslinger2 + " have peacefully concluded the duel. Phew!");
        break;
      case 1:
        console.log(gunslinger1 + " wins the duel!");
        break;
      case 2:
        console.log(gunslinger2 + " wins the duel!");
        break;
      case 3:
        console.log(gunslinger1 + " and " + gunslinger2 + " have both lost the duel. I don't know what they were expecting really.");
        break;
    }
  });
}

async function forceResetDuelListener() {
  game.on('ForceResetDuel', (resetter) => {
    console.log(resetter + " has forced a reset of the duel!");
  });
}

async function punishListener() {
  game.on('Punish', (gunslinger) => {
    console.log(gunslinger + " has been punished for being tardy!");
  });
}

async function resetListener() {
  game.on('Reset', () => {
    console.log("The town is quiet once more...");
  });
}

async function peacefulVictoryListener() {
  game.on('PeacefulVictory', (gunslinger1, gunslinger2, booty) => {
    console.log(gunslinger1 + " and " + gunslinger2 + " have secured a peaceful victory! They will share the booty of " + booty + " gwei.");
  });
}