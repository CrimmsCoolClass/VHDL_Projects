library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART_inst.all;

entity top is
    port(
        i_Clk     : in  std_logic;
        i_UART_RX : in  std_logic;
        o_UART_TX : out std_logic;
    o_Segment1_A  : out std_logic;
    o_Segment1_B  : out std_logic;
    o_Segment1_C  : out std_logic;
    o_Segment1_D  : out std_logic;
    o_Segment1_E  : out std_logic;
    o_Segment1_F  : out std_logic;
    o_Segment1_G  : out std_logic;
     
    o_Segment2_A  : out std_logic;
    o_Segment2_B  : out std_logic;
    o_Segment2_C  : out std_logic;
    o_Segment2_D  : out std_logic;
    o_Segment2_E  : out std_logic;
    o_Segment2_F  : out std_logic;
    o_Segment2_G  : out std_logic
    );
end entity;

architecture rtl of top is
    signal w_RX_DV     : std_logic;
    signal w_RX_Byte   : std_logic_vector(7 downto 0);
    signal w_TX_Active : std_logic;
    signal w_TX_Serial : std_logic;
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
    UART_TX_inst: entity work.UART_TX
     port map(
        i_Clk       => i_Clk,
        i_TX_DV     => w_RX_DV,
        i_TX_Byte   => w_RX_Byte,
        o_TX_Active => w_TX_Active,
        o_TX_Serial => w_TX_Serial,
        o_TX_Done   => open 
    );

    UART_RX_inst: entity work.UART_RX
     port map(
        i_Clk       => i_Clk,
        i_RX_Serial => i_UART_RX,
        o_RX_DV     => w_RX_DV,
        o_RX_Byte   => w_RX_Byte
    );

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            segs1 <= to_ssdca(w_rx_byte(7 downto 4));
        end if;
    end process;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            segs2 <= to_ssdca(w_rx_byte(3 downto 0));
        end if;
    end process;

    o_UART_TX <= w_TX_Serial when w_TX_Active = '1' else '1';
    (o_segment1_A,o_segment1_B,o_segment1_C,o_segment1_D,o_segment1_E,o_segment1_F,o_segment1_G) <= segs1;
    (o_segment2_A,o_segment2_B,o_segment2_C,o_segment2_D,o_segment2_E,o_segment2_F,o_segment2_G) <= segs2;

       





    

end architecture;
