library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity CrimmsTrafiic is
    port(
        clk  : in  std_logic;
        btnD : in  std_logic; --emergency
        btnL : in  std_logic; --millerLeftCounter
        btnR : in  std_logic; --120LeftCounter
        btnC : in  std_logic; --train
        btnU : in  std_logic; --millerStraightCounter
        JA   : out std_logic_vector(7 downto 0);
        JB   : out std_logic_vector(1 downto 0);
        an   : out std_logic_vector(3  downto 0);
        seg  : out std_logic_vector(6  downto 0);
        led  : out std_logic_vector(15 downto 0)
        
    );
end entity;

architecture rtl of CrimmsTrafiic is
    function to_ssdca(input: integer) return std_logic_vector is
    begin
        case input is
            when 0      => return "1000000";
            when 1      => return "1111001";
            when 2      => return "0100100";
            when 3      => return "0110000";
            when 4      => return "0011001";
            when 5      => return "0010010";
            when 6      => return "0000010";
            when 7      => return "1111000";
            when 8      => return "0000000";
            when 9      => return "0011000";
            when 10     => return "0001000";
            when 11     => return "0000011";
            when 12     => return "1000110";
            when 13     => return "0100001";
            when 14     => return "0000110";
            when 15     => return "0001110";
            when others => return "1111111";
        end case;
    end function;

    type StateType is (STRAIGHT120, TRAN120, LEFT120, TRANLEFT120, STRAIGHTMILL, TRANMILL, LEFTMILL, TRANLEFTMILL, ALLRED, TRAIN, EMERGENCY);
                        --mlg, mly, mg, my mr, 120g, 120y, 120r, 120lg, 120ly
    constant DEFAULTSTATE      : std_logic_vector(9 downto 0) := "0000110000";
    constant DEFAULTTRAN       : std_logic_vector(9 downto 0) := "0000101000";
    constant REDLIGHTS         : std_logic_vector(9 downto 0) := "0000100100";
    constant TURN120           : std_logic_vector(9 downto 0) := "0000100110";
    constant MILLERTURN        : std_logic_vector(9 downto 0) := "1000100100";
    constant MILLERDRIVE       : std_logic_vector(9 downto 0) := "0010000100";
    constant MILLERTRANSITION  : std_logic_vector(9 downto 0) := "0001000100";
    constant MILLERLTRANSITION : std_logic_vector(9 downto 0) := "0100100100";
    constant TURN120TRANSITION : std_logic_vector(9 downto 0) := "0000100101";
    
    constant ONE_SECOND : integer := 100_000_000;
    constant DEBOUNCE   : integer := 1_000_000;
    constant SEG_DISP_T : integer := 100_000;

    signal trafficlights  : std_logic_vector(9  downto 0) := (others => '0');
    signal lightemitdiode : std_logic_vector(15 downto 0) := (others => '0');

    signal state     : StateType := STRAIGHT120;
    signal nextState : StateType := STRAIGHT120;
    
    signal millerstraightcars : integer := 0;
    signal millerleftcars     : integer := 0;
    signal left120cars        : integer := 0;
    signal greenmincounter    : integer := 0;
    signal greenmaxcounter    : integer := 0;
    signal yellowtimecounter  : integer := 0;
    signal redtimecounter     : integer := 0;

    signal btnD_Debounce : std_logic;
    signal btnU_Debounce : std_logic;
    signal btnU_Toggle   : std_logic;
    signal btnL_Debounce : std_logic;
    signal btnL_Toggle   : std_logic;
    signal btnR_Debounce : std_logic;
    signal btnR_Toggle   : std_logic;
    signal btnC_Debounce : std_logic;
