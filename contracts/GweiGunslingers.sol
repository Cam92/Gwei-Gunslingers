//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract GweiGunslingers {

//-----------------------------------------------------------
// Vars, events, getters, and constructor
//-----------------------------------------------------------
    address[] public graveyard;
    uint public graveyardSize;
    address[] public wounded;
    uint public woundedSize;
    address private gunslinger1;
    bool private gunslinger1WillShoot;
    address private gunslinger2;
    uint public bootyExpiry;
    uint private turnsOfPeace;
    mapping(address => Gunslinger) public gunslingers;

    enum Outcome {Peace, Gunslinger1Win, Gunslinger2Win, MutualLoss}

    struct Gunslinger {
        string name;
        uint8 duelCount;
        uint bootyClaimed;
    }

    event Deployed();
    event Entry(string message);
    event Duel(string message);
    event OutcomeMessage(string message);
    event Registration(string message);

//-----------------------------------------------------------
// Constructor, getters, etc
//-----------------------------------------------------------

    constructor(uint _bootyExpiry, uint _woundedSize, uint _graveyardSize) {
    turnsOfPeace = 0;
    woundedSize = _woundedSize;
    graveyardSize = _graveyardSize;
    bootyExpiry = _bootyExpiry;

    emit Deployed();
    }

    function getBooty() public view returns(uint){
        return address(this).balance / 1 gwei;
    }

    fallback() external payable {}

//-----------------------------------------------------------
// Registration
//-----------------------------------------------------------

    modifier isRegistered() {
        require(bytes(gunslingers[msg.sender].name).length != 0);
        _;
    }

    modifier isNotRegistered() {
        require(bytes(gunslingers[msg.sender].name).length == 0);
        _;
    }


function register(string memory _name) external isNotRegistered {

    gunslingers[msg.sender].name = _name;

    emit Registration(string(abi.encodePacked(_name, " wanders into town")));
}


    function duel(bool shoot) external payable isRegistered {
        bool snuffedIt = false;
        for (uint i = 0; i < graveyard.length || i < graveyardSize; i++) {
            if (graveyard[graveyard.length - i] == msg.sender)
                snuffedIt = true;
        }
        
        require(!snuffedIt);
        require(msg.value == 1 gwei);
        payable(address(this)).transfer(msg.value);

        if (gunslinger1 == address(0)) {
            gunslinger1 = msg.sender;
            gunslinger1WillShoot = shoot;
            emit Entry("A gunslinger throws down the gauntlet!");
        } 
        else if (gunslinger2 == address(0)) {
            gunslinger2 = msg.sender;
            emit Entry("A challenger accepts the duel!");
        //Outcome winner = shootout(shoot);




        }
        else {
            emit Entry("Someone tried to interrupt the duel! Wait your turn!");
        }

    }


//-----------------------------------------------------------
// Action
//-----------------------------------------------------------

    //function shootout(bool gunslinger2WillShoot) private returns(Outcome) {
    function shootout(bool gunslinger2WillShoot) private {

        // #1 shoots
        if (gunslinger1WillShoot && !gunslinger2WillShoot) { 

            // #2 either gets wounded or killed
            hit(gunslinger2);
            pay(gunslinger1);

            //return Outcome.Gunslinger1Win;
        }

        // #2 shoots
        else if (!gunslinger1WillShoot && gunslinger2WillShoot) { 

            // #1 either gets wounded or killed
            hit(gunslinger1);
            pay(gunslinger2);

            //return Outcome.Gunslinger2Win;
        }

        // Both shoot
        else if (gunslinger1WillShoot && gunslinger2WillShoot) { 

            // Both wounded or killed
            hit(gunslinger1);
            hit(gunslinger2);

            //return Outcome.MutualLoss;
        }

        // Neither shoot
        else if (!gunslinger1WillShoot && !gunslinger2WillShoot) { 
            peacefulVictory();

           //return Outcome.Peace;
        }
    }


    function hit(address gunslinger) private {
            bool snuffedIt = false;
            for (uint i = 0; i < woundedSize || i < wounded.length; i++) { 
                if (wounded[wounded.length - i] == gunslinger) 
                    snuffedIt == true;
            }
            if (snuffedIt) {
                graveyard.push(gunslinger);
            }
            else {
                wounded.push(gunslinger);
            }
    }
    

    function pay(address gunslinger) private {
        payable(gunslinger).transfer(getBooty() / bootyExpiry);
    }


    function peacefulVictory() private returns(bool v) {
        turnsOfPeace++;

        if(turnsOfPeace == bootyExpiry) {
            turnsOfPeace = 0;

            payable(gunslinger1).transfer(getBooty() / 2);
            payable(gunslinger2).transfer(getBooty());

            v = true;
        }
    }

}