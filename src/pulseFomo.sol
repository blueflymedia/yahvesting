// https://scan.pulsechain.com/address/0x22bB7d895d888aaaB0d01C683Fca76AA9622267B/contracts#address-tabs

pragma solidity ^0.4.24;

contract F3Devents {
    // fired whenever a player registers a name
    event onNewName(
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired at end of buy or reload
    event onEndTx(
        uint256 compressedData,
        uint256 compressedIDs,
        bytes32 playerName,
        address playerAddress,
        uint256 plsIn,
        uint256 heartsBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 finalPulseBurn,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );

    // fired whenever theres a withdraw
    event onWithdraw(
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plsOut,
        uint256 timeStamp
    );

    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 plsOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 finalPulseBurn,
        uint256 genAmount
    );

    // fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 plsIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 finalPulseBurn,
        uint256 genAmount
    );

    // fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute(
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 finalPulseBurn,
        uint256 genAmount
    );

    // fired whenever an affiliate is paid
    event onAffiliatePayout(
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );

    // received pot swap deposit
    event onPotSwapDeposit(uint256 roundID, uint256 amountAddedToPot);
}

//==============================================================================
//   _ _  _ _|_ _ _  __|_   _ _ _|_    _   .
//  (_(_)| | | | (_|(_ |   _\(/_ | |_||_)  .
//====================================|=========================================

contract modularShort is F3Devents {

}

