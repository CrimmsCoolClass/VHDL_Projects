library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART2.all;

entity BASYS_UART_TX is
    port(
        clock           : in  std_logic;
        stop_bit        : in  std_logic;
        transmit_byte   : in  std_logic_vector(UART_BITS-1 downto 0);
        transmit_active : out std_logic;
        transmit_serial : out std_logic;
        transmit_done   : out std_logic 
    );
end entity;

architecture rtl of BASYS_UART_TX is
    signal tx_state       : UART_TX_SM := TX_Idle;
    signal clock_count    : integer range 0 to UART_CLKB-1 := 0;
    signal bit_index      : integer range 0 to UART_BITS-1 := 0;
    signal register_byte  : std_logic_vector(UART_BITS-1 downto 0) := (others => '0');
    signal tx_done_bit    : std_logic := '0';
begin
    statemachine:process(clock)
    begin
        if rising_edge(clock) then
            tx_done_bit <= '0';
            case tx_state is

                when TX_Idle => 
                    transmit_active <= '0';
                    transmit_serial <= '1';
                    clock_count     <=  0;
                    bit_index       <=  0;
                    if stop_bit = '1' then
                        register_byte <= transmit_byte;
                        tx_state      <= TX_Start;
                    else
                        tx_state      <= TX_Idle;
                    end if;

                when TX_Start =>
                    transmit_active <= '1';
                    transmit_serial <= '0';
                    if clock_count < UART_CLKB - 1 then
                        clock_count <= clock_count + 1;
                        tx_state    <= TX_Start;
                    else
                        clock_count <= 0;
                        tx_state    <= TX_Data;
                    end if;

                when TX_Data =>
                    transmit_serial <= register_byte(bit_index);
                    if clock_count < UART_CLKB - 1 then
                        clock_count <= clock_count + 1;
                        tx_state    <= TX_Data;
                    else
                        clock_count <= 0;
                        if bit_index < UART_BITS - 1 then
                            bit_index <= bit_index + 1;
                            tx_state  <= TX_Data;
                        else
                            bit_index <= 0;
                            tx_state  <= TX_Stop;
                        end if;
                    end if;

                when TX_Stop =>
                    transmit_serial <= '1';
                    if clock_count < UART_CLKB - 1 then
                        clock_count <= clock_count + 1;
                        tx_state    <= TX_Stop;
                    else
                        tx_done_bit <= '1';
                        clock_count <= 0;
                        tx_state    <= TX_Cleanup;
                    end if;

                when TX_Cleanup =>
                    transmit_active <= '0';
                    tx_state        <= TX_Idle;

                when others =>
                    tx_state <= TX_Idle;

            end case;
        end if;
    end process;

    transmit_done <= tx_done_bit;
    
end architecture;
