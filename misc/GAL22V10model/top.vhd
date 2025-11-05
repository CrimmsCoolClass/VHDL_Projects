library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
    port(
        I  : in    std_logic_vector(11 downto 0); --I(0) is clk
        IO : inout std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of top is
    type fusemap is array (0 to 740) of std_logic_vector(7 downto 0);

    signal jed   : fusemap;
    signal fuses : std_logic_vector(5891 downto 0);
begin

    

end architecture;
