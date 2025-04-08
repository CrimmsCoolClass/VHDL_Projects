library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tiplab1_tb is
end entity;

architecture test of tiplab1_tb is
    type testpattern is record
        nr : std_logic_vector(2 downto 0);
        hr : std_logic;
        cl : std_logic;
    end record;
    type testpattern_vector is array (natural range<>) of testpattern;

    constant TESTDELAY   : time := 10 ns;
    constant REPORTDELAY : time := 5 ns;
    constant TESTVECTORS : testpattern_vector := ( 
        ("000",'0','0'),("001",'0','0'),("010",'0','0'),("011",'0','0'),
        ("100",'0','0'),("101",'0','0'),("110",'0','0'),("111",'0','1'),
        ("000",'1','0'),("001",'1','1'),("010",'1','1'),("011",'1','1'),
        ("100",'1','1'),("101",'1','1'),("110",'1','1'),("111",'1','1')
    );
    
    signal norm_referees : std_logic_vector(2 downto 0);
    signal head_referee  : std_logic;
    signal referee_call  : std_logic;
    signal testindex     : integer range 0 to TESTVECTORS'length-1 := 0;
begin
    tiplab1_inst: entity work.tiplab1
     port map(
        normal_ref => norm_referees,
        head_ref   => head_referee,
        call       => referee_call
    );

    signalstimulation:process
    begin
        for i in TESTVECTORS'range loop
            norm_referees <= TESTVECTORS(i).nr;
            head_referee  <= TESTVECTORS(i).hr;
            testindex <= i;
            wait for TESTDELAY;
        end loop;
        report "End of test!";
        wait;
    end process;

    outputchecking:process
    begin
        wait until testindex'transaction;
        wait for REPORTDELAY;
        assert referee_call = TESTVECTORS(testindex).cl
            report "Mismatch!"
        severity error;
    end process;
end architecture;
