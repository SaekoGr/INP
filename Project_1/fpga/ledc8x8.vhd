library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ledc8x8 is
port ( -- Sem doplnte popis rozhrani obvodu.
	RESET : in std_logic;
	SMCLK : in std_logic;
	
	ROW: out std_logic_vector(0 to 7);
	LED: out std_logic_vector(0 to 7)
);
end ledc8x8;

architecture main of ledc8x8 is

   -- Sem doplnte definice vnitrnich signalu.
	
	-- enabling signal
	signal clock_enable : std_logic := '0';
	-- counter from 0 to 256
	signal cnt : std_logic_vector(0 to 7) := "00000000";
	-- help variable for row and led
	signal tmp_row : std_logic_vector(7 downto 0) := "10000000";
	signal tmp_led : std_logic_vector(7 downto 0) := "11111111";
	
	-- variable for state
	-- 1000 -> Shows name's initial
	-- 0100 -> Shows nothing
	-- 0010 -> Shows surname's initial
	-- 0001 -> Shows nothing
	signal state : std_logic_vector(3 downto 0) := "1000";
	
	-- signal that counts and then switches
	signal switch_counter : std_logic_vector(19 downto 0) := "00000000000000000000";
	-- signal for allowing to switch to the next state
	signal can_switch : std_logic := '0';


begin

    -- Sem doplnte popis obvodu. Doporuceni: pouzivejte zakladni obvodove prvky
    -- (multiplexory, registry, dekodery,...), jejich funkce popisujte pomoci
    -- procesu VHDL a propojeni techto prvku, tj. komunikaci mezi procesy,
    -- realizujte pomoci vnitrnich signalu deklarovanych vyse.

    -- DODRZUJTE ZASADY PSANI SYNTETIZOVATELNEHO VHDL KODU OBVODOVYCH PRVKU,
    -- JEZ JSOU PROBIRANY ZEJMENA NA UVODNICH CVICENI INP A SHRNUTY NA WEBU:
    -- http://merlin.fit.vutbr.cz/FITkit/docs/navody/synth_templates.html.

    -- Nezapomente take doplnit mapovani signalu rozhrani na piny FPGA
    -- v souboru ledc8x8.ucf.
	 
	 generator: process(SMCLK, RESET, cnt, switch_counter)
	 begin
			-- reset and counting 
			if (RESET = '1') then
				cnt <= "00000000";
				switch_counter <= "00000000000000000000";
			elsif rising_edge(SMCLK) then
				cnt <= cnt + 1;
				switch_counter <= switch_counter + 1;
			end if;
			
			-- enable clock when counter is finished
			if (cnt = "11111111") then
				clock_enable <= '1';
			else
				clock_enable <= '0';
			end if;
			
			-- enable switch when counter is finished
			if (switch_counter = "11111111111111111111") then
				can_switch <= '1';
			else
				can_switch <= '0';
			end if;
			
	 end process generator;
	 
	 move_to_the_next: process(RESET, SMCLK, clock_enable, can_switch)
	 begin
		-- when reset = '1', start from the beginning
		if RESET = '1' then
			tmp_row <= "10000000";
			state <= "1000";
		-- when rising edge on SMCLK, choose the appropriate rows and state
		elsif rising_edge(SMCLK) then
			-- moves thrugh the rows
			if(clock_enable = '1') then
				case tmp_row is
					when "10000000" => tmp_row <= "01000000";
					when "01000000" => tmp_row <= "00100000";
					when "00100000" => tmp_row <= "00010000";
					when "00010000" => tmp_row <= "00001000";
					when "00001000" => tmp_row <= "00000100";
					when "00000100" => tmp_row <= "00000010";
					when "00000010" => tmp_row <= "00000001";
					when "00000001" => tmp_row <= "10000000";
					when others => tmp_row <= "10000000";
				end case;
			end if;
			
			-- changes the state to the next one
			if(can_switch = '1') then
				case state is
					when "1000" => state <= "0100";
					when "0100" => state <= "0010";
					when "0010" => state <= "0001";
					when "0001" => state <= "1000";
					when others => state <= "1000";
				end case;
			end if;
			
		end if;
	 end process move_to_the_next;

	-- decoder for switching the leds on and off
	showing_leds: process(tmp_row, state)
	begin
		if state="1000" then -- state for showing S
			case tmp_row is -- first row is skipped because it doesn't light up
				when "01000000" => tmp_led <= "11100011";
				when "00100000" => tmp_led <= "11011101";
				when "00010000" => tmp_led <= "11011111";
				when "00001000" => tmp_led <= "11100011";
				when "00000100" => tmp_led <= "11111101";
				when "00000010" => tmp_led<= "10111101";
				when "00000001" => tmp_led <= "11000011";
				when others		=> tmp_led <= "11111111";
			end case;
	   elsif state="0010" then -- state for showing G
			case tmp_row is -- first row is skipped because it doesn't light up
				when "01000000" => tmp_led <= "11000011";
				when "00100000" => tmp_led <= "10111101";
				when "00010000" => tmp_led <= "10111111";
				when "00001000" => tmp_led <= "10110001";
				when "00000100" => tmp_led <= "10111101";
				when "00000010" => tmp_led<= "10111101";
				when "00000001" => tmp_led <= "11000011";
				when others		=> tmp_led <= "11111111";
			 end case;
		else -- show nothing
			tmp_led <= "11111110";
		end if;	
	 end process showing_leds;
	 
	 -- output for ROW and LED
	 ROW <= tmp_row;
	 LED <= tmp_led;
	 
end main;
