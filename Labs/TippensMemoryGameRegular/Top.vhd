library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Top is
    port(
        clk   : in  std_logic;
        btnD  : in  std_logic; --reset
        btnC  : in  std_logic; --set
        sw    : in  std_logic_vector(15 downto 0);
        led   : out std_logic_vector(15 downto 0);
        an    : out std_logic_vector(3  downto 0);
        seg   : out std_logic_vector(6  downto 0)
    );
end entity;

architecture rtl of Top is
    function to_ssdca(input: integer) return std_logic_vector is
    begin
        case input is
            when 0      => return "1000000";
            when 1      => return "1111001";
            when 2      => return "0100100";
            when 3      => return "0110000";
            when 4      => return "0011001";
            when 5      => return "0010010";
            when 6      => return "0000010";
            when 7      => return "1111000";
            when 8      => return "0000000";
            when 9      => return "0011000";
            when 10     => return "0001000";
            when 11     => return "0000011";
            when 12     => return "1000110";
            when 13     => return "0100001";
            when 14     => return "0000110";
            when 15     => return "0001110";
            when others => return "1111111";
        end case;
    end function to_ssdca;

    type storedvalue is array (1 to 5) of std_logic_vector(3 downto 0);
    type statetype   is (IDLE, STORE, DISPLAY, GUESS1, GUESS2, GUESS3, GUESS4, GUESS5, NOSWS, ROUNDEND, LOSE, WIN, GAMECLEANUP);

    constant FIVE_HUNDRED_MS  : integer := 50_000_000;
    constant THREE_HUNDRED_MS : integer := 30_000_000;
    constant ONE_HUNDRED_MS   : integer := 10_000_000;
    constant DBOUNCE          : integer := 1_000_000;
    

    signal ledposition   : integer := 12345;
    signal MSD_segment   : integer := 0;
    signal LSD_segment   : integer := 0;
    signal gamescore     : integer := 0;

    signal state         : statetype := IDLE;
    signal storage       : storedvalue := (others => (others => '0'));

    signal LSFR_register : std_logic_vector(4 downto 1) := (others => '0');
    signal debounce_sw   : std_logic_vector(15 downto 0) := (others => '0');

    signal xnor_wire     : std_logic;
    
