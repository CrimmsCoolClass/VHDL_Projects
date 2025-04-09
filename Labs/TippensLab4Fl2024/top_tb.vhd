library ieee;
context ieee.ieee_std_context;
use ieee.math_real.all;

entity top_tb is
end entity;

architecture test of top_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_PERIOD : time := 8680 ns;

    signal clk     : std_logic := '0';
    signal reset   : std_logic := '0';
    signal uartin  : std_logic := '1';
    signal swtchs  : std_logic_vector(15 downto 0) := (others => '0');
    signal stopsim : boolean := false;

    procedure write_UART(in_byte : in std_logic_vector(7 downto 0); signal out_serial : out std_logic) is
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

    LAB4_TOP_inst: entity work.LAB4_TOP
     port map(
        clk  => clk,
        btnD => reset,
        RsRx => uartin,
        sw   => swtchs,
        RsTx => open,
        an   => open,
        seg  => open,
        led  => open
    );
    
    process
    begin
        while stopsim = false loop
            wait for CLK_PERIOD/2;
            clk <= not clk;
        end loop;
        wait;
    end process;

    process
        alias tx_finished is <<signal LAB4_TOP_inst.transmit_done : std_logic>>;
    begin
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        write_UART(x"4C", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"30", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"31", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"4D", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"30", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"31", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"53", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"30", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        write_UART(X"33", uartin);
        wait until tx_finished = '1';
        wait until rising_edge(clk);
        wait for 10 ms;
        swtchs <= (others => '1');
        wait until rising_edge(clk);
        wait for 10 ms;
        wait for 8*BIT_PERIOD;
        stopsim <= true;
        report "End of testbench!";
        wait;
    end process;

end architecture;

