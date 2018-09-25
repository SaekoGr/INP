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
	signal state	: std_logic_vector(3 to 0) := "1000"; -- initial state, showing the name's initial
	signal next_state : std_logic_vector(3 to 0) := "0000";
	signal clock_enable : std_logic;
	signal cnt : std_logic_vector(0 to 7);
	signal tmp_row : std_logic_vector(0 to 7);
	signal tmp_led : std_logic_vector(0 to 7);

    -- Sem doplnte definice vnitrnich signalu.

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
	 
	 generator: process(SMCLK, RESET)
	 begin
			if RESET = '1' then
				cnt <= std_logic_vector(to_unsigned(0, 8));
			elsif rising_edge(SMCLK) then
				cnt <= cnt + 1;
			end if;
	 end process generator;
	 
	 
	 clock_enable <= '1' when ce_cnt = "11111111" else '0';
	 
	 rotacny: process(RESET)
	 begin
		if RESET = '1' then
			tmp_row <= "10000000";
		elsif (SMCLK = '1') and (clock_enable = '1') then
			tmp_row <= tmp_row(0) & tmp_row(7 downto 1);
		end if;
	 end process rotacny;
	 
	 decoder: process(tmp_row)
	 begin
		if tmp_row = "10000000" then
			tmp_led <= "11111111";
		elsif tmp_row = "01000000" then
			tmp_led <= "11100011";
		elsif tmp_row = "00100000" then
			tmp_led <= "11011101";
		elsif tmp_row = "00010000" then
			tmp_led <= "11011111";
		elsif tmp_row = "00001000" then
			tmp_led <= "11100011";
		elsif tmp_row = "00000100" then
			tmp_led <= "11111101";
		elsif tmp_row = "00000010" then
			tmp_led <= "10111001";
		elsif tmp_row = "00000001" then
			tmp_led <= "11000111";
		else
			tmp_led <= "11111111";
		end if;
	 end process decoder;

	 
	 ROW <= tmp_row;
	 LED <= tmp_led;

end main;