begin

    debounceswitches:process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if sw /= debounce_sw and count < DBOUNCE then
                count := count + 1;
            elsif count = DBOUNCE then
                debounce_sw <= sw;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;


    generatenumber:process(clk,btnD)
    begin
        if btnD = '1' then
            LSFR_register <= (others => '0');
        elsif rising_edge(clk) then
            LSFR_register <= LSFR_register(LSFR_register'left-1 downto 1) & xnor_wire;
        end if;
    end process;

    xnor_wire <= LSFR_register(4) xnor LSFR_register(3);


    memorygameplay:process(clk, btnD)
        variable count         : integer := 0;
        variable timing_magic  : integer := FIVE_HUNDRED_MS;
        variable guess_tracker : integer := 1;
        variable stop_scoring  : boolean := false;
    begin
        if btnD then
            state <= GAMECLEANUP;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    count := 0;
                    stop_scoring := false;
                    ledposition <= 12345;
                    if btnC = '1' then
                        state <= STORE;
                    end if;

                when STORE =>
                    if count < 5 then 
                        count := count + 1;
                        storage(count) <= LSFR_register;
                    else 
                        count := 0;
                        state <= DISPLAY;
                    end if;

                when DISPLAY =>
                    case gamescore is
                        when 0  => timing_magic := FIVE_HUNDRED_MS;
                        when 5  => timing_magic := THREE_HUNDRED_MS;
                        when 10 => timing_magic := ONE_HUNDRED_MS;
                        when others => timing_magic := FIVE_HUNDRED_MS;
                    end case;

                    if count < timing_magic - 1 then
                        ledposition <= to_integer(unsigned(storage(1)));
                        count := count + 1; 
                    elsif count < (timing_magic + timing_magic) - 1 then --nextpnr flails and dies when you try to multiply variables
                        ledposition <= to_integer(unsigned(storage(2)));
                        count := count + 1;
                    elsif count < (timing_magic + timing_magic + timing_magic) - 1 then
                        ledposition <= to_integer(unsigned(storage(3)));
                        count := count + 1;
                    elsif count < (timing_magic + timing_magic + timing_magic + timing_magic) - 1 then
                        ledposition <= to_integer(unsigned(storage(4)));
                        count := count + 1;  
                    elsif count < (timing_magic + timing_magic + timing_magic + timing_magic + timing_magic) - 1 then
                        ledposition <= to_integer(unsigned(storage(5)));
                        count := count + 1;
                    else 
                        ledposition <= 12345;
                        count := 0;
                        state <= NOSWS;
                    end if;

                when NOSWS =>
                    if debounce_sw = "0000000000000000" then
                        if guess_tracker = 1 then
                            state <= GUESS1;
                        elsif guess_tracker = 2 then
                            state <= GUESS2;
                        elsif guess_tracker = 3 then
                            state <= GUESS3;
                        elsif guess_tracker = 4 then
                            state <= GUESS4;
                        elsif guess_tracker = 5 then
                            state <= GUESS5;
                        end if;
                    end if;

                when GUESS1 =>
                    if debounce_sw /= "0000000000000000" then
                        for i in 0 to 15 loop
                            if debounce_sw(i) = '1' and i /= to_integer(unsigned(storage(1))) then
                                state <= LOSE;
                                exit;
                            elsif debounce_sw(i) = '1' and i = to_integer(unsigned(storage(1))) then
                                guess_tracker := guess_tracker + 1;
                                state <= NOSWS;
                            end if;
                        end loop;
                    end if;

                when GUESS2 =>
                    if debounce_sw /= "0000000000000000" then
                        for i in 0 to 15 loop
                            if debounce_sw(i) = '1' and i /= to_integer(unsigned(storage(2))) then
                                state <= LOSE;
                                exit;
                            elsif debounce_sw(i) = '1' and i = to_integer(unsigned(storage(2))) then
                                guess_tracker := guess_tracker + 1;
                                state <= NOSWS;
                            end if;
                        end loop;
                    end if;

                when GUESS3 =>
                    if debounce_sw /= "0000000000000000" then
                        for i in 0 to 15 loop
                            if debounce_sw(i) = '1' and i /= to_integer(unsigned(storage(3))) then
                                state <= LOSE;
                                exit;
                            elsif debounce_sw(i) = '1' and i = to_integer(unsigned(storage(3))) then
                                guess_tracker := guess_tracker + 1;
                                state <= NOSWS;
                            end if;
                        end loop;
                    end if;

                when GUESS4 =>
                    if debounce_sw /= "0000000000000000" then
                        for i in 0 to 15 loop
                            if debounce_sw(i) = '1' and i /= to_integer(unsigned(storage(4))) then
                                state <= LOSE;
                                exit;
                            elsif debounce_sw(i) = '1' and i = to_integer(unsigned(storage(4))) then
                                guess_tracker := guess_tracker + 1;
                                state <= NOSWS;
                            end if;
                        end loop;
                    end if;

                when GUESS5 =>
                    if debounce_sw /= "0000000000000000" then
                        for i in 0 to 15 loop
                            if debounce_sw(i) = '1' and i /= to_integer(unsigned(storage(5))) then
                                state <= LOSE;
                                exit;
                            elsif debounce_sw(i) = '1' and i = to_integer(unsigned(storage(5))) then
                                guess_tracker := guess_tracker + 1;
                                state <= ROUNDEND;
                            end if;
                        end loop;
                    end if;

                when ROUNDEND =>
                    guess_tracker := 1;
                    if count < 100_000_000 - 1 then
                        count := count + 1;
                    elsif count = 100_000_000 then
                        gamescore <= gamescore + 1;
                        count := count + 1;
                    elsif count < 200_000_000 - 1 then
                        count := count + 1;
                    elsif count = 200_000_000 then
                        gamescore <= gamescore + 1;
                        count := count + 1;
                    elsif count < 300_000_000 - 1 then
                        count := count + 1;
                    elsif count = 300_000_000 then
                        gamescore <= gamescore + 1;
                        count := count + 1;
                    elsif count < 400_000_000 - 1 then
                        count := count + 1;
                    elsif count = 400_000_000 then
                        gamescore <= gamescore + 1;
                        count := count + 1;
                    elsif count < 500_000_000 - 1 then
                        count := count + 1;
                    elsif count = 500_000_000 then
                        gamescore <= gamescore + 1;
                        count := count + 1;
                    else
                        count := 0;
                        stop_scoring := true;
                    end if;

                    if stop_scoring = true and gamescore = 15 then
                        state <= WIN;
                    elsif stop_scoring = true and gamescore mod 5 = 0 and gamescore /= 0 then
                        state <= IDLE;
                    end if;
                when LOSE =>
                    stop_scoring := false;
                    gamescore <= 0;
                    --LEDS are controlled in own process
                    --Hit reset to go back to start

                when WIN =>
                    stop_scoring := false;
                    --LEDS are controlled in own process
                    --Hit reset to go back to start
                when GAMECLEANUP =>
                    count := 0;
                    timing_magic := FIVE_HUNDRED_MS;
                    gamescore <= 0;
                    guess_tracker := 1;

                    state <= IDLE;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

    ledlightup:process(clk)
    begin
        if rising_edge(clk) then
            if state = DISPLAY then
                for i in 0 to 15 loop
                    if ledposition = i then
                        led(i) <= '1';
                    elsif ledposition /= i then
                        led(i) <= '0';
                    end if;
                end loop;
            elsif state = WIN then
                led <= (others => '1');
            else
                led <= (others => '0');
            end if;
        end if;
    end process;


    LSD_segment <= gamescore mod 10;
    MSD_segment <= gamescore / 10;   

    segmultiplex:process(clk)
        variable count: integer := 0;
    begin
        if rising_edge(clk) then
            if count < 99_999 then
                an <= "1101";
                seg <= to_ssdca(MSD_segment);
                count := count + 1;
            elsif count < 199_999 then
                an <= "1110";
                seg <= to_ssdca(LSD_segment);
                count := count + 1;
            else 
                count := 0;
            end if;
        end if;
    end process;
    
    

end architecture;
