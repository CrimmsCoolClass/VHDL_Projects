library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART_inst.all;

entity UART_RX is
    generic(
        UART_FREQ        : integer;
        UART_BAUD        : integer;
        UART_BITS        : integer;
        UART_CLK_PER_BIT : integer := UART_FREQ / UART_BAUD
    );
    port(
        i_Clk       : in  std_logic;
        i_RX_Serial : in  std_logic;
        o_RX_DV     : out std_logic;
        o_RX_Byte   : out std_logic_vector(UART_BITS - 1 downto 0)
    );
end entity;

architecture rtl of UART_RX is
    signal State     : UART_RX_SM := RX_Idle;
    signal clk_count : integer range 0 to UART_CLKB - 1 := 0;
    signal bit_index : integer range 0 to UART_BITS - 1 := 0;
    signal RX_Byte   : std_logic_vector(UART_BITS - 1 downto 0) := (others => '0');
    signal RX_dv     : std_logic := '0';
begin
    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            case State is
                when RX_Idle =>
                    RX_dv     <= '0';
                    clk_count <= 0;
                    bit_index <= 0;
                    if i_RX_Serial = '0' then
                        State <= RX_Start;
                    else
                        State <= RX_Idle;
                    end if;
                when RX_Start =>
                    if clk_count = (UART_CLKB - 1) / 2 then
                        if i_RX_Serial = '0' then
                            clk_count <= 0;
                            State <= RX_Data;
                        else
                            State <= RX_Start;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                        State <= RX_Start;
                    end if;
                when RX_Data =>
                    if clk_count < UART_CLKB - 1 then
                        clk_count <= clk_count + 1;
                        State <= RX_Data;
                    else
                        clk_count <= 0;
                        RX_Byte(bit_index) <= i_RX_Serial;
                        if bit_index <  UART_BITS - 1 then
                            bit_index <= bit_index + 1;
                            State <= RX_Data;
                        else
                            bit_index <= 0;
                            State <= RX_Stop;
                        end if;
                    end if;
                when RX_Stop =>
                    if clk_count < UART_CLKB - 1 then
                        clk_count <= clk_count + 1;
                        State <= RX_Stop;
                    else
                        RX_dv <= '1';
                        clk_count <= 0;
                        State <= RX_Cleanup;
                    end if;
                when RX_Cleanup => 
                    State <= RX_Idle;
                    RX_dv <= '0';
                when others =>
                    State <= RX_Idle;
            end case;
        end if;
    end process;

    o_RX_DV <= RX_Dv;
    o_RX_Byte <= RX_Byte;


end architecture;
