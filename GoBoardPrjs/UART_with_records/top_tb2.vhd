library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library UART;
use UART.UART_pkg.all;

library TB;
use TB.regular_tb.all;
use TB.UART_tb.all;


entity top_tb2 is
end entity;

architecture test of top_tb2 is
    constant CLK_PERIOD : time := 40 ns;
    constant BIT_PERIOD : time := 8680 ns;

    signal clk        : std_logic := '0';
    signal serial_in  : std_logic := '1';
    signal serial_out : std_logic;

    signal stop_sim  : boolean := false;

    constant test_data : UART_Stimuli_data := (
    (x"4C"),(x"30"),(x"31"),(x"32"),(x"33"),(x"4D")
    );


begin
    top_inst: entity work.top
     port map(
        i_Clk        => clk,
        i_UART_RX    => serial_in,
        o_UART_TX    => serial_out,
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
    clocking:process
    begin
        while stop_sim = false loop
            wait for CLK_PERIOD / 2;
            clk <= not clk;
        end loop;
        wait;
    end process;

    stimulation:process
        alias record_bring is <<signal top_inst.TX_MASTER_OUTS : UART_TX_OUT>>;
    begin
        wait until rising_edge(clk);

        for i in test_data'range loop
            report "Writing to UART iteration: " & to_string(i+1);

            write_UART(test_data(i), serial_in, BIT_PERIOD);
            wait until record_bring.TX_DONE = '1';
        end loop;

        wait for BIT_PERIOD;
        report "All bits sent";
        wait;

    end process;

    rxchecker:process
        alias record_bring is <<signal top_inst.RX_MASTER_OUTS : UART_RX_OUT>>;
        alias receive_byte is record_bring.RX_BYTE;
    begin
        for i in test_data'range loop
            wait until record_bring.RX_STOPBIT = '1';
            assert_eq("Receive matching check", receive_byte, test_data(i));
        end loop;
        report "Passed all RX Tests";
        wait;
    end process;


    txchecker:process
        alias transmit_outs is <<signal top_inst.TX_MASTER_OUTS  : UART_TX_OUT>>;
    begin
        for i in test_data'range loop
            check_TX(test_data(i), transmit_outs, BIT_PERIOD, CLK_PERIOD);
            report "Completed " & to_string(i+1) &  " iteration of txchecker";
        end loop;
        report "Passed all TX Tests";
        stop_sim <= true;
        wait;
    end process;

end architecture;
