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
    uint public duelAllocationTime;

    uint public bootyExpiry;
    uint private turnsOfPeace;
    
    uint public duelStartTime;
    address public gunslinger1;
    address public gunslinger2;
    uint public gunslinger1ActionHash;
    uint public gunslinger2ActionHash;
    bool public readyForShootout;
    bool public gunslinger1Shoots;
    bool public gunslinger1ActionComplete;
    bool public gunslinger2Shoots;
    bool public gunslinger2ActionComplete;

    enum Outcome {Peace, Gunslinger1Win, Gunslinger2Win, MutualLoss}

    struct Gunslinger {
        string name;
        uint8 duelCount;
        uint bootyClaimed;
        uint inDuel;
    }

    mapping(address => Gunslinger) public gunslingers;

    // struct Duel {
    //     bool isResolved;
    //     address gunslinger1;
    //     address gunslinger2;
    //     uint gunslinger1ActionHash;
    //     uint gunslinger2ActionHash;
    //     bool gunslinger1Action;
    //     bool gunslinger2Action;
    //     Outcome outcome;
    //     uint bootyAmountWon;
    //     uint duelStartTime;
    // }

    // Duel[] public duels;

    event Deployed();
    event Entry(string message);
    event OutcomeMessage(string message);
    event Registration(string message);
    event ReadyForRecoup();



//-----------------------------------------------------------
// Constructor, getters, etc
//-----------------------------------------------------------


    constructor(uint _duelAllocationTime, uint _bootyExpiry, uint _woundedSize, uint _graveyardSize) {
        duelAllocationTime = _duelAllocationTime;
        woundedSize = _woundedSize;
        graveyardSize = _graveyardSize;
        bootyExpiry = _bootyExpiry;

        emit Deployed();
    }


   /***** Getter functions *****/
    function getBooty() public view returns(uint) {
        return address(this).balance / 1 gwei;
    }

    function readyForRecoup() public view returns(bool) {
        return (gunslinger1ActionComplete && gunslinger2ActionComplete);
    }

    function duelExpired() public view returns(bool) {
        return ((duelStartTime != 0) && 
                        (block.timestamp - duelStartTime > duelAllocationTime)
                    );
    }

    /***** End of getter functions *****/


   /***** Shared functions *****/
    function hashAction(bool shoot, string calldata watchword) private view returns(uint actionHash) {
        actionHash = uint(sha256(abi.encodePacked(shoot, watchword, msg.sender)));
    }

    fallback() external payable {}

    receive() external payable {}

    /***** End of shared functions *****/


   /***** Security modifiers *****/
    modifier isRegistered() {
        require(bytes(gunslingers[msg.sender].name).length != 0);
        _;
    }

    modifier isNotRegistered() {
        require(bytes(gunslingers[msg.sender].name).length == 0);
        _;
    }

    modifier isInDuel() {
        require(gunslingers[msg.sender].inDuel != 0);

        _;
    }

    modifier isNotInDuel() {
        require(gunslingers[msg.sender].inDuel == 0);

        _;
    }

    modifier isNotDead() {
        bool isDead = false;
        for (uint i = 0; i < graveyard.length || i < graveyardSize; i++) {
            if (graveyard[graveyard.length - i] == msg.sender)
                isDead = true;
        }
        
        require(!isDead);

        _;
    }

    modifier isFitForAction() {
        require(gunslingers[msg.sender].inDuel == 0);
        require(bytes(gunslingers[msg.sender].name).length != 0);

        bool isDead;
        for (uint i = 0; i < graveyard.length || i < graveyardSize; i++) {
            if (graveyard[graveyard.length - i] == msg.sender)
                isDead = true;
        }
        
        require(!isDead);

        _;
    }

    /***** End of security modifiers *****/



//-----------------------------------------------------------
// Registration
//-----------------------------------------------------------


    /***** Main registration function *****/
    function register(string memory _name) external isNotRegistered {
        require(bytes(_name).length != 0);

        gunslingers[msg.sender].name = _name;

        emit Registration(_name);
    }

    /***** End of main registration function *****/



//-----------------------------------------------------------
// Commit
//-----------------------------------------------------------


   /***** Main commit function *****/
    function commitToDuel(bool shoot, string calldata watchword) external payable isFitForAction {

        require(msg.value >= 1 gwei);

        // if(msg.value >= 5 gwei)
        //     buyItem();   /* for another time. Buy armour, or armour piercing bullets? */

        if (gunslinger1 == address(0)) {
            duelStartTime = block.timestamp;
            gunslinger1 = msg.sender;
            gunslinger1ActionHash = hashAction(shoot, watchword);
            gunslingers[msg.sender].inDuel = 1;

            emit Entry(string(abi.encodePacked(gunslingers[msg.sender].name, " throws down the gauntlet!")));
        } 
        else if (gunslinger2 == address(0)) {
            gunslinger2 = msg.sender;
            gunslinger2ActionHash = hashAction(shoot, watchword);
            gunslingers[msg.sender].inDuel = 1;
            readyForShootout = true;
            emit Entry(string(abi.encodePacked(gunslingers[msg.sender].name, " accepts the duel!")));
        }
        else {
            emit Entry(string(abi.encodePacked(gunslingers[msg.sender].name, " tried to interrupt the duel! Wait your turn!")));
        }
    }

    /***** End of main commit function *****/



