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
    uint public turnsOfPeace;
    
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
        uint duelCount;
        uint killCount;
        uint bootyClaimed;
        bool inDuel;
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

    event Registration(string);
    event Entry(string);
    event GunslingerAction(string, bool);
    event ReadyForConsequences();
    event OutcomeMessage(string, string, Outcome);
    event ForceResetDuel(string);
    event Punish(string);
    event Reset();
    event Wounded(string);
    event Killed(string);
    event PeacefulVictory(string, string, uint);



//-----------------------------------------------------------
// Constructor, getters, etc
//-----------------------------------------------------------


    constructor(uint _duelAllocationTime, uint _bootyExpiry, uint _woundedSize, uint _graveyardSize) {
        duelAllocationTime = _duelAllocationTime;
        woundedSize = _woundedSize;
        graveyardSize = _graveyardSize;
        bootyExpiry = _bootyExpiry;
    }


   /***** Getter functions *****/
    function getBooty() public view returns(uint) {
        return address(this).balance / 1 gwei;
    }

    function getGunslinger(address gunslinger) public view returns(Gunslinger memory) {
        return gunslingers[gunslinger];
    }

    function getGunslingerName(address gunslinger) public view returns(string memory) {
        return gunslingers[gunslinger].name;
    }

    function readyForConsequences() public view returns(bool) {
        return (gunslinger1ActionComplete && gunslinger2ActionComplete);
    }

    function duelExpired() public view returns(bool) {
        return ((duelStartTime != 0) && 
                        (block.timestamp - duelStartTime > duelAllocationTime)
                    );
    }

    function getGraveyard() public view returns(address[] memory) {
        return graveyard;
    }

    function getGunslingerDeathCount(address gunslinger) public view returns(uint count) {
        for (uint i = 0; i < graveyard.length; i++) {
            if (graveyard[i] == gunslinger)
                count++;
        }
    }

    function isGunslingerDead(address gunslinger) public view returns(bool isDead) {
        uint startingPoint;
        if(graveyard.length < graveyardSize)
            startingPoint = 0;
        else
            startingPoint = (graveyard.length - graveyardSize);


        for (uint i = startingPoint; i < graveyard.length; i++) {
            if (graveyard[i] == gunslinger)
                isDead = true;
        }
    }

    function getWounded() public view returns(address[] memory) {
        return wounded;
    }

    function getGunslingerWoundedCount(address gunslinger) public view returns(uint count) {
        for (uint i = 0; i < wounded.length; i++) {
            if (wounded[i] == gunslinger)
                count++;
        }
    }

    function isGunslingerWounded(address gunslinger) public view returns(bool isWounded) {
        uint startingPoint;
        if(wounded.length < woundedSize)
            startingPoint = 0;
        else
            startingPoint = (wounded.length - woundedSize);

        for (uint i = startingPoint; i < wounded.length; i++) {
            if (wounded[i] == gunslinger)
                isWounded = true;
        }
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
        require(bytes(gunslingers[msg.sender].name).length != 0, "Must register as a gunslinger first!");
        _;
    }

    modifier isNotRegistered() {
        require(bytes(gunslingers[msg.sender].name).length == 0, "You've already registered as a gunslinger!");
        _;
    }

    modifier isInDuel() {
        require(gunslingers[msg.sender].inDuel == true, "Must be in duel!");

        _;
    }

    modifier isNotInDuel() {
        require(gunslingers[msg.sender].inDuel == false, "Must not be in a duel!");

        _;
    }

    modifier isNotDead() {
        require(!isGunslingerDead(msg.sender), "You're currently dead!");

        _;
    }

    // One modifier packaging multiple checks together
    modifier isFitForAction() {
        require(gunslingers[msg.sender].inDuel == false, "Must not be in a duel!");
        require(bytes(gunslingers[msg.sender].name).length != 0, "Must register as a gunslinger first!");
        require(!isGunslingerDead(msg.sender), "You're currently dead!");

        _;
    }

    /***** End of security modifiers *****/



//-----------------------------------------------------------
// Registration
//-----------------------------------------------------------


    /***** Main registration function *****/
    function register(string memory _name) external isNotRegistered {
        require(bytes(_name).length != 0, "Please submit a name!");

        gunslingers[msg.sender].name = _name;

        emit Registration(_name);
    }

    /***** End of main registration function *****/



