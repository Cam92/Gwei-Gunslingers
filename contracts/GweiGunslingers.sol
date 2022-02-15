//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


contract Greeter {
    uint private booty;
    address[] private graveyard;
    uint8 private graveyardSize;
    address[] private wounded;
    uint8 private woundedListSize;
    address private gunslinger1;
    bool private gunslinger1WillShoot;
    address private gunslinger2;
    uint8 private bootyExpiry;
    uint8 private turnsOfPeace;

    /*struct Gunslinger {
        address add;
        string name;
        uint8 duelCount;
        bool wounded;
        uint8 woundedCount;
        bool dead;
        uint8 deadCount;
        uint bootyClaimed;
    }*/

    event Deployed();
    event Entry(string message);
    event Duel();

    constructor(uint8 _bootyExpiry, uint8 _woundedListSize, uint8 _graveyardSize) {
    booty = 0;
    turnsOfPeace = 0;
    woundedListSize = _woundedListSize;
    graveyardSize = _graveyardSize;
    bootyExpiry = _bootyExpiry;

    emit Deployed();
    }

    function duel(bool shoot) external payable {
        address[] memory winner;
        bool isDead = false;
        for (uint i = 0; i < graveyard.length; i++) {
            if (graveyard[i] == msg.sender)
                isDead = true;
        }
        
        require(!isDead);
        require(msg.value == 1000000000);
        booty++;

        if (gunslinger1 == address(0)) {
            gunslinger1 = msg.sender;
            gunslinger1WillShoot = shoot;
            emit Entry("A gunslinger is waiting for a duel!");
        } 
        else if (gunslinger2 == address(0)) {
            gunslinger2 = msg.sender;
            emit Entry("A challenger wanders into town!");
            winner = shootout(shoot);

            // Duel completion logic (who gets a slice of the booty, peace counter check, diplomatic victory)




        }
        else {
            emit Entry("Someone tried to interrupt the duel! Wait your turn!");
        }

    }

    function shootout(bool gunslinger2WillShoot) private returns(address[]) {

        address[] winners;
        // #1 shoots
        if (gunslinger1WillShoot && !gunslinger2WillShoot) { 

            // #2 either gets wounded or killed
            hit(gunslinger2);

            // Payout for 1
            return winners.push(gunslinger1);
        }

        // #2 shoots
        else if (!gunslinger1WillShoot && gunslinger2WillShoot) { 

            // #1 either gets wounded or killed
            hit(gunslinger1);

            // Payout for 2
            return winners.push(gunslinger2);
        }

        // Both shoot
        else if (gunslinger1WillShoot && gunslinger2WillShoot) { 

            // Both wounded or killed
            hit(gunslinger1);
            hit(gunslinger2);

            return [];
        }

        // Neither shoot
        else if (!gunslinger1WillShoot && !gunslinger2WillShoot) { 
            return [gunslinger1, gunslinger2];
        }
    }

    function hit(address gunslinger) private {
            bool gunslingerKilled = false;
            for (uint i = 0; i < wounded.length; i++) { 
                if (wounded[i] == gunslinger)
                    gunslingerKilled == true;
            }
            if (gunslingerKilled) {
                graveyard.push(gunslinger);
                if (graveyard.length >= graveyardSize)
                    graveyard[graveyard.length - graveyardSize + 1] == address(0);
            }
            else {
                wounded.push(gunslinger);
                if (wounded.length >= woundedListSize)
                    wounded[graveyard.length - woundedListSize + 1] == address(0);
            }
    }

}