//-----------------------------------------------------------
// Action
//-----------------------------------------------------------

    
    /***** Main action function *****/
    function shootout(bool shoot, string calldata watchword) external isInDuel {
        require(readyForShootout);

        if(msg.sender == gunslinger1) {
            require(gunslinger1ActionHash == hashAction(shoot, watchword));
            gunslinger1Shoots = shoot;
            gunslinger1ActionComplete = true;
            if(shoot) {
                hit(gunslinger2);
                turnsOfPeace = 0;
            }
        }
        else if(msg.sender == gunslinger2) {
            require(gunslinger2ActionHash == hashAction(shoot, watchword));
            gunslinger2Shoots = shoot;
            gunslinger2ActionComplete = true;
            if(shoot) {
                hit(gunslinger1);
                turnsOfPeace = 0;
            }
        }

        if (gunslinger1ActionComplete && gunslinger2ActionComplete)
            emit ReadyForRecoup();
    }

    /***** End of main action function *****/


    /***** Extra action functions *****/
    function hit(address gunslinger) internal {
            bool isDead = false;
            for (uint i = 0; i < woundedSize || i < wounded.length; i++) { 
                if (wounded[wounded.length - i] == gunslinger) 
                    isDead == true;
            }
            if (isDead) {
                graveyard.push(gunslinger);
            }
            else {
                wounded.push(gunslinger);
            }
    }

    /***** End of extra action functions *****/



//-----------------------------------------------------------
// Recoup
//-----------------------------------------------------------


    /***** Main recoup function *****/
    function recoup() external isInDuel returns(Outcome outcome){
        
        require(duelExpired() || 
                        (gunslinger1ActionComplete && gunslinger2ActionComplete)
                    );

        if(!gunslinger1ActionComplete)
            punish(gunslinger1);

        if(!gunslinger2ActionComplete) 
            punish(gunslinger2);


        // #1 shoots
        if (gunslinger1Shoots && !gunslinger2Shoots) { 

            // #2 either gets wounded or killed
            pay(gunslinger1);
            reset();

            outcome = Outcome.Gunslinger1Win;
        }

        // #2 shoots
        else if (!gunslinger1Shoots && gunslinger2Shoots) { 

            // #1 either gets wounded or killed
            pay(gunslinger2);
            reset();

            outcome = Outcome.Gunslinger2Win;
        }

        // Both shoot
        else if (gunslinger1Shoots && gunslinger2Shoots) { 

            // Both wounded or killed
            reset();

            outcome = Outcome.MutualLoss;
        }

        // Neither shoot
        else if (!gunslinger1Shoots && !gunslinger2Shoots) { 
            peacefulVictory();
            reset();

           outcome = Outcome.Peace;
        }
    }

    /***** End of main recoup function *****/


    /***** Extra recoup functions *****/
    function pay(address gunslinger) internal {
        gunslingers[gunslinger].bootyClaimed = uint(getBooty() / bootyExpiry);
        payable(gunslinger).transfer(getBooty() / bootyExpiry);
    } 


    function peacefulVictory() internal returns(bool v) {
        turnsOfPeace++;

        if(turnsOfPeace == bootyExpiry) {
            turnsOfPeace = 0;

            payable(gunslinger1).transfer(getBooty() / 2);
            payable(gunslinger2).transfer(getBooty());

            v = true;
        }
    }


    function forceResetDuel() external isRegistered {
        require((duelStartTime != 0) && 
                        (block.timestamp - duelStartTime > (duelAllocationTime + 30 seconds))
                    );

        punish(gunslinger1);
        punish(gunslinger2);

        reset();
    }


    function punish(address gunslinger) internal {
        wounded.push(gunslinger);
        graveyard.push(gunslinger);
    }


    function reset() internal {

        readyForShootout = false;
        duelStartTime = 0;
        gunslinger1ActionComplete = false;
        gunslinger2ActionComplete = false;
        gunslinger1Shoots = false;
        gunslinger2Shoots = false;
        gunslinger1ActionHash = 0;
        gunslinger2ActionHash = 0;
        gunslingers[gunslinger1].inDuel = 0;
        gunslingers[gunslinger2].inDuel = 0;

        gunslinger1 = address(0);
        gunslinger2 = address(0);
    }

    /***** End of extra recoup functions *****/

}