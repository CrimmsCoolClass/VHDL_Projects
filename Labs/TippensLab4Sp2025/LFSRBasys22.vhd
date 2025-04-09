library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LFSRBasys22 is
    port(
        clk   : in  std_logic;
        btnD  : in  std_logic; --reset
        btnC  : in  std_logic; --set
        led   : out std_logic_vector(15 downto 0);
        an    : out std_logic_vector(3  downto 0);
        seg   : out std_logic_vector(6  downto 0)
    );
end entity;

architecture rtl of LFSRBasys22 is
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
    type statetype   is (IDLE, STORE, DISPLAY, CLEANUP, RESET);

    signal ledpos        : integer := 0;
    signal dsegl         : integer := 0;
    signal dsegm         : integer := 0;
    signal storage       : storedvalue;
    signal LSFR_register : std_logic_vector(4 downto 1) := (others => '0');
    signal xnor_wire     : std_logic;
    signal state         : statetype := IDLE;

begin

    statemachinetransition:process(clk,btnD)
        variable count : integer := 0;
    begin
        if btnD = '1' then
            state <= CLEANUP;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    ledpos <= 12345;
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
                    if count < 99_999_999 then
                        ledpos <= to_integer(unsigned(storage(1)));
                        count := count + 1;
                    elsif count < 199_999_999 then
                        ledpos <= to_integer(unsigned(storage(2)));
                        count := count + 1;
                    elsif count < 299_999_999 then
                        ledpos <= to_integer(unsigned(storage(3)));
                        count := count + 1;
                    elsif count < 399_999_999 then
                        ledpos <= to_integer(unsigned(storage(4)));
                        count := count + 1;
                    elsif count < 499_999_999 then
                        ledpos <= to_integer(unsigned(storage(5)));
                        count := count + 1;
                    else
                        state <= CLEANUP;
                    end if;
                when CLEANUP =>
                    ledpos <= 12345;
                    count := 0;
                    storage <= (others => (others => '0'));
                    state <= IDLE;
                when others => state <= IDLE;
            end case;           
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

    ledlightup:process(clk)
    begin
        if rising_edge(clk) then
            if ledpos /= 12345 then
                for i in 0 to 15 loop
                    if ledpos = i then
                        led(i) <= '1';
                    elsif ledpos /= i then
                        led(i) <= '0';
                    end if;
                end loop;
            else
                led <= (others => '0');
            end if;
        end if;
    end process;

    dsegl <= ledpos mod 10 when ledpos /= 12345 else 16; --least significant digit
    dsegm <= ledpos / 10   when ledpos /= 12345 else 16; --most significant digit

    segmultiplex:process(clk)
        variable count: integer := 0;
    begin
        if rising_edge(clk) then
            if count < 99_999 then
                an <= "0111";
                seg <= to_ssdca(ledpos);  
                count := count + 1;
            elsif count < 199_999 then
                an <= "1101";
                seg <= to_ssdca(dsegm);
                count := count + 1;
            elsif count < 299_999 then
                an <= "1110";
                seg <= to_ssdca(dsegl);
                count := count + 1;
            else 
                count := 0;
            end if;
        end if;
    end process;

end architecture;
