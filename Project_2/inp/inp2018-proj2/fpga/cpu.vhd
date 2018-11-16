-- cpu.vhd: Simple 8-bit CPU (BrainF*ck interpreter)
-- Copyright (C) 2018 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): DOPLNIT
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

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
	signal mem_data : std_logic_vector(7 downto 0) := "00000000";
	signal sel : std_logic_vector(1 downto 0) := "00";
	
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
		state_while_start,
		state_while_end,
		state_comment,
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
	MUX_process : process
	begin
		if(RESET = '1') then
			mem_data <= "00000000";
		elsif(CLK'event and CLK = '1') then
			if(sel = "00") then
				mem_data <= IN_DATA;
			elsif(sel = "01") then
				mem_data <= CODE_DATA;
			elsif(sel = "10") then
				mem_data <= DATA_RDATA + "00000001";
			elsif(sel = "11") then
				mem_data <= DATA_RDATA - "00000001";
			end if;
		end if;
	end process MUX_process;
	
 -- FSM 
 -- FSM present state
	FSM_present_state : process(RESET, CLK, EN)
	begin
		if(RESET = '1') then
			present_state <= state_idle;
		elsif(CLK'event) and (CLK = '1') then
			if(EN = '1') then
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
				CODE_EN <= '0';
				
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
					-- TODO finish
				end case;
			
			when state_ptr_inc =>
				next_state <= state_fetch;
				ptr_inc <= '1';
				pc_inc <= '1';
				
			when state_ptr_dec =>
				next_state <= state_fetch;
				ptr_dec <= '1';
				pc_inc <= '1';
			
			-- TODO:
			-- we first have to read the value from memory
			when state_value_inc_read =>
				next_state <= state_value_inc_write;
				DATA_EN <= '1';
				
			when state_value_inc =>
				
			-- we can save it
			when state_value_inc_write =>
				next_state <= state_fetch;
				pc_inc <= '1';
			-- END TODO
				
		end case;
	end process FSM_next_state;
	
end behavioral;
 
