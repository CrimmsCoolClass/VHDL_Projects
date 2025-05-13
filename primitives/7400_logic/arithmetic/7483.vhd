library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity design is
    port(
        A1 : in  std_logic;
        A2 : in  std_logic;
        A3 : in  std_logic;
        A4 : in  std_logic;
        B1 : in  std_logic;
        B2 : in  std_logic;
        B3 : in  std_logic;
        B4 : in  std_logic;
        C0 : in  std_logic;
        S1 : out std_logic;
        S2 : out std_logic;
        S3 : out std_logic;
        S4 : out std_logic;
        C4 : out std_logic
    );
end entity;

architecture rtl of design is
    signal A_input : std_logic_vector(3 downto 0) := (others => '0');
    signal B_input : std_logic_vector(3 downto 0) := (others => '0');
    signal Sum     : unsigned(4 downto 0) := (others => '0');
begin
    A_input <= (A4, A3, A2, A1);
    B_input <= (B4, B3, B2, B1);

    Sum <= resize(unsigned(A_input),5) + resize(unsigned(B_input),5) + unsigned'('0' & C0);
    
    (C4, S4, S3, S2, S1) <= std_logic_vector(Sum);


end architecture;
