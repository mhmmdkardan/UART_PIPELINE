----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/22/2026 10:20:25 AM
-- Design Name: 
-- Module Name: pipeline - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pipeline is
    Port ( BUTTON : in STD_LOGIC;
            clk : in std_logic;
           Tx : out STD_LOGIC:= '1');
end pipeline;

architecture Behavioral of pipeline is
type mem is array ( 0 to 12 ) of std_logic_vector(7 downto 0);
signal SENS : mem := (others =>(others => '0'));
signal count1 : unsigned( 19 downto 0 ) := (others => '0');
signal btn : std_logic;
signal btn_latch : std_logic;

signal BounceFlag : std_logic := '0';
signal SEND : std_logic := '0';
signal buffer_busy : std_logic := '0';
signal baud_counter : integer range 0 to 15 := 0;
signal bit_counter : integer range 0 to 7 := 0;
signal line_counter : integer range 0 to 15 := 0;
signal serial_out : std_logic := '1';
type state_type is (low, data, high,none);
signal state : state_type := none;
signal en_16_x_baud : std_logic := '0';
signal long_done : std_logic := '0';
signal baud_accumulator : unsigned(23 downto 0) := (others => '0');
begin
SENS(0) <= "01001101";         
SENS(1) <= "01000001";
SENS(2) <= "01001101";
SENS(3) <= "01000001";
SENS(4) <= "01000100";
SENS(5) <= "00100000";
SENS(6) <= "01101001";
SENS(7) <= "01110011";
SENS(8) <= "00100000";
SENS(9) <= "01000111";
SENS(10) <= "01001111";
SENS(11) <= "01000100";
SENS(12) <= "00001010";
    process(clk)
    variable v : unsigned(23 downto 0);
begin
    if rising_edge(clk) then
        v := baud_accumulator + to_unsigned(1843200, 24);

        if v >= to_unsigned(12000000, 24) then
            v := v - to_unsigned(12000000, 24);
            en_16_x_baud <= '1';
        else
            en_16_x_baud <= '0';
        end if;

        baud_accumulator <= v;
    end if;
end process;
    process(clk)
    begin
    if(rising_edge(clk)) then
        btn_latch <= BUTTON;
        btn <= btn_latch;
    end if;
    end process;    
    
    process(clk)
begin
    if rising_edge(clk) then

        SEND <= '0';

        if btn = '1' then

            if count1 < 1000000 then
                count1 <= count1 + 1;
                long_done <= '0';

            elsif long_done = '0' and buffer_busy = '0' then
                long_done <= '1';
                SEND <= '1';
            end if;

        else
            count1 <= (others => '0');
            long_done <= '0';
        end if;

    end if;
end process;
   process(clk) 
   begin 
    if(rising_edge(clk)) then
    
        case state is
        
            when none => 
            buffer_busy <= '0';
        if(SEND = '1')then
            state <= low;
            buffer_busy <= '1';
        end if;
        
        when low =>
            
            serial_out <= '0';
            if en_16_x_baud = '1' then
                        if baud_counter = 15 then
                            baud_counter <= 0;
                            state <= data;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;
                    end if;
        when data =>
            serial_out <= sens(line_counter)(bit_counter);
            if en_16_x_baud = '1' then
                        if baud_counter = 15 then
                            baud_counter <= 0;
                            if bit_counter = 7 then
                                bit_counter <= 0;
                                state <= high;
                            else
                                bit_counter <= bit_counter + 1;
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;
                    end if;
             when high =>
                    serial_out <= '1';
                    if en_16_x_baud = '1' then
                        if baud_counter = 15 then
                            baud_counter <= 0;
                            line_counter <= line_counter + 1;
                            if(line_counter < 12) then
                            state <= low ;
                            else
                                line_counter <= 0;
                                state <= none; 
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;
                    end if;
        end case;
    end if;
end process;
tx <= serial_out;
end Behavioral;
