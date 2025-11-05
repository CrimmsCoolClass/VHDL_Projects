library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UART;
use UART.UART_pkg.all;

entity top is
    generic(
        UART_FREQ : integer := 25_000_000;
        UART_BAUD : integer := 115200;
        UART_BITS : integer := 8;
        UART_CLKB : integer := UART_FREQ / UART_BAUD
    );
    port(
        i_Clk        : in  std_logic;
        i_UART_RX    : in  std_logic;
        o_UART_TX    : out std_logic;
        o_Segment1_A : out std_logic;
        o_Segment1_B : out std_logic;
        o_Segment1_C : out std_logic;
        o_Segment1_D : out std_logic;
        o_Segment1_E : out std_logic;
        o_Segment1_F : out std_logic;
        o_Segment1_G : out std_logic;
     
        o_Segment2_A : out std_logic;
        o_Segment2_B : out std_logic;
        o_Segment2_C : out std_logic;
        o_Segment2_D : out std_logic;
        o_Segment2_E : out std_logic;
        o_Segment2_F : out std_logic;
        o_Segment2_G : out std_logic
    );
end entity;

architecture rtl of top is
    signal RX_MASTER_INPUT : UART_RX_IN;
    signal RX_MASTER_OUTS  : UART_RX_OUT;
    signal TX_MASTER_INPUT : UART_TX_IN;
    signal TX_MASTER_OUTS  : UART_TX_OUT;
    
    signal segs1, segs2 : std_logic_vector(6 downto 0);

    function to_ssdca(input: std_logic_vector) return std_logic_vector is
        begin
            case input is
                when "0000" => return "0000001";
                when "0001" => return "1001111";
                when "0010" => return "0010010";
                when "0011" => return "0000110";
                when "0100" => return "1001100";
                when "0101" => return "0100100";
                when "0110" => return "0100000";
                when "0111" => return "0001111";
                when "1000" => return "0000000";
                when "1001" => return "0001100";
                when "1010" => return "0001000";
                when "1011" => return "1100000";
                when "1100" => return "0110001";
                when "1101" => return "1000010";
                when "1110" => return "0110000";
                when "1111" => return "0111000";
                when others => return "1111111";
            end case;
    end function to_ssdca;
begin

    UART_RX_inst: entity UART.UART_RX
     generic map(
        UART_FREQ        => UART_FREQ,
        UART_BAUD        => UART_BAUD,
        UART_BITS        => UART_BITS,
        UART_CLK_PER_BIT => UART_CLKB
    )
     port map(
        clk          => i_Clk,
        uart_inputs  => RX_MASTER_INPUT,
        uart_outputs => RX_MASTER_OUTS
    );

    UART_TX_inst: entity UART.UART_TX
     generic map(
        UART_FREQ        => UART_FREQ,
        UART_BAUD        => UART_BAUD,
        UART_BITS        => UART_BITS,
        UART_CLK_PER_BIT => UART_CLKB
    )
     port map(
        clk          => i_Clk,
        uart_inputs  => TX_MASTER_INPUT,
        uart_outputs => TX_MASTER_OUTS
    );
    TX_MASTER_INPUT.TX_STARTBIT <= RX_MASTER_OUTS.RX_STOPBIT;
    TX_MASTER_INPUT.TX_BYTE     <= RX_MASTER_OUTS.RX_BYTE;
    RX_MASTER_INPUT.RX_SERIAL   <= i_UART_RX;                   
    o_UART_TX                   <= TX_MASTER_OUTS.TX_SERIAL when TX_MASTER_OUTS.TX_ACTIVATE else '1';

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            segs1 <= to_ssdca(RX_MASTER_OUTS.RX_BYTE(7 downto 4));
        end if;
    end process;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            segs2 <= to_ssdca(RX_MASTER_OUTS.RX_BYTE(3 downto 0));
        end if;
    end process;

    (o_segment1_A,o_segment1_B,o_segment1_C,o_segment1_D,o_segment1_E,o_segment1_F,o_segment1_G) <= segs1;
    (o_segment2_A,o_segment2_B,o_segment2_C,o_segment2_D,o_segment2_E,o_segment2_F,o_segment2_G) <= segs2;
end architecture;
