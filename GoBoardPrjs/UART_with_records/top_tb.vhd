library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UART;
use UART.UART_pkg.all;

entity top_tb is
end entity;

architecture test of top_tb is
    constant CLK_PERIOD : time := 40 ns;
    constant BIT_PERIOD : time := 8680 ns;

    signal clk       : std_logic := '0';
    signal serial_in : std_logic := '1';

    signal stop_sim  : boolean := false;

    procedure write_to_UART(in_byte : in std_logic_vector(7 downto 0); signal out_serial : out std_logic) is
    begin
        out_serial <= '0';
        wait for BIT_PERIOD;

        for i in 0 to 7 loop
            out_serial <= in_byte(i);
            wait for BIT_PERIOD;
        end loop;
        out_serial <= '1';
        wait for BIT_PERIOD;
    end procedure;
begin
    top_inst: entity work.top
     port map(
        i_Clk        => clk,
        i_UART_RX    => serial_in,
        o_UART_TX    => open,
        o_Segment1_A => open,
        o_Segment1_B => open,
        o_Segment1_C => open,
        o_Segment1_D => open,
        o_Segment1_E => open,
        o_Segment1_F => open,
        o_Segment1_G => open,
        o_Segment2_A => open,
        o_Segment2_B => open,
        o_Segment2_C => open,
        o_Segment2_D => open,
        o_Segment2_E => open,
        o_Segment2_F => open,
        o_Segment2_G => open 
    );
    process
    begin
        while stop_sim = false loop
            wait for CLK_PERIOD / 2;
            clk <= not clk;
        end loop;
        wait;
    end process;

    process
        alias transmitter is <<signal top_inst.TX_MASTER_OUTS : UART_TX_OUT>>;
    begin
        wait until rising_edge(clk);
        write_to_UART("01001100",serial_in);
        wait until transmitter.TX_DONE = '1'; 
        write_to_UART(X"30",serial_in);
        report "Debug Statement 2";
        wait until transmitter.TX_DONE = '1'; 
        write_to_UART(X"4D",serial_in);
        wait until transmitter.TX_DONE = '1';
        stop_sim <= true;
        report "End of testing!";
        wait;
    end process;
    

end architecture;
