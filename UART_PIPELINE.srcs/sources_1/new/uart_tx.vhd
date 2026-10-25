--
-------------------------------------------------------------------------------------------
-- Copyright ? 2011, Xilinx, Inc.
-- This file contains confidential and proprietary information of Xilinx, Inc. and is
-- protected under U.S. and international copyright and other intellectual property laws.
-------------------------------------------------------------------------------------------
--
-- Disclaimer:
-- This disclaimer is not a license and does not grant any rights to the materials
-- distributed herewith. Except as otherwise provided in a valid license issued to
-- you by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE
-- MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY
-- DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
-- INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
-- OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable
-- (whether in contract or tort, including negligence, or under any other theory
-- of liability) for any loss or damage of any kind or nature related to, arising
-- under or in connection with these materials, including for any direct, or any
-- indirect, special, incidental, or consequential loss or damage (including loss
-- of data, profits, goodwill, or any type of loss or damage suffered as a result
-- of any action brought by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-safe, or for use in any
-- application requiring fail-safe performance, such as life-support or safety
-- devices or systems, Class III medical devices, nuclear facilities, applications
-- related to the deployment of airbags, or any other applications that could lead
-- to death, personal injury, or severe property or environmental damage
-- (individually and collectively, "Critical Applications"). Customer assumes the
-- sole risk and liability of any use of Xilinx products in Critical Applications,
-- subject only to applicable laws and regulations governing limitations on product
-- liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------------------
--
-- UART Transmitter with integral 16 byte FIFO buffer
--
-- 8 bit, no parity, 1 stop bit
--
-- This module was made for use with Spartan-6 Generation Devices and is also ideally 
-- suited for use with Virtex-6 and 7-Series devices.
--
-- Version 1 - 31st March 2011.
--
-- Ken Chapman
-- Xilinx Ltd
-- Benchmark House
-- 203 Brooklands Road
-- Weybridge
-- Surrey KT13 ORH
-- United Kingdom
--
-- chapman@xilinx.com
--
-------------------------------------------------------------------------------------------
--
-- Format of this file.
--
-- The module defines the implementation of the logic using Xilinx primitives.
-- These ensure predictable synthesis results and maximise the density of the 
-- implementation. The Unisim Library is used to define Xilinx primitives. It is also 
-- used during simulation. 
-- The source can be viewed at %XILINX%\vhdl\src\unisims\unisim_VCOMP.vhd
-- 
-------------------------------------------------------------------------------------------
--
-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
        generic (
        N : positive := 1843200;
        C : positive := 12000000
    );

  Port (             data_input : in std_logic_vector(7 downto 0);
                
                  serial_out : out std_logic := '1';
                buffer_start : in std_logic;
         buffer_busy : out std_logic;
            
                         clk : in std_logic);
  end uart_tx;
--

architecture low_level_definition of uart_tx is
function clog2 (v : integer) return integer is
    variable n : integer := 1;
    variable r : integer := 2;
  begin
    while r < v loop
      r := r * 2;
      n := n + 1;
    end loop;
    return n;
  end function clog2;
  constant NN  : integer := clog2(N);   
    constant CC  : integer := clog2(C);   
signal bit_counter : integer range 0 to 7 := 0;
signal baud_counter : integer range 0 to 15 := 0;
type state_type is (low, data, high,none);
signal state : state_type := none;
signal data_in : std_logic_vector(7 downto 0);
signal baud_accumulator : unsigned(23 downto 0) := (others => '0');
signal en_16_x_baud : std_logic := '0';
begin
        process(clk)
    variable v : unsigned(23 downto 0);
begin
    if rising_edge(clk) then
        v := baud_accumulator + to_unsigned(N, NN);
        if v >= to_unsigned(C, CC) then
            v := v - to_unsigned(C, CC);
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
    
        case state is
        
            when none => 
            buffer_busy <= '0';
        if(buffer_start = '1')then
            data_in <= data_input;
            bit_counter  <= 0;
            baud_counter <= 0;
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
            serial_out <= data_in(bit_counter);
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
            state <= none;
        else
            baud_counter <= baud_counter + 1;
        end if;
    end if;
        end case;
    end if;
end process;
end architecture;
