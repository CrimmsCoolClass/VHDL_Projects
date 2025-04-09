library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package UART_pkg is
    generic(
        UART_FREQ : integer;
        UART_BAUD : integer;
        UART_BITS : integer;
        UART_CLKB : integer := UART_FREQ / UART_BAUD
    ); 

    type UART_RX_SM is (RX_Idle, RX_Start, RX_Data, RX_Stop, RX_Cleanup);
    type UART_TX_SM is (TX_Idle, TX_Start, TX_Data, TX_Stop, TX_Cleanup);

end package;
