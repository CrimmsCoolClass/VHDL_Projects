library lib1;
package UART_inst is new lib1.UART_pkg
generic map (UART_FREQ => 25_000_000, UART_BAUD => 115200, UART_BITS => 8);
