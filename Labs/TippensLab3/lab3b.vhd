library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity lab3b is
    port(
        clk: in std_logic;
        btnL,btnR: in std_logic;
        led: out std_logic_vector(15 downto 0);
        an: out std_logic_vector(3 downto 0);
        seg: out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of lab3b is
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

    constant DBOUNCE: integer := 1_000_000;
    signal sldb, slt, srdb, srt: std_logic;
    signal dsegm, dsegl: integer;
    signal ledpos: integer := 0;
begin
    dbl:process(clk)
        variable count: integer := 0;
    begin
        if rising_edge(clk) then
            if btnL /= sldb and count < DBOUNCE then
                count := count + 1;
            elsif count = DBOUNCE then
                sldb <= btnL;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    dbr:process(clk)
        variable count: integer := 0;
    begin
        if rising_edge(clk) then
            if btnR /= srdb and count < DBOUNCE then
                count := count + 1;
            elsif count = DBOUNCE then
                srdb <= btnR;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    ledposhand:process(clk)
    begin
        if rising_edge(clk) then
            slt <= sldb;
            srt <= srdb;
            if sldb = '1' and slt = '0' and ledpos < 15 then
                ledpos <= ledpos + 1;
            elsif srdb = '1' and srt = '0' and ledpos > 0 then
                ledpos <= ledpos - 1;
            end if;
        end if;
    end process;

    ledlightup:process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 15 loop
                if ledpos = i then
                    led(i) <= '1';
                elsif ledpos /= i then
                    led(i) <= '0';
                end if;
            end loop;
        end if;
    end process;

    dsegl <= ledpos mod 10; --least significant digit
    dsegm <= ledpos / 10; --most significant digit

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


