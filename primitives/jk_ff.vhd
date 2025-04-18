library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity jk_ff is
    port(
        clk : in  std_logic;
        j   : in  std_logic;
        k   : in  std_logic;
        q   : out std_logic;
        qb  : out std_logic
    );
end entity;

architecture rtl of jk_ff is
    signal q_temp  : std_logic := '0';
    signal qb_temp : std_logic := '1';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            case std_logic_vector'(j & k) is --type qualification expression. Fun stuff.
                when "00" => null;
                when "01" =>
                    q_temp  <= '0';
                    qb_temp <= '1';
                when "10" =>
                    q_temp  <= '1';
                    qb_temp <= '0';
                when "11" =>
                    q_temp  <= not q;
                    qb_temp <= not qb;
                when others => null;
            end case;
        end if;
    end process;

    q  <= q_temp;
    qb <= qb_temp;

end architecture;
