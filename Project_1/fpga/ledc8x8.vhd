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
				state <= "1000";
			elsif rising_edge(SMCLK) then
				cnt <= cnt + 1;
			end if;
	 end process generator;
	 
	 decoder: process(state, tmp_row, tmp_led)
	 begin
		if state = "1000" then -- show the name's initial
			next_state <= "0100";
		
		elsif state = "0100" then
			next_state <= "0010";
		
		elsif state = "0010" then	-- show
			next_state <= "0001";
		
		elsif state = "0001" then -- show nothing
			next_state <= "1000";
		
			
		end if;
	 end process decoder;
	 
	 state <= next_state;
	 ROW <= tmp_row;
	 LED <= tmp_led;

end main;