//-----------------------------------------------------------
// Commit
//-----------------------------------------------------------


   /***** Main commit function *****/
    function commitToDuel(bool shoot, string calldata watchword) external payable isFitForAction {

        require(msg.value >= 1 gwei, "Message value must be 1 gwei or more.");

        // if(msg.value >= 5 gwei)
        //     buyItem();   /* for another time. Buy armour, or armour piercing bullets? */

        if (gunslinger1 == address(0)) {
            duelStartTime = block.timestamp;
            gunslinger1 = msg.sender;
            gunslinger1ActionHash = hashAction(shoot, watchword);
            gunslingers[msg.sender].inDuel = true;
            gunslingers[msg.sender].duelCount++;

            emit Entry(string(abi.encodePacked(gunslingers[msg.sender].name, " throws down the gauntlet!")));
        } 
        else if (gunslinger2 == address(0)) {
            gunslinger2 = msg.sender;
            gunslinger2ActionHash = hashAction(shoot, watchword);
            gunslingers[msg.sender].inDuel = true;
            gunslingers[msg.sender].duelCount++;
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
        require(readyForShootout, "Both gunslingers must be ready for  a shootout!");

        if(msg.sender == gunslinger1) {
            require(!gunslinger1ActionComplete, "You've already completed your part of the shootout!");
            require(gunslinger1ActionHash == hashAction(shoot, watchword), "Your decision or watchword doesn't match what you've committed.");
            gunslinger1Shoots = shoot;
            gunslinger1ActionComplete = true;
            if(shoot) {
                hit(gunslinger2);
                turnsOfPeace = 0;
            }
            emit GunslingerAction(gunslingers[msg.sender].name, shoot);
        }
        else if(msg.sender == gunslinger2) {
            require(!gunslinger2ActionComplete, "You've already completed your part of the shootout!");
            require(gunslinger2ActionHash == hashAction(shoot, watchword), "Your decision or watchword doesn't match what you've committed.");
            gunslinger2Shoots = shoot;
            gunslinger2ActionComplete = true;
            if(shoot) {
                hit(gunslinger1);
                turnsOfPeace = 0;
            }
            emit GunslingerAction(gunslingers[msg.sender].name, shoot);
        }

        if (gunslinger1ActionComplete && gunslinger2ActionComplete)
            emit ReadyForConsequences();
    }

    /***** End of main action function *****/


    /***** Extra action functions *****/
    function hit(address gunslinger) internal {
            if (isGunslingerWounded(gunslinger)) {
                if (gunslinger1 == gunslinger)
                    gunslingers[gunslinger2].killCount++;
                else if (gunslinger2 == gunslinger)
                    gunslingers[gunslinger1].killCount++;
                emit Killed(gunslingers[gunslinger].name);
                graveyard.push(gunslinger);
            }
            else {
                emit Wounded(gunslingers[gunslinger].name);
                wounded.push(gunslinger);
            }
    }

    /***** End of extra action functions *****/



//-----------------------------------------------------------
// Consequences
//-----------------------------------------------------------


    /***** Main consequences function *****/
    function consequences() external isInDuel returns(Outcome outcome){
        
        require(duelExpired() || 
                        (gunslinger1ActionComplete && gunslinger2ActionComplete),
                        "Needs the gunslingers to complete the shootout, or for the duel to expire first!"
                    );

        if(!gunslinger1ActionComplete)
            punish(gunslinger1);

        if(!gunslinger2ActionComplete) 
            punish(gunslinger2);


        // #1 shoots
        if (gunslinger1Shoots && !gunslinger2Shoots) { 

            // #2 either gets wounded or killed
            pay(gunslinger1);
            outcome = Outcome.Gunslinger1Win;
        }

        // #2 shoots
        else if (!gunslinger1Shoots && gunslinger2Shoots) { 

            // #1 either gets wounded or killed
            pay(gunslinger2);
            outcome = Outcome.Gunslinger2Win;
        }

        // Both shoot
        else if (gunslinger1Shoots && gunslinger2Shoots) { 

            // Both wounded or killed
            outcome = Outcome.MutualLoss;
        }

        // Neither shoot
        else if (!gunslinger1Shoots && !gunslinger2Shoots) { 
            peacefulVictory();

           outcome = Outcome.Peace;
        }

        emit OutcomeMessage(gunslingers[gunslinger1].name, gunslingers[gunslinger2].name, outcome);
        reset();
    }

    /***** End of main consequences function *****/


    /***** Extra consequences functions *****/
    function pay(address gunslinger) internal {
        uint amountPaid = getBooty() / bootyExpiry;
        gunslingers[gunslinger].bootyClaimed += amountPaid;
        payable(gunslinger).transfer(amountPaid * 1 gwei);
    } 


    function peacefulVictory() internal {
        turnsOfPeace++;

        if(turnsOfPeace == bootyExpiry) {
            uint booty = getBooty();
            emit PeacefulVictory(gunslingers[gunslinger1].name, gunslingers[gunslinger2].name, booty);
            turnsOfPeace = 0;
            uint amountToPay = address(this).balance / 3;
            payable(gunslinger1).transfer(amountToPay);
            payable(gunslinger2).transfer(amountToPay);
        }
    }


    function forceResetDuel() external isRegistered {
        require((duelStartTime != 0) && 
                        (block.timestamp - duelStartTime > (duelAllocationTime + 30 seconds)),
                        "Needs the duel to expire first (+ 30 seconds)."
                    );

        emit ForceResetDuel(gunslingers[msg.sender].name);

        punish(gunslinger1);
        punish(gunslinger2);


        reset();
    }


    function punish(address gunslinger) internal {
        emit Punish(gunslingers[gunslinger].name);
        wounded.push(gunslinger);
        graveyard.push(gunslinger);
    }


    function reset() internal {
        emit Reset();
        readyForShootout = false;
        duelStartTime = 0;
        gunslinger1ActionComplete = false;
        gunslinger2ActionComplete = false;
        gunslinger1Shoots = false;
        gunslinger2Shoots = false;
        gunslinger1ActionHash = 0;
        gunslinger2ActionHash = 0;
        gunslingers[gunslinger1].inDuel = false;
        gunslingers[gunslinger2].inDuel = false;

        gunslinger1 = address(0);
        gunslinger2 = address(0);
    }

    /***** End of extra consequences functions *****/

}