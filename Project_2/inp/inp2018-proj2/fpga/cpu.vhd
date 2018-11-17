-- cpu.vhd: Simple 8-bit CPU (BrainF*ck interpreter)
-- Copyright (C) 2018 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): DOPLNIT
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti
   
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_RDWR  : out std_logic;                    -- cteni z pameti (DATA_RDWR='1') / zapis do pameti (DATA_RDWR='0')
   DATA_EN    : out std_logic;                    -- povoleni cinnosti
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA obsahuje stisknuty znak klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna pokud IN_VLD='1'
   IN_REQ    : out std_logic;                     -- pozadavek na vstup dat z klavesnice
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- pokud OUT_BUSY='1', LCD je zaneprazdnen, nelze zapisovat,  OUT_WE musi byt '0'
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is
	-- PC register signal
	signal pc_reg : std_logic_vector(11 downto 0); -- this will be CODE_ADDR
	signal pc_inc : std_logic;
	signal pc_dec : std_logic;
	
	signal cnt_reg : std_logic_vector(7 downto 0); -- this will be TODO
	signal cnt_inc : std_logic;
	signal cnt_dec : std_logic;
	
	signal ptr_reg : std_logic_vector(9 downto 0); -- this will be DATA_ADRR
	signal ptr_inc : std_logic;
	signal ptr_dec : std_logic;
	
	-- data to be written to memory
	signal mx_data : std_logic_vector(7 downto 0) := "00000000";
	signal sel : std_logic_vector(1 downto 0) := "00";
	
	signal to_replace : std_logic_vector(3 downto 0) := "0000";
	signal can_replace : std_logic := '0';
	signal use_mux : std_logic := '0';
	
	type fsm_state is(
		state_idle,
		state_fetch,
		state_decode,
		
		state_ptr_inc,
		state_ptr_dec,
		
		state_value_inc_read,
		state_value_inc,
		state_value_inc_write,
		
		state_value_dec_read,
		state_value_dec,
		state_value_dec_write,
		
		state_putchar,
		state_getchar,
		
		state_replace_top_read,
		state_replace_top,
		state_replace_top_write,
		
		state_while_start,
		state_while_end,
		state_comment,
		state_stop,
		state_others
		-- TODO
	);
	signal present_state : fsm_state := state_idle; 
	signal next_state : fsm_state;

