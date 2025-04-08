library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tiplab1 is
    port(
        normal_ref : in  std_logic_vector(2 downto 0);
        head_ref   : in  std_logic;
        call       : out std_logic
    );
end entity;

architecture rtl of tiplab1 is
    signal referees : std_logic_vector(3 downto 0);
begin
    referees <= head_ref & normal_ref;

    with referees select
        call <= '0' when "0000",
                '0' when "0001",
                '0' when "0010",
                '0' when "0011",
                '0' when "0100",
                '0' when "0101",
                '0' when "0110",
                '1' when "0111",
                '0' when "1000",
                '1' when others;
    
    

end architecture;
