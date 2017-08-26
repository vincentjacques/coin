pragma solidity ^0.4.14;

contract ERC20 { // інтерфейс стандурту, свідчить про те що в тих хто це наслідує мають бути такі методи, так званий стандарт ERC20
    function totalSupply() constant returns (uint supply); // загальна кількість монет
    function balanceOf( address who ) constant returns (uint value); // баланс конкретного гаманця
    function allowance( address owner, address spender ) constant returns (uint _allowance); // тут перевіряється чи дозволено перевід від чужого імені

    function transfer( address to, uint value) returns (bool ok); // функція що переводить токен з балансу на баланс
    function transferFrom( address from, address to, uint value) returns (bool ok); //функція переводу токена з чужого балансу, якщо дозволено власником
    function approve( address spender, uint value ) returns (bool ok); //тут можна дати дозвіл перевід з мого балансу комусь певої суми

    event Transfer( address indexed from, address indexed to, uint value); //Описана подія про перевід
    event Approval( address indexed owner, address indexed spender, uint value);//Описана подія про дозвіл переводити третій особі
}

contract DSMath {//Чужа бібліотека, що спрощує життя солідіті кодеру
    
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

contract TokenBase is ERC20, DSMath { //база монети, наслідує бібліотеку, стандартний токен
    uint256                                            _supply; //змінна загальної кількості монет
    mapping (address => uint256)                       _balances; //баланси
    mapping (address => mapping (address => uint256))  _approvals; //масив дозволів для третіх осіб

    function totalSupply() constant returns (uint256) { //див опис в ERC20
        return _supply;
    }
    function balanceOf(address addr) constant returns (uint256) {//див опис в ERC20
        return _balances[addr];
    }
    function allowance(address from, address to) constant returns (uint256) {//див опис в ERC20
        return _approvals[from][to];
    }
    
    function transfer(address to, uint value) returns (bool) {//див опис в ERC20
        assert(_balances[msg.sender] >= value);
        
        _balances[msg.sender] = sub(_balances[msg.sender], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) returns (bool) {//див опис в ERC20
        assert(_balances[from] >= value);
        assert(_approvals[from][msg.sender] >= value);
        
        _approvals[from][msg.sender] = sub(_approvals[from][msg.sender], value);
        _balances[from] = sub(_balances[from], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address to, uint256 value) returns (bool) {//див опис в ERC20
        _approvals[msg.sender][to] = value;
        
        Approval(msg.sender, to, value);
        
        return true;
    }

}

contract Owned //контракт, що має змінну owner, і записує в неї того хто його створив
{
    address public owner;
    
    function Owned()//конструктор контракту, виконується один раз при створенні контракту
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()//modifier - це функція яка виконається перед тілом функції до якої застосовується. знак _ - це тіло функції до якої застосовується.
    {
        if (msg.sender != owner) revert(); //перевірка, якщо виконується не власником контракту, обірвати виконання та вийти.
        _;
    }
}

contract Migrable is TokenBase, Owned //контракт який призначений для міграції монети в інший контракт в майбутньому.
{
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    address public migrationAgent; //адрес куда мігрувати
    uint256 public totalMigrated;//скільки монет мігровано


    function migrate() external { //основна функція міграції, мігрує весь баланс в новий контракт
        if (migrationAgent == 0)  revert(); //якщо нема куда мігрувати, обірвати виконання
        if (_balances[msg.sender] == 0)  revert(); //якщо нема що мігрувати, обірвати виконання
        
        uint256 _value = _balances[msg.sender];
        _balances[msg.sender] = 0; //обнуляєм баланс
        _supply = sub(_supply, _value);//зменшуєм загальну кількість монт
        totalMigrated = add(totalMigrated, _value);//добавляємо до мігрованих
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);//викликаємо функцію в контракті куда мігруємо скільки монет мігровано і звідки
        Migrate(msg.sender, migrationAgent, _value);//створюємо подію про це (сповіщення)
    }

    function setMigrationAgent(address _agent) onlyOwner external { //встановлюємо контракт куда мігрувати, може бути викликана тільки власником
        if (migrationAgent != 0)  revert();//обірвати якщо вже встановлено
        migrationAgent = _agent; //присвоюємо контракт для міграції в змінну
    }
}

contract CrowdCoin is TokenBase, Owned, Migrable { //Монетка, наслідує базовий токен, може мати власника, може бути мігрована
    string public constant name = "Crowd Coin";//Назва
    string public constant symbol = "CRC";//Символ
    uint8 public constant decimals = 18; //Кількість знаків після коми (це абстракція, дрібних чисел в солідіті не існує як таких)

    uint public constant pre_ico_allocation = 3500000 * WAD; //Кількісь монет що буде виділено на пресейл
    uint public constant bounty_allocation = 500000 * WAD;//Кількісь монет що буде виділено на баунті
    
    uint private ico_allocation = 4000000 * WAD; //Кількісь монет що буде виділено на ICO

    bool public locked = true; //Змінна яка не дозволяє перевід токенів поки не буде успішного ICO

    address public bounty; //описується адреса баунті контракту
    CrowdCoinPreICO public pre_ico;//описується контракт preICO
    CrowdCoinICO public ico;//описується контракт ICO
    address team_allocation;//описується адреса для переводу токенів команді
    

    function CrowdCoin(address _team_allocation) { //конструктор
        team_allocation = _team_allocation; //присвоюємо адресу контракту де будуть лежати токени команди (мусить бути перед тим створено)
    }
    
    function transfer(address to, uint value) returns (bool) //обриває перевід монет якщо ще не розблоковано. Дозволяє переводити тільки від імені ICO, preICO
    {
        if (locked == true && msg.sender != address(ico) && msg.sender != address(pre_ico)) revert();
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint value)  returns (bool) //обриває перевід монет від третього лиця якщо ще не розблоковано.
    {
        if (locked == true) revert();
        return super.transferFrom(from, to, value);
    }

    function init_pre_ico(address _pre_ico) onlyOwner //ініціалізація преICO, отримує параметром адресу контракту, може бути викликана тільки власником
    {
        if (address(0) != address(pre_ico)) revert(); //перервати якщо вже було зроблено
        pre_ico = CrowdCoinPreICO(_pre_ico);//присвоєння в змінну preICO контракту
        mint_tokens(pre_ico, pre_ico_allocation);//виготовлення токенів для нього
    }
    
    function close_pre_ico() onlyOwner //закриваємо preICO
    {
        ico_allocation = add(ico_allocation, _balances[pre_ico]); //додаємо непродану суму в змінну для подальшого створення ICO токенів
        burn_balance(pre_ico); //спалюємо неподане
    }

    function init_ico(address _ico) onlyOwner  //ініціалізація ICO, отримує параметром адресу контракту, може бути викликана тільки власником
    {
        if (address(0) != address(ico) || _balances[pre_ico] > 0) revert();//перервати якщо вже було зроблено, або не була викликана функція закриттяpreICO
        ico = CrowdCoinICO(_ico);//присвоєння в змінну ICO контракту
        mint_tokens(ico, ico_allocation);//виготовлення токенів для нього
    }
    
    function init_bounty_program(address _bounty) onlyOwner //ініціалізація Bounty, отримує параметром адресу контракту, може бути викликана тільки власником
    {
        if (address(0) != address(bounty)) revert();//перервати якщо вже було зроблено
        bounty = _bounty;//присвоєння в змінну bounty адреси
        mint_tokens(bounty, bounty_allocation);//виготовлення токенів для нього
    }
    
    function finalize() onlyOwner { //закриття ICO, виготовлення токенів для команди
        if (ico.successfully_closed() == false || locked == false) revert(); //перервати якщо ICO неуспішне, або це вже було зроблено
        burn_balance(ico); //спалення залишку токенів ICO

        uint256 percentOfTotal = 25; //процент для команди
        uint256 additionalTokens =
            _supply * percentOfTotal / (100 - percentOfTotal); //вираховуємо щоб монет для команди було 25% від кінцевої суми
        
        mint_tokens(team_allocation, additionalTokens); //виготовлення монет для команди
        
        locked = false; //розблокування переводів монети
    }

    function mint_tokens(address addr, uint amount) private  //функція що виготовляє монети, приватна - може бути викликана тільки зсередини контракту
    {
        _balances[addr] = add(_balances[addr], amount); //додаємо до балансу монети
        _supply = add(_supply, amount); //збільшуємо загальну кількість монет
        Transfer(0, addr, amount); //створюємо сповіщення що з 0 гаманця було відправлено монети на певний гаманець
    }
    
    function burn_balance(address addr) private //функція що спалює монети, приватна - може бути викликана тільки зсередини контракту
    {
        uint amount = _balances[addr]; //баланс в змінну
        if (amount > 0)
        {
            _balances[addr] = 0; //обнуляємо
            _supply = sub(_supply, amount); //зменшуємо загальну кількість
            Transfer(addr, 0, amount);//створюємо сповіщення що з певного гаманеця в 0 було відправлено монети
        }
    }
}


contract CrowdCoinPreICO is Owned, DSMath //контракт preICO
{
    CrowdCoin public token;//монета
    address public dev_multisig;//адреса на яку переводити ETH
    
    uint public total_raised;//скільки залучено ETH

    uint public constant price =  0.0005 * 10**18; //ціна монети в wei (1ETH = 1**18 wei)

    function my_token_balance() public constant returns (uint) //баланс монет preICO контракту
    {
        return token.balanceOf(this);
    }

    modifier has_value //мінімальна сума яку можна надіслати, зараз 0,01ETH
    {
        if (msg.value < 0.01 ether) revert();
        _;
    }

    function CrowdCoinPreICO(address _token_address, address _dev_multisig) //коснруктор, присвоює монету і гаманець для ETH
    {
        token = CrowdCoin(_token_address);
        dev_multisig = _dev_multisig;
    }
    
    function () has_value payable external //функція що приймає ETH
    {
        if (my_token_balance() == 0) revert(); //обрив якщо нема що продавати

        var can_buy = wdiv(cast(msg.value), cast(price)); //скільки хоче купити
        var buy_amount = cast(min(can_buy, my_token_balance())); //скільки може купити

        if (can_buy > buy_amount) revert(); //якщо хоче більше чим може обрив

        total_raised = add(total_raised, msg.value);//збільшуємо загальну суму приходу ETH на дану кількість

        dev_multisig.transfer(this.balance); //відправляємо ETH команді
        token.transfer(msg.sender, buy_amount); //переводимо монети покупцю
    }
}

contract CrowdCoinICO is Owned, DSMath  //контракт ICO
{
    CrowdCoin public token;//монета
    address public dev_multisig; //адреса на яку переводити ETH
    
    uint public total_raised; //скільки залучено ETH

    uint public constant start_time = 0; //початок ICO - формат unix timestamp
    uint public constant end_time = 0; //кінець ICO - формат unix timestamp
    uint public constant goal = 100 ether; //необхідний мінімум для успіху
    uint256 public constant default_price = 0.0004 * 10**18; //ціна без бонуса
    
    mapping (uint => uint256) public price; //ціни потижднево

    mapping(address => uint) funded; //запусуємо сюда скільки кожен покупець дав ETH
    
    modifier in_time //дозволить купувати монети тільки після початку і до кінця
    {
        if (time() < start_time || time() > end_time)  revert();
        _;
    }

    function successfully_closed() public constant returns (bool) //каже чи успішнe ICO (має бути забрана мінімальна сума і пройдений час або розпродано все)
    {
        return time() > start_time && (time() > end_time || my_token_balance() == 0) && total_raised >= goal;
    }
    
    function time() public constant returns (uint) //поточний час
    {
        return block.timestamp;
    }
    
    function my_token_balance() public constant returns (uint) //баланс монет в ICO
    {
        return token.balanceOf(this);
    }

    modifier has_value //дозволений мінімум для покупки
    {
        if (msg.value < 0.01 ether) revert();
        _;
    }

    function CrowdCoinICO(address _token_address, address _dev_multisig) //конструктор
    {
        token = CrowdCoin(_token_address); //присвоюєм монету з якою працюємо
        dev_multisig = _dev_multisig;//присвоюєм гаманець на який переводити eth
        
        price[0] = 0.0001 * 10**18; //ціна 1 тиждень
        price[1] = 0.0002 * 10**18; //ціна 2 тиждень
        price[2] = 0.0003 * 10**18; //ціна 3 тиждень
        price[3] = 0.0004 * 10**18; //ціна 4 тиждень
    }
    
    function () has_value in_time payable external //функція для покупки
    {
        if (my_token_balance() == 0) revert(); //якщо всьо розпродали обрив

        var can_buy = wdiv(cast(msg.value), cast(get_current_price())); //скільки хоче
        var buy_amount = cast(min(can_buy, my_token_balance()));//скільки може

        if (can_buy > buy_amount) revert();//якщо хоче більше чим може обрив

        total_raised = add(total_raised, msg.value);//обновляєм зібрану суму

        token.transfer(msg.sender, buy_amount); //переводимо монети покупцю
    }
    
    function refund() //можливість забрати гроші покупцем після завершення якщо мінімум не назбирано
    {
        if (total_raised >= goal || time() < end_time) revert();
        var amount = funded[msg.sender];
        if (amount > 0)
        {
            funded[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }
    
    function collect() //можливість забрати гроші командою, якщо мінімум було зібрано
    {
        if (total_raised < goal) revert();
        dev_multisig.transfer(this.balance);
    }
    
    function get_current_price() constant returns (uint256) { //поточний прайс, залезить від поточного тиждня
        return price[current_week()] == 0 ? default_price : price[current_week()];
    }
    
    function current_week() constant returns (uint) { //поточний тиждень
        return sub(block.timestamp, start_time) / 7 days;
    }
}


contract CrowdDevAllocation is Owned //контракт що зберігатиме монети команди
{
    CrowdCoin public token;//монета
    uint public initial_time;//час від якого відштовхуємося
    address tokens_multisig;//куда відправляти монети

    mapping(uint => bool) public unlocked;//що біло відправлено
    mapping(uint => uint) public unlock_times;//коли можна відправити
    mapping(uint => uint) unlock_values;//скільки можна відправити
    
    function CrowdDevAllocation(address _token)//конструктор, присвоюємо монету
    {
        token = CrowdCoin(_token);
    }
    
    function init() onlyOwner //ініціалізація
    {
        if (token.balanceOf(this) == 0 || initial_time != 0) revert(); //обрив якщо вже ініціалізовано, або нема монет на балансі
        initial_time = block.timestamp; //поточний час, від нього відштовхуємся
        uint256 balance = token.balanceOf(this); //баланс (25% від всіх монет)

        unlock_values[0] = balance / 100 * 33; //перший раз віддати 33%
        unlock_values[1] = balance / 100 * 33; //другий раз віддати 33%
        unlock_values[2] = balance / 100 * 34; //другий раз віддати 34%

        unlock_times[0] = 180 days; //перша порція через 180 днів
        unlock_times[1] = 1080 days; //перша порція через 1080 днів
        unlock_times[2] = 1800 days; //перша порція через 1800 днів
    }

    function unlock(uint part) //виводим монети команди
    {
        if (unlocked[part] == true || block.timestamp < initial_time + unlock_times[part] || unlock_values[part] == 0) revert(); //якщо вже виведено або час ще не настав - обрив
        token.transfer(tokens_multisig, unlock_values[part]); //виводимо
        unlocked[part] = true; //записуємо що партія вже виведена
    }
}

contract MigrationAgent { //інтерфейс контракту що буде виступати в ролі міграційного агента
    function migrateFrom(address _from, uint256 _value);
}
