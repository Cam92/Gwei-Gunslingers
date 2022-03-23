const { assert, expect } = require("chai");
const { ethers } = require("hardhat");

//-----------------------------------------------------------
// Normal game and registration
//-----------------------------------------------------------
describe("MAIN TESTING SCOPE", function () {

  let game, accounts, watchwords = [ "hoss", "nines", "thunderation" ];

//-----------------------------------------------------------
// Deployment
//-----------------------------------------------------------
  before("Deploying contract with 300000ms expiry, 2 turns until peace, and graveyard/wounded sizes of 1", async function () {
    const Game = await hre.ethers.getContractFactory("GweiGunslingers");
    game = await Game.deploy(300000, 2, 1, 1);
    await game.deployed();
    console.log("Gwei Gunslingers deployed to: " + game.address);
    accounts = await ethers.getSigners();
  })

//-----------------------------------------------------------
// Registration checks
//-----------------------------------------------------------
  describe("Registration", function () {

    it("Should correctly register the three new gunslingers", async function () {
      await game.connect(accounts[0]).register("The Lone Ranger");
      await game.connect(accounts[1]).register("Butch Cassidy");
      await game.connect(accounts[2]).register("Django");

      assert.equal(await game.getGunslingerName(accounts[0].address), "The Lone Ranger");
      assert.equal(await game.getGunslingerName(accounts[1].address), "Butch Cassidy");
      assert.equal(await game.getGunslingerName(accounts[2].address), "Django");
    });

    it("Should not allow an address to register multiple times", async function () {
      await expect(game.connect(accounts[0]).register("The Lone Ranger"))
        .to.be.reverted;
    });

    it("Should not allow an address to register without a name", async function () {
      await expect(game.connect(accounts[0]).register(""))
        .to.be.reverted;
    });
  });

  describe("Game 1 - Gunslinger 2 shoots, 1 doesn't", function () {

    it("Should revert gunslinger not paying 1 gwei or more", async function () {
      await expect(game.connect(accounts[0]).commitToDuel(true, watchwords[0], { value: ethers.utils.parseUnits("0.1", "gwei") }))
        .to.be.reverted;
      await expect(game.connect(accounts[0]).commitToDuel(true, watchwords[0]))
        .to.be.reverted;
    });

    it("Should correctly commit first gunslinger to duel and start the timer", async function () {
      await game.connect(accounts[0]).commitToDuel(false, watchwords[0], { value: ethers.utils.parseUnits("1", "gwei") })

      assert.equal(await game.connect(accounts[0]).gunslinger1(), accounts[0].address);
      await expect(game.connect(accounts[0]).duelStartTime()).to.not.equal(0);
    });

    it("Should correctly commit second gunslinger to duel and set readyForShootout = true", async function () {
      await game.connect(accounts[1]).commitToDuel(true, watchwords[1], { value: ethers.utils.parseUnits("1", "gwei") })

      assert.equal(await game.connect(accounts[0]).gunslinger2(), accounts[1].address);
      assert.equal(await game.connect(accounts[0]).readyForShootout(), true);
    });

    it("Should correctly revert interrupting gunslinger", async function () {
      await expect(game.connect(accounts[3]).commitToDuel(true, watchwords[3], { value: ethers.utils.parseUnits("1", "gwei") }))
        .to.be.reverted;
    });

    it("Should revert if the action hash doesn't match ", async function () {
      await expect(game.connect(accounts[0]).shootout(false, "test"))
        .to.be.reverted;
        await expect(game.connect(accounts[0]).shootout(true, watchwords[0]))
          .to.be.reverted;
    });

    it("Should correctly reveal action and show action complete bool = true", async function () {
      await game.connect(accounts[0]).shootout(false, watchwords[0]);

      assert.equal(await game.connect(accounts[0]).gunslinger1Shoots(), false);
      assert.equal(await game.connect(accounts[0]).gunslinger1ActionComplete(), true);

      await game.connect(accounts[1]).shootout(true, watchwords[1]);
      assert.equal(await game.connect(accounts[0]).gunslinger2Shoots(), true);
      assert.equal(await game.connect(accounts[0]).gunslinger2ActionComplete(), true);
    });

    it("Should correctly wound opposing gunslinger when hit", async function () {
      assert.equal(await game.connect(accounts[0]).isGunslingerWounded(accounts[0].address), true);
      assert.equal(await game.connect(accounts[0]).getGunslingerWoundedCount(accounts[0].address), 1);
      assert.equal(await game.connect(accounts[0]).isGunslingerDead(accounts[0].address), false);
      assert.equal(await game.connect(accounts[0]).getGunslingerDeathCount(accounts[0].address), 0);
    });

    it("Only gunslingers in duel can call consequences()", async function () {
      await expect(game.connect(accounts[3]).consequences())
        .to.be.reverted;
    });

    it("Should pay gunslinger2", async function () {
      const amountBefore = await ethers.provider.getBalance(accounts[1].address);
      await game.connect(accounts[0]).consequences();
      const amountAfter = await ethers.provider.getBalance(accounts[1].address);

      await expect(amountAfter).to.not.equal(amountBefore);
    });

    it("Should reset", async function () {
      assert.equal(await game.connect(accounts[0]).gunslinger1ActionComplete(), false);
      assert.equal(await game.connect(accounts[0]).gunslinger2ActionComplete(), false);
      assert.equal(await game.connect(accounts[0]).readyForShootout(), false);
      assert.equal(await game.connect(accounts[0]).gunslinger1ActionHash(), 0);
      assert.equal(await game.connect(accounts[0]).gunslinger2ActionHash(), 0);
      assert.equal(await game.connect(accounts[0]).duelStartTime(), 0);
      assert.equal(await game.connect(accounts[0]).gunslinger1(), 0);
      assert.equal(await game.connect(accounts[0]).gunslinger2(), 0);

    });




  });

  describe("Game 2 - repeat of game 1, gunslinger 1 killed", function () {

    it("Should kill gunslinger 1", async function () {
      await game.connect(accounts[0]).commitToDuel(false, watchwords[0], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[1]).commitToDuel(true, watchwords[1], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[0]).shootout(false, watchwords[0]);
      await game.connect(accounts[1]).shootout(true, watchwords[1]);
      await game.connect(accounts[0]).consequences();
      
      assert.equal(await game.connect(accounts[0]).isGunslingerDead(accounts[0].address), true);
    });

  })

  describe("Game 3+4 - peaceful victory achieved", function () {

    it("Should not achieve peaceful victory after one game", async function () {
      await game.connect(accounts[2]).commitToDuel(false, watchwords[2], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[1]).commitToDuel(false, watchwords[1], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[2]).shootout(false, watchwords[2]);
      await game.connect(accounts[1]).shootout(false, watchwords[1]);
      await game.connect(accounts[2]).consequences();
      
      assert.equal(await game.connect(accounts[0]).turnsOfPeace(), 1);
    });

    it("Should achieve peaceful victory after second game, and reset counter", async function () {
      await game.connect(accounts[2]).commitToDuel(false, watchwords[2], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[1]).commitToDuel(false, watchwords[1], { value: ethers.utils.parseUnits("1", "gwei") })
      await game.connect(accounts[2]).shootout(false, watchwords[2]);
      await game.connect(accounts[1]).shootout(false, watchwords[1]);
      await game.connect(accounts[2]).consequences();
      
      assert.equal(await game.connect(accounts[0]).turnsOfPeace(), 0);
    });

  })


    // it("", async function () {

    // });
});

 