begin

    debounceBtnD: process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if btnD /= btnD_Debounce and count < DEBOUNCE - 1 then
                count := count + 1;
            elsif count = DEBOUNCE - 1 then
                btnD_Debounce <= btnD;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    debounceBtnC: process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if btnC /= btnC_Debounce and count < DEBOUNCE - 1 then
                count := count + 1;
            elsif count = DEBOUNCE - 1 then
                btnC_Debounce <= btnC;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    debounceBtnU: process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if btnU /= btnU_Debounce and count < DEBOUNCE - 1 then
                count := count + 1;
            elsif count = DEBOUNCE - 1 then
                btnU_Debounce <= btnU;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    debounceBtnL: process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if btnL /= btnL_Debounce and count < DEBOUNCE - 1 then
                count := count + 1;
            elsif count = DEBOUNCE - 1 then
                btnL_Debounce <= btnL;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    debounceBtnR: process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if btnR /= btnR_Debounce and count < DEBOUNCE - 1 then
                count := count + 1;
            elsif count = DEBOUNCE - 1 then
                btnR_Debounce <= btnR;
                count := 0;
            else
                count := 0;
            end if;
        end if;
    end process;

    statemachine:process(clk)
    begin
        if rising_edge(clk) then
            case state is

                when STRAIGHT120 =>
                    redtimecounter <= 0;
                    if greenmincounter < ONE_SECOND * 10 - 1 then
                        greenmincounter <= greenmincounter + 1;
                    end if;

                    if btnC_Debounce = '1' then
                        state     <= TRAN120;
                        nextState <= TRAIN;
                    elsif btnD_Debounce = '1' then
                        state     <= TRAN120;
                        nextState <= EMERGENCY;
                    elsif (greenmincounter = ONE_SECOND * 10 - 1) then
                        if millerleftcars > 4 then
                            state     <= TRAN120;
                            nextState <= LEFTMILL;
                        elsif millerstraightcars > 7 then
                            state     <= TRAN120;
                            nextState <= STRAIGHTMILL;
                        end if;
                    end if;

                when LEFT120 =>
                    redtimecounter <= 0;
                    if greenmincounter < ONE_SECOND * 10 - 1 then
                        greenmincounter <= greenmincounter + 1;
                    end if;

                    if btnC_Debounce = '1' then
                        state     <= TRANLEFT120;
                        nextState <= TRAIN;
                    elsif btnD_Debounce = '1' then
                        state     <= TRANLEFT120;
                        nextState <= EMERGENCY;
                    elsif (greenmincounter = ONE_SECOND * 10 - 1) then
                        state     <= TRANLEFT120;
                        nextState <= STRAIGHT120;
                    end if;
                    
                when STRAIGHTMILL =>
                    redtimecounter <= 0;
                    if greenmincounter < ONE_SECOND * 10 - 1 then
                        greenmincounter <= greenmincounter + 1;
                    end if;
                    if greenmaxcounter < ONE_SECOND * 20 - 1 then
                        greenmaxcounter <= greenmaxcounter + 1;
                    end if;

                    if btnC_Debounce = '1' then
                        state     <= TRANMILL;
                        nextState <= TRAIN;
                    elsif btnD_Debounce = '1' then
                        state     <= TRANMILL;
                        nextState <= EMERGENCY;
                    elsif greenmaxcounter = ONE_SECOND * 20 - 1 then
                        if left120cars > 0 then
                            state     <= TRANMILL;
                            nextState <= LEFT120;
                        else
                            state     <= TRANMILL;
                            nextState <= STRAIGHT120;
                        end if;
                    elsif greenmincounter = ONE_SECOND * 10 - 1 then
                        if left120cars > 4 then
                            state     <= TRANMILL;
                            nextState <= LEFT120;
                        end if;
                    end if;

                when LEFTMILL =>
                    redtimecounter <= 0;
                    if greenmincounter < ONE_SECOND * 10 - 1 then
                        greenmincounter <= greenmincounter + 1;
                    end if;

                    if btnC_Debounce = '1' then
                        state     <= TRANLEFTMILL;
                        nextState <= TRAIN;
                    elsif btnD_Debounce = '1' then
                        state     <= TRANLEFTMILL;
                        nextState <= EMERGENCY;
                    elsif greenmincounter = ONE_SECOND * 10 - 1 then
                        if millerstraightcars > 0 then
                            state     <= TRANLEFTMILL;
                            nextState <= STRAIGHTMILL;
                        elsif left120cars > 0 then
                            state     <= TRANLEFTMILL;
                            nextState <= LEFT120;
                        else
                            state     <= TRANLEFTMILL;
                            nextState <= STRAIGHT120;
                        end if;
                    end if; 
                    
                when TRAN120 =>
                    greenmincounter <= 0;
                    if yellowtimecounter < ONE_SECOND * 5 - 1 then
                        yellowtimecounter <= yellowtimecounter + 1;
                    else
                        state <= ALLRED;
                    end if;

                when TRANLEFTMILL =>
                    greenmincounter <= 0;
                    if yellowtimecounter < ONE_SECOND * 5 - 1 then
                        yellowtimecounter <= yellowtimecounter + 1;
                    else
                        state <= ALLRED;
                    end if;

                when TRANMILL =>
                    greenmincounter <= 0;
                    greenmaxcounter <= 0;
                    if yellowtimecounter < ONE_SECOND * 5 - 1 then
                        yellowtimecounter <= yellowtimecounter + 1;
                    else
                        state <= ALLRED;
                    end if;

                when TRANLEFT120 =>
                    greenmincounter <= 0;
                    if yellowtimecounter < ONE_SECOND * 5 - 1 then
                        yellowtimecounter <= yellowtimecounter + 1;
                    else
                        state <= ALLRED;
                    end if;
                
                when ALLRED =>
                    yellowtimecounter <= 0;
                    if redtimecounter < ONE_SECOND * 2 - 1 then
                        redtimecounter <= redtimecounter +  1;
                    else
                        state <= nextState;
                    end if;
                
                when TRAIN =>
                    if btnC_Debounce = '1' then
                        state <= TRAIN;
                    else
                        state <= STRAIGHT120;
                    end if;

                when EMERGENCY =>
                    if btnD_Debounce = '1' then
                        state <= EMERGENCY;
                    else
                        state <= STRAIGHT120;
                    end if;

                when others =>
                    state <= STRAIGHT120;

            end case;
        end if;  
    end process;

    millerleftcarcounting:process(clk, state)
    begin
        if state = LEFTMILL then
            millerleftcars <= 0;
        elsif rising_edge(clk) then
            btnL_Toggle <= btnL_Debounce;
            if btnL_Debounce = '1' and btnL_Toggle = '0' and millerleftcars < 9 then
                millerleftcars <= millerleftcars + 1;
            end if;
        end if;
    end process;

    millercarcounting:process(clk, state)
    begin
        if state = STRAIGHTMILL then
            millerstraightcars <= 0;
        elsif rising_edge(clk) then
            btnU_Toggle <= btnU_Debounce;
            if btnU_Debounce = '1' and btnU_Toggle = '0' and millerstraightcars < 9 then
                millerstraightcars <= millerstraightcars + 1;
            end if;
        end if;
    end process;

    left120carcounting:process(clk, state)
    begin
        if state = LEFT120 then
            left120cars <= 0;
        elsif rising_edge(clk) then
            btnR_Toggle <= btnR_Debounce;
            if btnR_Debounce = '1' and btnR_Toggle = '0' and left120cars < 9 then
                left120cars <= left120cars + 1;
            end if;
        end if;
    end process;

    specialleds:process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if state = TRAIN then
                if count < ONE_SECOND / 2 - 1 then
                    count := count + 1;
                    lightemitdiode(15) <= '1';
                    lightemitdiode(0)  <= '0';
                elsif count < ONE_SECOND - 1 then
                    count := count + 1;
                    lightemitdiode(15) <= '0';
                    lightemitdiode(0)  <= '1';
                else
                    count := 0;
                end if;
            else
                lightemitdiode <= (others => '0');
            end if;
        end if;
    end process;

    segmultiplexing:process(clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if count < SEG_DISP_T - 1 then
                an <= "0111";
                seg <= to_ssdca(left120cars);
                count := count + 1;
            elsif count < SEG_DISP_T * 2 -1 then
                an <= "1101";
                seg <= to_ssdca(millerleftcars);
                count := count + 1;
            elsif count < SEG_DISP_T * 3 - 1 then
                an <= "1110";
                seg <= to_ssdca(millerstraightcars);
                count := count + 1;
            else
                count := 0;
            end if;
        end if;
    end process;


    with state select
        trafficlights <= DEFAULTSTATE      when STRAIGHT120,
                         DEFAULTTRAN       when TRAN120,
                         TURN120           when LEFT120,
                         TURN120TRANSITION when TRANLEFT120,
                         MILLERDRIVE       when STRAIGHTMILL,
                         MILLERTRANSITION  when TRANMILL,
                         MILLERTURN        when LEFTMILL,
                         MILLERLTRANSITION when TRANLEFTMILL,
                         REDLIGHTS         when ALLRED,
                         REDLIGHTS         when EMERGENCY,
                         DEFAULTSTATE      when TRAIN;
                         
    led <= lightemitdiode;
    --(JA1, JA2, JA3, JA4, JA7, JA8, JA9, JA10, JB1, JB2) <= trafficlights;
    JA <= trafficlights(9 downto 2);
    JB <= trafficlights(1 downto 0);
end architecture;
