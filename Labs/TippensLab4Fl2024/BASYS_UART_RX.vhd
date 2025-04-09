library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART2.all;

entity BASYS_UART_RX is
    port(
        clock         : in  std_logic;
        serial_input  : in  std_logic;
        stop_bit      : out std_logic;
        data_byte     : out std_logic_vector(UART_BITS-1 downto 0)
    );
end entity;

architecture rtl of BASYS_UART_RX is
    signal rx_state       : UART_RX_SM := RX_Idle;
    signal clock_count    : integer range 0 to UART_CLKB-1 := 0;
    signal bit_index      : integer range 0 to UART_BITS-1 := 0;
    signal register_byte  : std_logic_vector(UART_BITS-1 downto 0) := (others => '0');
    signal wire_stop_bit  : std_logic := '0';
begin
    statemachine:process(clock)
    begin
        if rising_edge(clock) then
            case rx_state is
                when RX_Idle =>
                    wire_stop_bit <= '0';
                    clock_count   <=  0;
                    bit_index     <=  0;
                    
                    if serial_input = '1' then
                        rx_state <= RX_Start;
                    else
                        rx_state <= RX_Idle;
                    end if;

                when RX_Start =>
                    if clock_count = (UART_CLKB-1) / 2 then
                        if serial_input = '0' then
                            clock_count <= 0;
                            rx_state    <= RX_Data;
                        else
                            rx_state    <= RX_Start;
                        end if;
                    else
                        clock_count <= clock_count + 1;
                        rx_state    <= RX_Start;
                    end if;

                when RX_Data =>
                    if clock_count < UART_CLKB - 1 then
                        clock_count <= clock_count + 1;
                        rx_state    <= RX_Data;
                    else
                        clock_count              <= 0;
                        register_byte(bit_index) <= serial_input;
                        if bit_index < UART_BITS - 1 then
                            bit_index <= bit_index + 1;
                            rx_state  <= RX_Data;
                        else
                            bit_index <= 0;
                            rx_state  <= RX_Stop;
                        end if;
                    end if;
                
                when RX_Stop =>
                    if clock_count < UART_CLKB - 1 then
                        clock_count <= clock_count + 1;
                        rx_state    <= RX_Stop;
                    else
                        wire_stop_bit <= '1';
                        clock_count <= 0;
                        rx_state    <= RX_Cleanup;
                    end if;

                when RX_Cleanup =>
                    rx_state      <= RX_Idle;
                    wire_stop_bit <= '0';

                when others =>
                    rx_state <= RX_Idle;
            end case;
        end if;
    end process;

    stop_bit  <= wire_stop_bit;
    data_byte <= register_byte;
end architecture;
