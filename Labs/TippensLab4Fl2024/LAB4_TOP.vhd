library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART2.all;

entity LAB4_TOP is
    port(
        clk   : in  std_logic;
        btnD  : in  std_logic;
        RsRx  : in  std_logic;
        sw    : in  std_logic_vector(15 downto 0);
        RsTx  : out std_logic;
        an    : out std_logic_vector(3  downto 0);
        seg   : out std_logic_vector(6  downto 0);
        led   : out std_logic_vector(15 downto 0) 
    );
end entity;

architecture rtl of LAB4_TOP is
    signal stop_bit        : std_logic;
    signal data_byte       : std_logic_vector( 7 downto 0); 
    signal transmit_serial : std_logic;
    signal transmit_active : std_logic;
    signal transmit_done   : std_logic;
begin
    basys_uart_rx_inst: entity work.BASYS_UART_RX
    port map (
      clock        => clk,
      serial_input => RsRx,
      stop_bit     => stop_bit,
      data_byte    => data_byte
    );

    basys_uart_tx_inst: entity work.BASYS_UART_TX
    port map (
      clock           => clk,
      stop_bit        => stop_bit,
      transmit_byte   => data_byte,
      transmit_active => transmit_active,
      transmit_serial => transmit_serial,
      transmit_done   => transmit_done
    );

    basys_led_controller_inst: entity work.BASYS_LED_CONTROLLER
    port map (
      clock          => clk,
      reset          => btnD,
      uart_stop_bit  => stop_bit,
      uart_data_byte => data_byte,
      switches       => sw,
      segments       => seg,
      anodes         => an,
      leds           => led
    );

    RsTx <= transmit_serial when transmit_active = '1' else '1';
end architecture;