contract PulseFOMO is modularShort {
    using SafeMath for *;
    using NameFilter for string;
    using F3DHeartsCalcShort for uint256;

    PlayerBookInterface private constant PlayerBook =
        PlayerBookInterface(0x41Aaa871CBDbdE228A087D376bEDE57556817cAB);

    //==============================================================================
    //     _ _  _  |`. _     _ _ |_ | _  _  .
    //    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
    //=================_|===========================================================
    address private admin = msg.sender;
    address private alphaOne;
    address private alphaTwo;
    address private alphaThree;
    address private alphaFour;
    address private alphaFive;
    address private alphaSix;
    address private alphaSeven;
    address private alphaEight;
    address private burnAddress;
    string public constant name = "Pulse Fomo";
    string public constant symbol = "PLS3D";
    uint256 private rndExtra_ = 5 seconds; // length of the very first ICO
    uint256 private rndGap_ = 5 seconds; // length of ICO phase, set to 1 year for EOS.
    uint256 private constant rndInit_ = 45 minutes; // round timer starts at this
    uint256 private constant rndInc_ = 37 seconds; // every full key purchased adds this much to the timer
    uint256 private constant rndMax_ = 18 hours; // max length a round timer can be
    //==============================================================================
    //     _| _ _|_ _    _ _ _|_    _   .
    //    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store game info that changes)
    //=============================|================================================
    uint256 public airDropPot_; // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0; // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    uint256 public rID_; // round id number / total rounds that have happened
    uint256 public companyShare; // yes, this is our share per tx for providing you fun, you shouldn't play this anyway, we probably go on holiday from it, thanks
    uint256 public companyPot; // public, no secrets
    uint256 public burnShare = 7; // 7% of each buy will be burned (PLS)
    uint256 public burnerShare = 13; // the person who calls the burn function get 13% of the amount
    uint256 public burnPot; // total collected PLS to burn
    uint256 public totalPulseBurned; // total pulse burned by this game
    uint256 public minimumBurnPot = 10e18; // minimum that needs to be in the burnpot before it can be called, can be changed if Pulse moons
    uint256 public totalRewarded;
    //****************
    // PLAYER DATA
    //****************
    mapping(address => uint256) public pIDxAddr_; // (addr => pID) returns player id by address
    mapping(bytes32 => uint256) public pIDxName_; // (name => pID) returns player id by name
    mapping(uint256 => F3Ddatasets.Player) public plyr_; // (pID => data) player data
    mapping(uint256 => mapping(uint256 => F3Ddatasets.PlayerRounds))
        public plyrRnds_; // (pID => rID => data) player round data by player id & round id
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)
    //****************
    // ROUND DATA
    //****************
    mapping(uint256 => F3Ddatasets.Round) public round_; // (rID => data) round data
    mapping(uint256 => mapping(uint256 => uint256)) public rndTmPls_; // (rID => tID => data) pls in per team, by round id and team id
    //****************
    // TEAM FEE DATA
    //****************
    mapping(uint256 => F3Ddatasets.TeamFee) public fees_; // (team => fees) fee distribution by team
    mapping(uint256 => F3Ddatasets.PotSplit) public potSplit_; // (team => fees) pot split distribution by team

    //==============================================================================
    //     _ _  _  __|_ _    __|_ _  _  .
    //    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
    //==============================================================================
    constructor(
        address _alphaOne,
        address _alphaTwo,
        address _alphaThree,
        address _alphaFour,
        address _alphaFive,
        address _alphaSix,
        address _alphaSeven,
        address _alphaEight,
        uint256 _cs
    ) public {
        // Team allocation structures
        // 0 = Team Vitalik
        // 1 = Team Justin Sun
        // 2 = Team Richard
        // 3 = Team Jack Levin

        // Team allocation percentages
        // Referrals / Community rewards are mathematically designed to come from the winner's share of the pot.
        fees_[0] = F3Ddatasets.TeamFee(76); // 76% to heart holders, 7% to pot, 10% to aff, 5% to com, 1% to pot swap, 1% to air drop pot
        fees_[1] = F3Ddatasets.TeamFee(33); // 33% to heart holders, 53% to pot, 10% to aff, 5% to com, 1% to pot swap, 1% to air drop pot
        fees_[2] = F3Ddatasets.TeamFee(45); // 45% to heart holders, 41% to pot, 10% to aff, 5% to com, 1% to pot swap, 1% to air drop pot
        fees_[3] = F3Ddatasets.TeamFee(17); // 17% to heart holders, 69% to pot, 10% to aff, 5% to com, 1% to pot swap, 1% to air drop pot

        // how to split up the final pot based on which team was picked
        potSplit_[0] = F3Ddatasets.PotSplit(10); // 75% to winner, 10% to next round, 5% to com
        potSplit_[1] = F3Ddatasets.PotSplit(10); // 75% to winner, 10% to next round, 5% to com
        potSplit_[2] = F3Ddatasets.PotSplit(10); // 75% to winner, 10% to next round, 5% to com
        potSplit_[3] = F3Ddatasets.PotSplit(10); // 75% to winner, 10% to next round, 5% to com

        // set addresses
        alphaOne = _alphaOne;
        alphaTwo = _alphaTwo;
        alphaThree = _alphaThree;
        alphaFour = _alphaFour;
        alphaFive = _alphaFive;
        alphaSix = _alphaSix;
        alphaSeven = _alphaSeven;
        alphaEight = _alphaEight;
        burnAddress = 0x0000000000000000000000000000000000000000;
        companyShare = _cs;
    }

    //==============================================================================
    //     _ _  _  _|. |`. _  _ _  .
    //    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
    //==============================================================================
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(
            activated_ == true,
            "its not ready yet.  check ?eta in discord"
        );
        _;
    }

    /**
     * @dev prevents contracts from interacting
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _pls) {
        require(_pls >= 75000000000000, "that is so much less");
        require(_pls <= 100000000000000000000000000000, "no richard, no");
        _;
    }

    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
    //====|=========================================================================
    /**
     * @dev emergency buy uses last stored affiliate ID and team Richard
     */
    function() public payable isActivated isHuman isWithinLimits(msg.value) {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // buy core
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }

    /**
     * @dev converts all incoming pulse to hearts.
     * -functionhash- 0x8f38f309 (using ID for affiliate)
     * -functionhash- 0x98a0871d (using address for affiliate)
     * -functionhash- 0xa65b37a1 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for?
     */
    function buyXid(
        uint256 _affCode,
        uint256 _team
    ) public payable isActivated isHuman isWithinLimits(msg.value) {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID) {
            _affCode = plyr_[_pID].laff;
            // if affiliate code was given & its not the same as previously stored
        } else if (_affCode != plyr_[_pID].laff) {
            // update last affiliate
            plyr_[_pID].laff = _affCode;
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // buy core
        buyCore(_pID, _affCode, _team, _eventData_);
    }

    function buyXaddr(
        address _affCode,
        uint256 _team
    ) public payable isActivated isHuman isWithinLimits(msg.value) {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender) {
            _affID = plyr_[_pID].laff;
            // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff) {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // buy core
        buyCore(_pID, _affID, _team, _eventData_);
    }

    function buyXname(
        bytes32 _affCode,
        uint256 _team
    ) public payable isActivated isHuman isWithinLimits(msg.value) {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == "" || _affCode == plyr_[_pID].name) {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;
            // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff) {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // buy core
        buyCore(_pID, _affID, _team, _eventData_);
    }

    /**
     * @dev essentially the same as buy, but instead of you sending pulse
     * from your wallet, it uses your unwithdrawn earnings.
     * -functionhash- 0x349cdcac (using ID for affiliate)
     * -functionhash- 0x82bfc739 (using address for affiliate)
     * -functionhash- 0x079ce327 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _team what team is the player playing for?
     * @param _pls amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadXid(
        uint256 _affCode,
        uint256 _team,
        uint256 _pls
    ) public isActivated isHuman isWithinLimits(_pls) {
        // set up our tx event data
        F3Ddatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID) {
            _affCode = plyr_[_pID].laff;
            // if affiliate code was given & its not the same as previously stored
        } else if (_affCode != plyr_[_pID].laff) {
            // update last affiliate
            plyr_[_pID].laff = _affCode;
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // reload core
        reLoadCore(_pID, _affCode, _team, _pls, _eventData_);
    }

    function reLoadXaddr(
        address _affCode,
        uint256 _team,
        uint256 _pls
    ) public isActivated isHuman isWithinLimits(_pls) {
        // set up our tx event data
        F3Ddatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender) {
            _affID = plyr_[_pID].laff;
            // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxAddr_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff) {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // reload core
        reLoadCore(_pID, _affID, _team, _pls, _eventData_);
    }

    function reLoadXname(
        bytes32 _affCode,
        uint256 _team,
        uint256 _pls
    ) public isActivated isHuman isWithinLimits(_pls) {
        // set up our tx event data
        F3Ddatasets.EventReturns memory _eventData_;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == "" || _affCode == plyr_[_pID].name) {
            _affCode = 0x6e6f6e6500000000000000000000000000000000000000000000000000000000;
            // if affiliate code was given
        } else {
            // get affiliate ID from aff Code
            _affID = pIDxName_[_affCode];

            // if affID is not the same as previously stored
            if (_affID != plyr_[_pID].laff) {
                // update last affiliate
                plyr_[_pID].laff = _affID;
            }
        }

        // verify a valid team was selected
        _team = verifyTeam(_team);

        // reload core
        reLoadCore(_pID, _affID, _team, _pls, _eventData_);
    }

    /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw() public isActivated isHuman {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];

        // setup temp var for player pls
        uint256 _pls;

        // check to see if round has ended and no one has run round end yet
        if (
            _now > round_[_rID].end &&
            round_[_rID].ended == false &&
            round_[_rID].plyr != 0
        ) {
            // set up our tx event data
            F3Ddatasets.EventReturns memory _eventData_;

            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // get their earnings
            _pls = withdrawEarnings(_pID);

            // gib moni
            if (_pls > 0) plyr_[_pID].addr.transfer(_pls);

            // build event data
            _eventData_.compressedData =
                _eventData_.compressedData +
                (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire withdraw and distribute event
            emit F3Devents.onWithdrawAndDistribute(
                msg.sender,
                plyr_[_pID].name,
                _pls,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.finalPulseBurn,
                _eventData_.genAmount
            );

            // in any other situation
        } else {
            // get their earnings
            _pls = withdrawEarnings(_pID);

            // gib moni
            if (_pls > 0) plyr_[_pID].addr.transfer(_pls);

            // fire withdraw event
            emit F3Devents.onWithdraw(
                _pID,
                msg.sender,
                plyr_[_pID].name,
                _pls,
                _now
            );
        }
    }

    /**
     * @dev use these to register names.  they are just wrappers that will send the
     * registration requests to the PlayerBook contract.  So registering here is the
     * same as registering there.  UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate
     * links.
     * - must pay a registration fee.
     * - name must be unique
     * - names will be converted to lowercase
     * - name cannot start or end with a space
     * - cannot have more than 1 space in a row
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9, and space
     * -functionhash- 0x921dec21 (using ID for affiliate)
     * -functionhash- 0x3ddd4698 (using address for affiliate)
     * -functionhash- 0x685ffd83 (using name for affiliate)
     * @param _nameString players desired name
     * @param _affCode affiliate ID, address, or name of who referred you
     * @param _all set to true if you want this to push your info to all games
     * (this might cost a lot of gas)
     */
    function registerNameXID(
        string _nameString,
        uint256 _affCode,
        bool _all
    ) public payable isHuman {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook
            .registerNameXIDFromDapp
            .value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(
            _pID,
            _addr,
            _name,
            _isNewPlayer,
            _affID,
            plyr_[_affID].addr,
            plyr_[_affID].name,
            _paid,
            now
        );
    }

    function registerNameXaddr(
        string _nameString,
        address _affCode,
        bool _all
    ) public payable isHuman {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook
            .registerNameXaddrFromDapp
            .value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(
            _pID,
            _addr,
            _name,
            _isNewPlayer,
            _affID,
            plyr_[_affID].addr,
            plyr_[_affID].name,
            _paid,
            now
        );
    }

    function registerNameXname(
        string _nameString,
        bytes32 _affCode,
        bool _all
    ) public payable isHuman {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook
            .registerNameXnameFromDapp
            .value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

        // fire event
        emit F3Devents.onNewName(
            _pID,
            _addr,
            _name,
            _isNewPlayer,
            _affID,
            plyr_[_affID].addr,
            plyr_[_affID].name,
            _paid,
            now
        );
    }

    //==============================================================================
    //     _  _ _|__|_ _  _ _
    //    (_|(/_ |  | (/_| _\
    //=====_|=======================================================================
    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice() public view returns (uint256) {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (
            _now > round_[_rID].strt + rndGap_ &&
            (_now <= round_[_rID].end ||
                (_now > round_[_rID].end && round_[_rID].plyr == 0))
        )
            return (
                (round_[_rID].hearts.add(1370000000000000000)).plsRec(
                    1370000000000000000
                )
            );
        // rounds over.  need price for new round
        else return (10000000000000000000); // init
    }

    /**
     * @dev returns time left.  dont spam this, you'll ddos yourself from your node
     * provider
     * -functionhash- 0xc7e284b8
     * @return time left in seconds
     */
    function getTimeLeft() public view returns (uint256) {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now < round_[_rID].strt + rndGap_)
                return ((round_[_rID].strt + rndGap_).sub(_now));
            else return ((round_[_rID].end).sub(_now));
        else return (0);
    }

    /**
     * @dev returns player earnings per vaults
     * -functionhash- 0x63066434
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
     */
    function getPlayerVaults(
        uint256 _pID
    ) public view returns (uint256, uint256, uint256) {
        // setup local rID
        uint256 _rID = rID_;

        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (
            now > round_[_rID].end &&
            round_[_rID].ended == false &&
            round_[_rID].plyr != 0
        ) {
            // if player is winner
            if (round_[_rID].plyr == _pID) {
                return (
                    (plyr_[_pID].win).add(((round_[_rID].pot).mul(75)) / 100),
                    (plyr_[_pID].gen).add(
                        getPlayerVaultsHelper(_pID, _rID).sub(
                            plyrRnds_[_pID][_rID].mask
                        )
                    ),
                    plyr_[_pID].aff
                );
                // if player is not the winner
            } else {
                return (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(
                        getPlayerVaultsHelper(_pID, _rID).sub(
                            plyrRnds_[_pID][_rID].mask
                        )
                    ),
                    plyr_[_pID].aff
                );
            }

            // if round is still going on, or round has ended and round end has been ran
        } else {
            return (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(
                    calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)
                ),
                plyr_[_pID].aff
            );
        }
    }

    /**
     * solidity hates stack limits.  this lets us avoid that hate
     */
    function getPlayerVaultsHelper(
        uint256 _pID,
        uint256 _rID
    ) private view returns (uint256) {
        return (
            ((
                (
                    (round_[_rID].mask).add(
                        (
                            ((
                                (round_[_rID].pot).mul(
                                    potSplit_[round_[_rID].team].gen
                                )
                            ) / 100).mul(1000000000000000000)
                        ) / (round_[_rID].hearts)
                    )
                ).mul(plyrRnds_[_pID][_rID].hearts)
            ) / 1000000000000000000)
        );
    }

    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return pls invested during ICO phase
     * @return round id
     * @return total hearts for round
     * @return time round ends
     * @return time round started
     * @return current pot
     * @return current team ID & player ID in lead
     * @return current player in leads address
     * @return current player in leads name
     * @return Team Jack Levin pls in for round
     * @return Team Justin Sun pls in for round
     * @return Team Richard pls in for round
     * @return Team Vitalik pls in for round
     * @return airdrop tracker # & airdrop pot
     */
    function getCurrentRoundInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // setup local rID
        uint256 _rID = rID_;

        return (
            round_[_rID].ico, //0
            _rID, //1
            round_[_rID].hearts, //2
            round_[_rID].end, //3
            round_[_rID].strt, //4
            round_[_rID].pot, //5
            (round_[_rID].team + (round_[_rID].plyr * 10)), //6
            plyr_[round_[_rID].plyr].addr, //7
            plyr_[round_[_rID].plyr].name, //8
            rndTmPls_[_rID][0], //9
            rndTmPls_[_rID][1], //10
            rndTmPls_[_rID][2], //11
            rndTmPls_[_rID][3], //12
            airDropTracker_ + (airDropPot_ * 1000) //13
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will
     * use msg.sender
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return player name
     * @return hearts owned (current round)
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
     * @return player round pls
     */
    function getPlayerInfoByAddress(
        address _addr
    )
        public
        view
        returns (uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;

        if (_addr == address(0)) {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return (
            _pID, //0
            plyr_[_pID].name, //1
            plyrRnds_[_pID][_rID].hearts, //2
            plyr_[_pID].win, //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)), //4
            plyr_[_pID].aff, //5
            plyrRnds_[_pID][_rID].pls //6
        );
    }

    //==============================================================================
    //     _ _  _ _   | _  _ . _  .
    //    (_(_)| (/_  |(_)(_||(_  . (this + tools + calcs + modules = our softwares engine)
    //=====================_|=======================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle
     * incoming pls depending on if we are in an active round or not
     */
    function buyCore(
        uint256 _pID,
        uint256 _affID,
        uint256 _team,
        F3Ddatasets.EventReturns memory _eventData_
    ) private {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        uint256 totalTaxed = (msg.value / 100) *
            companyShare +
            ((msg.value / 100) * burnShare);
        uint256 correctedValue = msg.value - totalTaxed;

        // if round is active
        if (
            _now > round_[_rID].strt + rndGap_ &&
            (_now <= round_[_rID].end ||
                (_now > round_[_rID].end && round_[_rID].plyr == 0))
        ) {
            // call core

            core(_rID, _pID, correctedValue, _affID, _team, _eventData_);

            // if round is not active
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false) {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                // build event data
                _eventData_.compressedData =
                    _eventData_.compressedData +
                    (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                // fire buy and distribute event
                emit F3Devents.onBuyAndDistribute(
                    msg.sender,
                    plyr_[_pID].name,
                    correctedValue,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.finalPulseBurn,
                    _eventData_.genAmount
                );
            }

            // put pls in players vault
            plyr_[_pID].gen = plyr_[_pID].gen.add(correctedValue);
        }
        burnPot = burnPot + ((msg.value / 100) * burnShare);
        companyPot = companyPot + ((msg.value / 100) * companyShare);
    }

    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle
     * incoming pls depending on if we are in an active round or not
     */
    function reLoadCore(
        uint256 _pID,
        uint256 _affID,
        uint256 _team,
        uint256 _pls,
        F3Ddatasets.EventReturns memory _eventData_
    ) private {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        uint256 totalTaxed = (_pls / 100) *
            companyShare +
            ((_pls / 100) * burnShare);
        uint256 correctedValue = _pls - totalTaxed;

        // if round is active
        if (
            _now > round_[_rID].strt + rndGap_ &&
            (_now <= round_[_rID].end ||
                (_now > round_[_rID].end && round_[_rID].plyr == 0))
        ) {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player
            // tried to spend more pls than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(correctedValue);

            // call core
            core(_rID, _pID, correctedValue, _affID, _team, _eventData_);

            // if round is not active and end round needs to be ran
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

            // build event data
            _eventData_.compressedData =
                _eventData_.compressedData +
                (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            // fire buy and distribute event
            emit F3Devents.onReLoadAndDistribute(
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.finalPulseBurn,
                _eventData_.genAmount
            );
        }
    }

    /**
     * @dev this is the core logic for any buy/reload that happens while a round
     * is live.
     */
    function core(
        uint256 _rID,
        uint256 _pID,
        uint256 _pls,
        uint256 _affID,
        uint256 _team,
        F3Ddatasets.EventReturns memory _eventData_
    ) private {
        // if player is new to round
        if (plyrRnds_[_pID][_rID].hearts == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        // early round pls limiter
        if (
            round_[_rID].pls < 100000000000000000000 &&
            plyrRnds_[_pID][_rID].pls.add(_pls) > 2100000000000000000000
        ) {
            uint256 _availableLimit = (2100000000000000000000).sub(
                plyrRnds_[_pID][_rID].pls
            );
            uint256 _refund = _pls.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _pls = _availableLimit;
        }

        // if pls left is greater than min pls allowed (sorry no pocket lint)
        if (_pls > 1000000000) {
            // mint the new hearts
            uint256 _hearts = (round_[_rID].pls).heartsRec(_pls);

            // if they bought at least 1 whole key
            if (_hearts >= 1000000000000000000) {
                updateTimer(_hearts, _rID);

                // set new leaders
                if (round_[_rID].plyr != _pID) round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team) round_[_rID].team = _team;

                // set the new leader bool to true
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            // manage airdrops
            if (_pls >= 10000000000000000000000) {
                airDropTracker_++;
                if (airdrop() == true) {
                    // gib muni
                    uint256 _prize;
                    if (_pls >= 1000000000000000000000000) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_
                            .compressedData += 300000000000000000000000000000000;
                    } else if (
                        _pls >= 100000000000000000000000 &&
                        _pls < 1000000000000000000000000
                    ) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 2 prize was won
                        _eventData_
                            .compressedData += 200000000000000000000000000000000;
                    } else if (
                        _pls >= 10000000000000000000000 &&
                        _pls < 100000000000000000000000
                    ) {
                        // calculate prize and give it to winner
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                        // adjust airDropPot
                        airDropPot_ = (airDropPot_).sub(_prize);

                        // let event know a tier 3 prize was won
                        _eventData_
                            .compressedData += 300000000000000000000000000000000;
                    }
                    // set airdrop happened bool to true
                    _eventData_
                        .compressedData += 10000000000000000000000000000000;
                    // let event know how much was won
                    _eventData_.compressedData +=
                        _prize *
                        1000000000000000000000000000000000;

                    // reset air drop tracker
                    airDropTracker_ = 0;
                }
            }

            // store the air drop tracker number (number of buys since last airdrop)
            _eventData_.compressedData =
                _eventData_.compressedData +
                (airDropTracker_ * 1000);

            // update player
            plyrRnds_[_pID][_rID].hearts = _hearts.add(
                plyrRnds_[_pID][_rID].hearts
            );
            plyrRnds_[_pID][_rID].pls = _pls.add(plyrRnds_[_pID][_rID].pls);

            // update round
            round_[_rID].hearts = _hearts.add(round_[_rID].hearts);
            round_[_rID].pls = _pls.add(round_[_rID].pls);
            rndTmPls_[_rID][_team] = _pls.add(rndTmPls_[_rID][_team]);

            // distribute pls
            _eventData_ = distributeExternal(
                _rID,
                _pID,
                _pls,
                _affID,
                _team,
                _eventData_
            );
            _eventData_ = distributeInternal(
                _rID,
                _pID,
                _pls,
                _team,
                _hearts,
                _eventData_
            );

            // call end tx function to fire end tx event.
            endTx(_pID, _team, _pls, _hearts, _eventData_);
        }
    }

    //==============================================================================
    //     _ _ | _   | _ _|_ _  _ _  .
    //    (_(_||(_|_||(_| | (_)| _\  .
    //==============================================================================
    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(
        uint256 _pID,
        uint256 _rIDlast
    ) private view returns (uint256) {
        return (
            (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].hearts)) /
                (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)
        );
    }

    /**
     * @dev returns the amount of hearts you would get given an amount of pls.
     * -functionhash- 0xce89c80c
     * @param _rID round ID you want price for
     * @param _pls amount of pls sent in
     * @return hearts received
     */
    function calcHeartsReceived(
        uint256 _rID,
        uint256 _pls
    ) public view returns (uint256) {
        // grab time
        uint256 _now = now;

        // are we in a round?
        if (
            _now > round_[_rID].strt + rndGap_ &&
            (_now <= round_[_rID].end ||
                (_now > round_[_rID].end && round_[_rID].plyr == 0))
        ) return ((round_[_rID].pls).heartsRec(_pls));
        // rounds over.  need hearts for new round
        else return ((_pls).hearts());
    }

    /**
     * @dev returns current pls price for X hearts.
     * -functionhash- 0xcf808000
     * @param _hearts number of hearts desired (in 18 decimal format)
     * @return amount of pls needed to send
     */
    function iWantXHearts(uint256 _hearts) public view returns (uint256) {
        // setup local rID
        uint256 _rID = rID_;

        // grab time
        uint256 _now = now;

        // are we in a round?
        if (
            _now > round_[_rID].strt + rndGap_ &&
            (_now <= round_[_rID].end ||
                (_now > round_[_rID].end && round_[_rID].plyr == 0))
        ) return ((round_[_rID].hearts.add(_hearts)).plsRec(_hearts));
        // rounds over.  need price for new round
        else return ((_hearts).pls());
    }

    //==============================================================================
    //    _|_ _  _ | _  .
    //     | (_)(_)|_\  .
    //==============================================================================
    /**
     * @dev receives name/player info from names contract
     */
    function receivePlayerInfo(
        uint256 _pID,
        address _addr,
        bytes32 _name,
        uint256 _laff
    ) external {
        require(
            msg.sender == address(PlayerBook),
            "your not playerNames contract... hmmm.."
        );
        if (pIDxAddr_[_addr] != _pID) pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID) pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr) plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name) plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff) plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false) plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev receives entire player name list
     */
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external {
        require(
            msg.sender == address(PlayerBook),
            "your not playerNames contract... hmmm.."
        );
        if (plyrNames_[_pID][_name] == false) plyrNames_[_pID][_name] = true;
    }

    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID
     */
    function determinePID(
        F3Ddatasets.EventReturns memory _eventData_
    ) private returns (F3Ddatasets.EventReturns) {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this version
        if (_pID == 0) {
            // grab their player ID, name and last aff ID, from player names contract
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

            // set up player account
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            if (_name != "") {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

            if (_laff != 0 && _laff != _pID) plyr_[_pID].laff = _laff;

            // set the new player bool to true
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    /**
     * @dev checks to make sure user picked a valid team.  if not sets team
     * to default (Team Richard)
     */
    function verifyTeam(uint256 _team) private pure returns (uint256) {
        if (_team < 0 || _team > 3) return (2);
        else return (_team);
    }

    /**
     * @dev decides if round end needs to be run & new round started.  and if
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(
        uint256 _pID,
        F3Ddatasets.EventReturns memory _eventData_
    ) private returns (F3Ddatasets.EventReturns) {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0) updateGenVault(_pID, plyr_[_pID].lrnd);

        // update player's last round played
        plyr_[_pID].lrnd = rID_;

        // set the joined round bool to true
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return (_eventData_);
    }

    function burnPulse() public {
        require(burnPot >= minimumBurnPot, "min not reached okay");
        address burnCaller = msg.sender;
        uint256 burnerBonus = (burnPot / 100) * burnerShare;
        uint256 correctedBurn = burnPot - burnerBonus;
        burnAddress.transfer(correctedBurn);
        burnCaller.transfer(burnerBonus);
        totalPulseBurned = totalPulseBurned + correctedBurn;
        burnPot = 0;
        totalRewarded = totalRewarded + burnerBonus;
    }

    function currentReward() public view returns (uint256) {
        uint256 currentBurnReward = (burnPot / 100) * burnerShare;
        return currentBurnReward;
    }

    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(
        F3Ddatasets.EventReturns memory _eventData_
    ) private returns (F3Ddatasets.EventReturns) {
        // setup local rID
        uint256 _rID = rID_;

        // grab our winning player and team id's
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

        // grab our pot amount
        uint256 _pot = round_[_rID].pot;

        // calculate our winner share, community rewards, gen share,
        // and amount reserved for next pot
        uint256 _win = (_pot.mul(75)) / 100; // 75%
        uint256 _com = (_pot.mul(5)) / 100; // 5%
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen));

        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].hearts);
        uint256 _dust = _gen.sub(
            (_ppt.mul(round_[_rID].hearts)) / 1000000000000000000
        );
        if (_dust > 0) {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        // community rewards
        admin.transfer(_com);

        // distribute gen portion to heart holders
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // prepare event data
        _eventData_.compressedData =
            _eventData_.compressedData +
            (round_[_rID].end * 1000000);
        _eventData_.compressedIDs =
            _eventData_.compressedIDs +
            (_winPID * 100000000000000000000000000) +
            (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;

        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return (_eventData_);
    }

    function clearAlphas() public {
        uint256 a1 = (companyPot / 100) * 30;
        uint256 a2 = (companyPot / 100) * 10;
        uint256 a3 = (companyPot / 100) * 10;
        uint256 a4 = (companyPot / 100) * 10;
        uint256 a5 = (companyPot / 100) * 10;
        uint256 a6 = (companyPot / 100) * 10;
        uint256 a7 = (companyPot / 100) * 10;
        uint256 a8 = (companyPot / 100) * 10;
        alphaOne.transfer(a1);
        alphaTwo.transfer(a2);
        alphaThree.transfer(a3);
        alphaFour.transfer(a4);
        alphaFive.transfer(a5);
        alphaSix.transfer(a6);
        alphaSeven.transfer(a7);
        alphaEight.transfer(a8);
        companyPot = 0;
    }

    function setCompany(uint256 _share) external {
        require(msg.sender == admin);
        require(_share >= 5, "we cannot pay vacation below 5, admin");
        require(_share <= 13, "we cannot go above 13, they will hate us");
        companyShare = _share;
    }

    function setMinimumBurnPot(uint256 _amount) external {
        require(msg.sender == admin);
        minimumBurnPot = _amount;
    }

    function setNewA1(address _a1) external {
        require(msg.sender == admin);
        alphaOne = _a1;
    }

    function setNewA2(address _a2) external {
        require(msg.sender == admin);
        alphaTwo = _a2;
    }

    function setNewA3(address _a3) external {
        require(msg.sender == admin);
        alphaThree = _a3;
    }

    function setNewA4(address _a4) external {
        require(msg.sender == admin);
        alphaFour = _a4;
    }

    function setNewA5(address _a5) external {
        require(msg.sender == admin);
        alphaFive = _a5;
    }

    function setNewA6(address _a6) external {
        require(msg.sender == admin);
        alphaSix = _a6;
    }

    function setNewA7(address _a7) external {
        require(msg.sender == admin);
        alphaSeven = _a7;
    }

    function setNewA8(address _a8) external {
        require(msg.sender == admin);
        alphaEight = _a8;
    }

    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast) private {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0) {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(
                plyrRnds_[_pID][_rIDlast].mask
            );
        }
    }

    /**
     * @dev updates round timer based on number of whole hearts bought.
     */
    function updateTimer(uint256 _hearts, uint256 _rID) private {
        // grab time
        uint256 _now = now;

        // calculate time based on number of hearts bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_hearts) / (1000000000000000000)).mul(rndInc_)).add(
                _now
            );
        else
            _newTime = (((_hearts) / (1000000000000000000)).mul(rndInc_)).add(
                round_[_rID].end
            );

        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now)) round_[_rID].end = _newTime;
        else round_[_rID].end = rndMax_.add(_now);
    }

    /**
     * @dev generates a random number between 0-99 and checks to see if thats
     * resulted in an airdrop win
     * @return do we have a winner?
     */
    function airdrop() private view returns (bool) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp)
                        .add(block.difficulty)
                        .add(
                            (
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (now)
                        )
                        .add(block.gaslimit)
                        .add(
                            (uint256(keccak256(abi.encodePacked(msg.sender)))) /
                                (now)
                        )
                        .add(block.number)
                )
            )
        );
        if ((seed - ((seed / 1000) * 1000)) < airDropTracker_) return (true);
        else return (false);
    }

    /**
     * @dev distributes pls based on fees to com, aff, and p3d
     */
    function distributeExternal(
        uint256 _rID,
        uint256 _pID,
        uint256 _pls,
        uint256 _affID,
        uint256 _team,
        F3Ddatasets.EventReturns memory _eventData_
    ) private returns (F3Ddatasets.EventReturns) {
        // pay 2% out to community rewards
        uint256 _com = _pls / 50; //2%

        uint256 _finalBurn;
        if (!address(admin).call.value(_com)()) {
            // This ensures the team cannot influence the outcome with
            // bank migrations by breaking outgoing transactions.
            // Somplsing we would never do. But that's not the point.
            _finalBurn = _com;
            _com = 0;
        }

        // distribute share to affiliate
        uint256 _aff = _pls / 10;

        // decide what to do with affiliate share of fees
        // affiliate must not be self, and must have a name registered
        if (_affID != _pID && plyr_[_affID].name != "") {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F3Devents.onAffiliatePayout(
                _affID,
                plyr_[_affID].addr,
                plyr_[_affID].name,
                _rID,
                _pID,
                _aff,
                now
            );
        } else {
            _finalBurn = _aff;
        }

        return (_eventData_);
    }

    function potSwap() external payable {
        // setup local rID
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F3Devents.onPotSwapDeposit(_rID, msg.value);
    }

    /**
     * @dev distributes pls based on fees to gen and pot
     */
    function distributeInternal(
        uint256 _rID,
        uint256 _pID,
        uint256 _pls,
        uint256 _team,
        uint256 _hearts,
        F3Ddatasets.EventReturns memory _eventData_
    ) private returns (F3Ddatasets.EventReturns) {
        // calculate gen share
        uint256 _gen = (_pls.mul(fees_[_team].gen)) / 100;

        // toss 1% into airdrop pot
        uint256 _air = (_pls / 100);
        airDropPot_ = airDropPot_.add(_air);

        // update pls balance (pls = pls - (com share + pot swap share + aff share + airdrop pot share))
        _pls = _pls.sub(((_pls.mul(14)) / 100));

        // calculate pot
        uint256 _pot = _pls.sub(_gen);

        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _hearts);
        if (_dust > 0) _gen = _gen.sub(_dust);

        // add pls to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return (_eventData_);
    }

    /**
     * @dev updates masks for round and player when hearts are bought
     * @return dust left over
     */
    function updateMasks(
        uint256 _rID,
        uint256 _pID,
        uint256 _gen,
        uint256 _hearts
    ) private returns (uint256) {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.
            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */

        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].hearts);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        // calculate player earning from their own buy (only based on the hearts
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_hearts)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (
            ((round_[_rID].mask.mul(_hearts)) / (1000000000000000000)).sub(
                _pearn
            )
        ).add(plyrRnds_[_pID][_rID].mask);

        // calculate & return dust
        return (
            _gen.sub((_ppt.mul(round_[_rID].hearts)) / (1000000000000000000))
        );
    }

    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID) private returns (uint256) {
        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);

        // from vaults
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(
            plyr_[_pID].aff
        );
        if (_earnings > 0) {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return (_earnings);
    }

    /**
     * @dev prepares compression data and fires event for buy or reload tx's
     */
    function endTx(
        uint256 _pID,
        uint256 _team,
        uint256 _pls,
        uint256 _hearts,
        F3Ddatasets.EventReturns memory _eventData_
    ) private {
        _eventData_.compressedData =
            _eventData_.compressedData +
            (now * 1000000000000000000) +
            (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs =
            _eventData_.compressedIDs +
            _pID +
            (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit F3Devents.onEndTx(
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _pls,
            _hearts,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.finalPulseBurn,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

    //==============================================================================
    //    (~ _  _    _._|_    .
    //    _)(/_(_|_|| | | \/  .
    //====================/=========================================================
    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs
     * have time to set things up on the web end                            **/
    bool public activated_ = false;

    function activate() public {
        // only team can activate
        require(msg.sender == admin);

        // can only be ran once
        require(activated_ == false);

        // activate the contract
        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library F3Ddatasets {
    //compressedData key
    // [76-33][32][31][30][29][28-18][17][16-6][5-3][2][1][0]
    // 0 - new player (bool)
    // 1 - joined round (bool)
    // 2 - new  leader (bool)
    // 3-5 - air drop tracker (uint 0-999)
    // 6-16 - round end time
    // 17 - winnerTeam
    // 18 - 28 timestamp
    // 29 - team
    // 30 - 0 = reinvest (round), 1 = buy (round), 2 = buy (ico), 3 = reinvest (ico)
    // 31 - airdrop happened bool
    // 32 - airdrop tier
    // 33 - airdrop amount won
    //compressedIDs key
    // [77-52][51-26][25-0]
    // 0-25 - pID
    // 26-51 - winPID
    // 52-77 - rID
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr; // winner address
        bytes32 winnerName; // winner name
        uint256 amountWon; // amount won
        uint256 newPot; // amount in new pot
        uint256 finalPulseBurn; // amount distributed to p3d
        uint256 genAmount; // amount distributed to gen
        uint256 potAmount; // amount added to pot
    }
    struct Player {
        address addr; // player address
        bytes32 name; // player name
        uint256 win; // winnings vault
        uint256 gen; // general vault
        uint256 aff; // affiliate vault
        uint256 lrnd; // last round played
        uint256 laff; // last affiliate id used
    }
    struct PlayerRounds {
        uint256 pls; // pls player has added to round (used for pls limiter)
        uint256 hearts; // hearts
        uint256 mask; // player mask
        uint256 ico; // ICO phase investment
    }
    struct Round {
        uint256 plyr; // pID of player in lead
        uint256 team; // tID of team in lead
        uint256 end; // time ends/ended
        bool ended; // has round end function been ran
        uint256 strt; // time round started
        uint256 hearts; // hearts
        uint256 pls; // total pls in
        uint256 pot; // pls to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask; // global mask
        uint256 ico; // total pls sent in during ICO phase
        uint256 icoGen; // total pls for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase
    }
    struct TeamFee {
        uint256 gen; // % of buy in thats paid to heart holders of current round
    }
    struct PotSplit {
        uint256 gen; // % of pot thats paid to heart holders of current round
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library F3DHeartsCalcShort {
    using SafeMath for *;

    /**
     * @dev calculates number of hearts received given X pls
     * @param _curPls current amount of pls in contract
     * @param _newPls pls being spent
     * @return amount of ticket purchased
     */
    function heartsRec(
        uint256 _curPls,
        uint256 _newPls
    ) internal pure returns (uint256) {
        return (hearts((_curPls).add(_newPls)).sub(hearts(_curPls)));
    }

    /**
     * @dev calculates amount of pls received if you sold X hearts
     * @param _curHearts current amount of hearts that exist
     * @param _sellHearts amount of hearts you wish to sell
     * @return amount of pls received
     */
    function plsRec(
        uint256 _curHearts,
        uint256 _sellHearts
    ) internal pure returns (uint256) {
        return ((pls(_curHearts)).sub(pls(_curHearts.sub(_sellHearts))));
    }

    /**
     * @dev calculates how many hearts would exist with given an amount of pls
     * @param _pls pls "in contract"
     * @return number of hearts that would exist
     */
    function hearts(uint256 _pls) internal pure returns (uint256) {
        return
            (
                (
                    (
                        (
                            ((_pls).mul(1000000000000000000)).mul(
                                312500000000000000000000000
                            )
                        ).add(
                                5624988281256103515625000000000000000000000000000000000000000000
                            )
                    ).sqrt()
                ).sub(74999921875000000000000000000000)
            ) / (156250000);
    }

    /**
     * @dev calculates how much pls would be in contract given a number of hearts
     * @param _hearts number of hearts "in contract"
     * @return pls that would exists
     */
    function pls(uint256 _hearts) internal pure returns (uint256) {
        return
            (
                (78125000).mul(_hearts.sq()).add(
                    ((149999843750000).mul(_hearts.mul(1000000000000000000))) /
                        (2)
                )
            ) / ((1000000000000000000).sq());
    }
}

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);

    function getPlayerName(uint256 _pID) external view returns (bytes32);

    function getPlayerLAff(uint256 _pID) external view returns (uint256);

    function getPlayerAddr(uint256 _pID) external view returns (address);

    function getNameFee() external view returns (uint256);

    function registerNameXIDFromDapp(
        address _addr,
        bytes32 _name,
        uint256 _affCode,
        bool _all
    ) external payable returns (bool, uint256);

    function registerNameXaddrFromDapp(
        address _addr,
        bytes32 _name,
        address _affCode,
        bool _all
    ) external payable returns (bool, uint256);

    function registerNameXnameFromDapp(
        address _addr,
        bytes32 _name,
        bytes32 _affCode,
        bool _all
    ) external payable returns (bool, uint256);
}

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input) internal pure returns (bytes32) {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require(
            _length <= 32 && _length > 0,
            "string must be between 1 and 32 characters"
        );
        // make sure it doesnt start with or end with space
        require(
            _temp[0] != 0x20 && _temp[_length - 1] != 0x20,
            "string cannot start or end with space"
        );
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30) {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++) {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b) {
                // convert to lower case a-z
                _temp[i] = bytes1(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false) _hasNonNumber = true;
            } else {
                require(
                    // require character is a space
                    _temp[i] == 0x20 ||
                        // OR lowercase a-z
                        (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                        // or 0-9
                        (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require(
                        _temp[i + 1] != 0x20,
                        "string cannot contain consecutive spaces"
                    );

                // see if we have a character other than a number
                if (
                    _hasNonNumber == false &&
                    (_temp[i] < 0x30 || _temp[i] > 0x39)
                ) _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) return (0);
        else if (y == 0) return (1);
        else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) z = mul(z, x);
            return (z);
        }
    }
}
