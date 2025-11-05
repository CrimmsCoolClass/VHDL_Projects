library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART_inst.all;

entity UART_TX is
    generic(
        UART_FREQ        : integer;
        UART_BAUD        : integer;
        UART_BITS        : integer;
        UART_CLK_PER_BIT : integer := UART_FREQ / UART_BAUD
    );
    port(
        i_Clk       : in  std_logic;
        i_TX_DV     : in  std_logic;
        i_TX_Byte   : in  std_logic_vector(UART_BITS - 1 downto 0);
        o_TX_Active : out std_logic;
        o_TX_Serial : out std_logic;
        o_TX_Done   : out std_logic
    );
end entity;

architecture rtl of UART_TX is
    signal State     : UART_TX_SM := TX_Idle;
    signal clk_count : integer range 0 to UART_CLKB - 1 := 0;
    signal bit_index : integer range 0 to UART_BITS - 1 := 0;
    signal TX_Byte   : std_logic_vector(UART_BITS - 1 downto 0) := (others => '0');
    signal TX_done     : std_logic := '0';
begin
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            TX_done <= '0';
            case State is
                when TX_Idle =>
                    o_TX_Active <= '0';
                    o_TX_Serial <= '1';
                    clk_count <= 0;
                    bit_index <= 0;
                    if i_TX_DV = '1' then
                        TX_Byte <= i_TX_Byte;
                        State <= TX_Start;
                    else
                        State <= TX_Idle;
                    end if;
                when TX_Start =>
                    o_TX_Active <= '1';
                    o_TX_Serial <= '0';
                    if clk_count < (UART_CLKB - 1) then
                        clk_count <= clk_count + 1;
                        State <= TX_Start;
                    else
                        clk_count <= 0;
                        State <= TX_Data;
                    end if;
                when TX_Data =>
                    o_TX_Serial <= TX_Byte(bit_index);
                    if clk_count < UART_CLKB - 1 then
                        clk_count <= clk_count + 1;
                        State <= TX_Data;
                    else
                        clk_count <= 0;
                        if bit_index <  UART_BITS - 1 then
                            bit_index <= bit_index + 1;
                            State <= TX_Data;
                        else
                            bit_index <= 0;
                            State <= TX_Stop;
                        end if;
                    end if;
                when TX_Stop =>
                    o_TX_Serial <= '1';
                    if clk_count < UART_CLKB - 1 then
                        clk_count <= clk_count + 1;
                        State <= TX_Stop;
                    else
                        TX_done <= '1';
                        clk_count <= 0;
                        State <= TX_Cleanup;
                    end if;
                when TX_Cleanup => 
                    State <= TX_Idle;
                    o_TX_Active <= '0';
                when others =>
                    State <= TX_Idle;
            end case;
        end if;
    end process;

    o_TX_Done <= TX_Done;


end architecture;
