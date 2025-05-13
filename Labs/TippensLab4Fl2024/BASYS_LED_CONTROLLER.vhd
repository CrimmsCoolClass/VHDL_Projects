library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.UART2.all;

entity BASYS_LED_CONTROLLER is
    port(
        clock           : in  std_logic;
        reset           : in  std_logic;
        uart_stop_bit   : in  std_logic;
        uart_data_byte  : in  std_logic_vector(7  downto 0);
        switches        : in  std_logic_vector(15 downto 0);
        segments        : out std_logic_vector(6  downto 0);
        anodes          : out std_logic_vector(3  downto 0);
        leds            : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of BASYS_LED_CONTROLLER is

    function ascii_to_num(input: std_logic_vector(15 downto 0)) return integer is
    begin
        case input is
            when "0011000000110000" => return  0;
            when "0011000000110001" => return  1;
            when "0011000000110010" => return  2;
            when "0011000000110011" => return  3;
            when "0011000000110100" => return  4;
            when "0011000000110101" => return  5;
            when "0011000000110110" => return  6;
            when "0011000000110111" => return  7;
            when "0011000000111000" => return  8;
            when "0011000000111001" => return  9;
            when "0011000100110000" => return 10;
            when "0011000100110001" => return 11;
            when "0011000100110010" => return 12;
            when "0011000100110011" => return 13;
            when "0011000100110100" => return 14;
            when "0011000100110101" => return 15;
            when others => return 16;
        end case;
    end function ascii_to_num;

    function ascii_to_seg(input: std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        case input is
            when "00110000" => return "1000000";
            when "00110001" => return "1111001";
            when "00110010" => return "0100100";
            when "00110011" => return "0110000";
            when "00110100" => return "0011001";
            when "00110101" => return "0010010";
            when "00110110" => return "0000010";
            when "00110111" => return "1111000";
            when "00111000" => return "0000000";
            when "00111001" => return "0011000";
            when others     => return "1111111";
        end case;
    end function ascii_to_seg;

    type stateType is (IDLE, READ, ASSIGN, CLEANUP);

    constant L_ascii_uc : std_logic_vector(7 downto 0) := "01001100"; --!ASCII for uppercase L
    constant l_ascii_lc : std_logic_vector(7 downto 0) := "01101100"; --!ASCII for lowercase L
    constant M_ascii_uc : std_logic_vector(7 downto 0) := "01001101"; --!ASCII for uppercase M
    constant m_ascii_lc : std_logic_vector(7 downto 0) := "01101101"; --!ASCII for lowercase m
    constant S_ascii_uc : std_logic_vector(7 downto 0) := "01010011";
    constant s_ascii_lc : std_logic_vector(7 downto 0) := "01110011";
    constant seg_H      : std_logic_vector(6 downto 0) := "0001001";
    constant seg_L      : std_logic_vector(6 downto 0) := "1000111";


    signal ascii_number  : std_logic_vector(15 downto 0) := (others => '0');
    signal ascii_letter  : std_logic_vector(7  downto 0) := (others => '0');
    signal segment_one   : std_logic_vector(6  downto 0) := (others => '1'); --msd num
    signal segment_two   : std_logic_vector(6  downto 0) := (others => '1'); --lsd num
    signal segment_three : std_logic_vector(6  downto 0) := (others => '1');
    signal state         : stateType := IDLE;           
begin
    statemachine:process(clock,reset)
        variable byte_counter : integer := 0;
        variable command      : std_logic_vector(23 downto 0) := (others => '0');
    begin
        if reset then
            state <= CLEANUP;
        elsif rising_edge(clock) then
            case state is
                when IDLE =>
                    if uart_stop_bit = '1' then
                        byte_counter := byte_counter + 1;
                        state <= READ;
                    end if;
                
                when READ =>
                    command := command(15 downto 0) & uart_data_byte;
                    if byte_counter = 3 then
                        state <= ASSIGN;
                    else
                        state <= IDLE;
                    end if;

                when ASSIGN =>
                    ascii_letter <= command(23 downto 16);
                    ascii_number <= command(15 downto  0);
                    byte_counter := 0;
                    state <= IDLE;

                when CLEANUP =>
                    byte_counter := 0;
                    ascii_letter <= (others => '0');
                    ascii_number <= (others => '0');
                    command      := (others => '0');
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    ledprocessing:process(clock,reset)
    begin
        if reset = '1' then
            leds <= (others => '0');
        elsif rising_edge(clock) then
            case ascii_letter is
                when L_ascii_uc => leds(ascii_to_num(ascii_number)) <= '1';
                when l_ascii_lc => leds(ascii_to_num(ascii_number)) <= '1';
                when M_ascii_uc => leds(ascii_to_num(ascii_number)) <= '0';
                when m_ascii_lc => leds(ascii_to_num(ascii_number)) <= '0';
                when others     => null; 
            end case;
        end if;
    end process;

    switchandling:process(clock)
    begin
        if rising_edge(clock) then
            if ascii_letter = s_ascii_lc or ascii_letter = S_ascii_uc then
                for i in 0 to 15 loop
                    if i = ascii_to_num(ascii_number) then
                        if switches(i) = '1' then
                            segment_three <= seg_H;
                        elsif switches(i) = '0' then
                            segment_three <= seg_L;
                        end if;
                        segment_one <= ascii_to_seg(ascii_number(15 downto 8));
                        segment_two <= ascii_to_seg(ascii_number(7  downto 0));
                        exit;
                    end if;
                end loop;
            else
                segment_one   <= (others => '1');
                segment_two   <= (others => '1');
                segment_three <= (others => '1');
            end if;
        end if;
    end process;

    segment_multiplexing:process(clock) --add async reset to segments
        variable count: integer := 0;
    begin
        if rising_edge(clock) then
            if count < 99_999 then
                anodes   <= "0111";
                segments <= segment_three;
                count    := count + 1;
            elsif count < 199_999 then
                anodes   <= "1101";
                segments <= segment_one;
                count    := count + 1;
            elsif count < 299_999 then
                anodes   <= "1110";
                segments <= segment_two;
                count    := count + 1;
            else
                count := 0;
            end if;
        end if;
    end process;

end architecture;
