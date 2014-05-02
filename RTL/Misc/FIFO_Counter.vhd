library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity FIFO_Counter is
	generic(
		maxbit : integer := 7;
		lowbit : integer := 3;	-- Ignore (lowbit-1 downto 0) when generating full and empty signals
		increment : integer := 1
	);
	port(
		clk : in std_logic;
		reset_n : in std_logic;
		fill : in std_logic; -- FIFO has received an entry
		drain : in std_logic;	-- An entry has been read
		full : out std_logic;	-- FIFO is full
		empty : out std_logic	-- FIFO is empty
	);
end entity;


architecture RTL of FIFO_Counter is
signal counter : unsigned(maxbit downto 0);
constant	hightide : unsigned(maxbit downto lowbit) := (others=>'1');
constant	lowtide : unsigned(maxbit downto lowbit) := (others=>'0');

begin

-- Maintain a counter to coordinate filling and emptying of a FIFO.
-- Need to increment and decrement the counters according to the fill and drain signals
-- Must be able to cope with both signals being triggered simultaneously.

full <='1' when counter(maxbit downto lowbit)=hightide else '0';
empty <='1' when counter(maxbit downto lowbit)=lowtide else '0';

process(clk)
begin

	if rising_edge(clk) then
		if reset_n='0' then
			counter<=(others=>'0');
		else
			if fill='1' and drain='0' then
				counter<=counter+to_unsigned(increment,maxbit+1);
			elsif fill='0' and drain='1' then
				counter<=counter-to_unsigned(increment,maxbit+1);
			end if;
		end if;
	end if;
	
end process;

end architecture;