begin

 --                REGISTERS                    --
 -- registers change according to RESET, CLK and
 -- their special signals named as XX_inc and XX_dec
 -- according to the name of the register

 -- PC Register
	PC_process : process(RESET, CLK, pc_inc, pc_dec)
	begin
		if(RESET = '1') then				-- when reset, pc_reg starts from all zeros
			pc_reg <= "000000000000";
		elsif(CLK'event) and (CLK='1') then -- works when CLK is rising
			if(pc_inc = '1') then            -- increases pc_reg
				pc_reg <= pc_reg + 1;
			elsif(pc_dec = '1') then			-- decreases pc_reg
				pc_reg <= reg - 1;
			end if;
		end if;
	end process PC_process;

	CODE_ADDR <= pc_reg;

 -- CNT Register
	CNT_process : process(RESET, CLK, cnt_inc, cnt_dec)
	begin
		if(RESET = '1') then
			cnt_reg <= "00000000";		-- when reset, cnt_reg starts from all zeros
		elsif(CLK'event) and (CLK = '1') then -- works when CLK is rising
			if(cnt_inc = '1')then				  -- increases cnt_reg
				cnt_reg <= cnt_reg + 1;
			elsif(cnt_dec = '1')then			  -- decreases cnt_reg
				cnt_reg <= cnt_reg - 1;
			end if;
		end if;
	end process CNT_process;

	
 -- PTR Register
	PTR_process : process(RESET, CLK, ptr_inc, ptr_dec)
	begin
		if(RESET = '1') then
			ptr_reg <= "0000000000";	-- when reset, ptr_reg starts from all zeros
		elsif(CLK'event) and (CLK = '1') then -- works when CLK is rising
			if(ptr_inc = '1') then				  -- increases ptr_inc
				ptr_reg <= ptr_reg + 1;
			elsif(ptr_dec = '1') then			  -- decreases ptr_inc
				ptr_reg <= ptr_reg - 1;
			end if;
		end if;
	end process PTR_process;

	DATA_ADDR <= ptr_reg;
	
 -- TODO: MUX
	MUX_process : process(RESET, CLK, sel, can_replace, use_mux)
	begin
		if(RESET = '1') then
			mx_data <= "00000000";
		elsif(CLK'event and CLK = '1') then
			-- mux
			if(use_mux = '1') then
				if(sel = "00") then
					mx_data <= IN_DATA;
				elsif(sel = "01") then
					mx_data <= CODE_DATA;
				elsif(sel = "10") then
					mx_data <= DATA_RDATA - "00000001";
				elsif(sel = "11") then
					mx_data <= DATA_RDATA + "00000001";
				end if;
			elsif(use_mux = '0') then
				if(can_replace = '1') then
					mx_data <= to_replace & "0000";	
				end if;
			end if;
		end if;
	end process MUX_process;
	
	DATA_WDATA <= mx_data;
	
 -- FSM 
 -- FSM present state
	FSM_present_state : process(RESET, CLK, EN)
	begin
		if(RESET = '1') then
			present_state <= state_idle;
		elsif(CLK'event) and (CLK = '1') then
			if(EN = '1') then -- it is allowed to work
				present_state <= next_state;
			end if;
		end if;
	end process FSM_present_state;
	
	
 -- FSM next state
	FSM_next_state : process(present_state)
	begin
		-- everything is set to zero as default
		-- my signals
		pc_inc <= '0';
		pc_dec <= '0';
		cnt_inc <= '0';
		cnt_dec <= '0';
		ptr_inc <= '0';
		ptr_dec <= '0';
		sel <= "00";
		can_replace <= '0';
		use_mux <= '0';
		
		-- output
		CODE_EN <= '0';
		DATA_EN <= '0';
		DATA_RDWR <= '0';
		OUT_WE <= '0';
		IN_REG <= '0';
		
		case FSM_current_state is
			-- when idle, fetch next instruction
			when state_idle =>
				next_state <= state_fetch;
				
			when state_fetch =>
				next_state <= state_decode;
				CODE_EN <= '1';
				
			when state_decode =>
				case CODE_DATA is
					when X"3E" =>
						next_state <= state_ptr_inc;
					when X"3C" =>
						next_state <= state_ptr_dec;
					when X"2B" =>
						next_state <= state_value_inc_read;
					when X"2D" =>
						next_state <= state_value_dec_read;
					when X"5B" =>
						next_state <= state_while_start;
					when X"5D" =>
						next_state <= state_while_end;
					when X"2E" =>
						next_state <= state_putchar;
					when X"2C" =>
						next_state <= state_getchar;
					when X"23" =>
						next_state <= state_comment;
					when X"30" =>	-- 0
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(0, to_replace'length));
					when X"31" =>	-- 1
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(1, to_replace'length));
					when X"32" =>	-- 2
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(2, to_replace'length));
					when X"33" =>	-- 3
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(3, to_replace'length));
					when X"34" =>	-- 4
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(4, to_replace'length));
					when X"35" =>	-- 5
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(5, to_replace'length));
					when X"36" =>	-- 6
						nnext_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(6, to_replace'length));
					when X"37" =>	-- 7
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(7, to_replace'length));
					when X"38" =>	-- 8
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(8, to_replace'length));
					when X"39" =>	-- 9
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(9, to_replace'length));
					when X"41" =>	-- A 
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(10, to_replace'length));
					when X"42" =>	-- B
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(11, to_replace'length));
					when X"43" =>	-- C
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(12, to_replace'length));
					when X"44" =>	-- D
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(13, to_replace'length));
					when X"45" =>	-- E
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(14, to_replace'length));
					when X"46" =>	-- F
						next_state <= state_replace_top_read;
						to_replace <= std_logic_vector(to_unsigned(15, to_replace'length));
					when X"00" =>
						next_state <= state_stop;
					when others =>
						next_state <= state_none;						
					-- TODO finish
				end case;
			
			-- Increases ptr value
			when state_ptr_inc =>
				next_state <= state_fetch;
				ptr_inc <= '1';
				pc_inc <= '1';
				
			-- Decreases ptr value
			when state_ptr_dec =>
				next_state <= state_fetch;
				ptr_dec <= '1';
				pc_inc <= '1';
			
			-- TODO:
			-- INCREASING VALUE
			-- we first have to read the value from memory
			when state_value_inc_read =>
				next_state <= state_value_inc;
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				
			when state_value_inc =>
				next_state <= state_value_inc_write;
				use_mux <= '1';
				sel <= "11";
				
			-- we can save it now
			when state_value_inc_write =>
				next_state <= state_fetch;
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				pc_inc <= '1';
			-- END TODO
			
			-- DESCREASING VALUE
			when state_value_dec_read =>
				next_state <= state_value_dec;
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				
			when state_value_dec =>
				next_state <= state_value_dec_write;
				use_mux <= '1';
				sel <= "10";
				
			when state_value_dec_write =>
				next_state <= state_fetch;
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				pc_inc <= '1';
				
			-- Replacing top 4 bites
			when state_replace_top_read =>
				next_state <= state_replace_top;
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				
			when state_replace_top =>
				next_state <= state_replace_write;
				can_replace <= '1';
				
			when state_replace_write =>
				next_state <= state_fetch;
				DATA_EN <= '1';
				DATA_RDWR <= '0';
				pc_inc <= '1';
			
			-- Writing char to LCD monitor
			when state_putchar_read =>
				next_state <= state_putchar_write;
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				
			when state_putchar_write =>
				if(OUT_BUSY = '1') then -- it is busy, cannot putchar yet
					next_state <= state_putchar_write; -- repeat enabling of reading until we can write it out
					DATA_EN <= '1';
					DATA_RDWRD <= '1';
				elsif(OUT_BUSY = '0') then -- it is not busy, can putchar now
					next_state <= state_fetch;
					OUT_WE <= '1';
					pc_inc <= '1';
				end if;
				
			-- GETCHAR
			when state_getchar =>
				next_state <= state_getchar;
				IN_REQ <= '1';
				if(IN_VLD = '1') then
					next_state <= state_fetch;
					use_mux <= '1';
					sel <= "00";
					DATA <= '1';
					DATA_RDWR <= '0';
					IN_REQ <= '0';
					pc_inc <= '1';
				end if;
				
			-- WHILE
			
				
			-- COMMENT
			when state_comment =>
				if(CODE_DATA = X"23") then
					next_state <= state_fetch;
				end if;
				pc_inc <= '1';
				
			when state_halt =>
				next_state <= state_halt;
				
			when state_none =>
				next_state <= state_fetch;
				pc_inc <= '1';
				
		end case;
	end process FSM_next_state;
	
end behavioral;
 
