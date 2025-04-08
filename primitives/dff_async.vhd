library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dff is
    port(
        clk    : in  std_logic;
        areset : in  std_logic;
        d      : in  std_logic;
        q      : out std_logic;
        qb     : out std_logic
    );
end entity;

architecture rtl of dff is
    signal tempq  : std_logic := '0';
    signal tempqb : std_logic := '1';
begin
    process(clk,areset)
    begin
        if areset then
            tempq  <= '0';
            tempqb <= '1';
        elsif rising_edge(clk) then
            tempq  <= d;
            tempqb <= not d;
        end if;
    end process;
    
    q  <= tempq;
    qb <= tempqb;
end architecture;
