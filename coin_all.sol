pragma solidity ^0.4.14;

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It's O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract TokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function totalSupply() constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address addr) constant returns (uint256) {
        return _balances[addr];
    }
    function allowance(address from, address to) constant returns (uint256) {
        return _approvals[from][to];
    }
    
    function transfer(address to, uint value) returns (bool) {
        assert(_balances[msg.sender] >= value);
        
        _balances[msg.sender] = sub(_balances[msg.sender], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) returns (bool) {
        assert(_balances[from] >= value);
        assert(_approvals[from][msg.sender] >= value);
        
        _approvals[from][msg.sender] = sub(_approvals[from][msg.sender], value);
        _balances[from] = sub(_balances[from], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address to, uint256 value) returns (bool) {
        _approvals[msg.sender][to] = value;
        
        Approval(msg.sender, to, value);
        
        return true;
    }

}

contract Owned
{
    address public owner;
    
    function Owned()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }
}

contract Migrable is TokenBase, Owned
{
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    address public migrationAgent;
    uint256 public totalMigrated;


    function migrate() external {
        // Abort if not in Operational Migration state.
        if (migrationAgent == 0)  revert();
        if (_balances[msg.sender] == 0)  revert();
        
        uint256 _value = _balances[msg.sender];
        _balances[msg.sender] = 0;
        _supply = sub(_supply, _value);
        totalMigrated = add(totalMigrated, _value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    function setMigrationAgent(address _agent) onlyOwner external {
        if (migrationAgent != 0)  revert();
        migrationAgent = _agent;
    }
}

contract CrowdCoin is TokenBase, Owned, Migrable {
    string public constant name = "Crowd Coin";
    string public constant symbol = "CRC";
    uint8 public constant decimals = 18; 

    uint public constant pre_ico_allocation = 3500000 * WAD;
    uint public constant bounty_allocation = 500000 * WAD;
    
    uint private ico_allocation = 4000000 * WAD;

    bool public locked = true; 

    address public bounty; 
    CrowdCoinPreICO public pre_ico;
    CrowdCoinICO public ico;
    address team_allocation;
    

    function CrowdCoin(address _team_allocation) {
        team_allocation = _team_allocation;
    }
    
    function transfer(address to, uint value) returns (bool)
    {
        if (locked == true && (msg.sender != address(ico) && msg.sender != address(pre_ico))) revert();
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint value)  returns (bool)
    {
        if (locked == true) revert();
        return super.transferFrom(from, to, value);
    }

    function init_pre_ico(address _pre_ico) onlyOwner
    {
        if (address(0) != address(pre_ico)) revert();
        pre_ico = CrowdCoinPreICO(_pre_ico);
        mint_tokens(pre_ico, pre_ico_allocation);
    }
    
    function close_pre_ico() onlyOwner
    {
        if (_balances[pre_ico] > 0)
        {
            ico_allocation = add(ico_allocation, _balances[pre_ico]);   
            burn_tokens(pre_ico, _balances[pre_ico]);
        }
        
        pre_ico.close();
    }

    function init_ico(address _ico) onlyOwner
    {
        if (address(0) != address(ico)) revert();
        ico = CrowdCoinICO(_ico);
        mint_tokens(ico, ico_allocation);
    }
    
    function init_bounty_program(address _bounty) onlyOwner
    {
        if (address(0) != address(bounty)) revert();
        bounty = _bounty;
        mint_tokens(bounty, bounty_allocation);
    }
    
    function finalize() onlyOwner {
        if (ico.is_success() == false || locked == false) revert();
        if (_balances[ico] > 0)
        {
            burn_tokens(ico, _balances[ico]);
        }

        uint256 percentOfTotal = 25;
        uint256 additionalTokens =
            _supply * percentOfTotal / (100 - percentOfTotal);
        
        mint_tokens(team_allocation, additionalTokens);
        
        locked = false;
    }

    function mint_tokens(address addr, uint amount) private
    {
        _balances[addr] = add(_balances[addr], amount);
        _supply = add(_supply, amount);
        Transfer(0, addr, amount);
    }
    
    function burn_tokens(address addr, uint amount) private
    {
        if (_balances[addr] < amount) revert();
        _balances[addr] = sub(_balances[addr], amount);
        _supply = sub(_supply, amount);
        Transfer(addr, 0, amount);
    }
}


contract CrowdCoinPreICO is Owned, DSMath
{
    CrowdCoin public token;
    address public dev_multisig;
    
    uint public total_raised;

    uint public constant price =  0.0005 * 10**18;
    bool private closed = false;

    function my_token_balance() public constant returns (uint)
    {
        return token.balanceOf(this);
    }

    modifier has_value
    {
        if (msg.value < 0.01 ether) revert();
        _;
    }

    function CrowdCoinPreICO(address _token_address, address _dev_multisig)
    {
        token = CrowdCoin(_token_address);
        dev_multisig = _dev_multisig;
    }
    
    function () has_value payable external 
    {
        if (my_token_balance() == 0 || closed == true) revert();

        var can_buy = wdiv(cast(msg.value), cast(price));
        var buy_amount = cast(min(can_buy, my_token_balance()));

        if (can_buy > buy_amount) revert();

        total_raised = add(total_raised, msg.value);

        dev_multisig.transfer(this.balance); //transfer eth to dev
        token.transfer(msg.sender, buy_amount); //transfer tokens to participant
    }
    
    function close()
    {
        if (msg.sender != address(token)) revert();
        closed = true;
    }
}


contract CrowdCoinICO {
    function is_success() returns (bool);
}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}
