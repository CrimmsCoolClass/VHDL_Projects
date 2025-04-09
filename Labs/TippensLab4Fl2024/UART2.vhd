package UART2 is new work.UART_pkg
generic map(UART_FREQ => 100_000_000, UART_BAUD => 115_200, UART_BITS => 8);
