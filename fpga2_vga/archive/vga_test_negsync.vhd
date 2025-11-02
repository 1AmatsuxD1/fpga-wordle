--------------------------------------------------------------------------------
-- VGA Test - Negative Sync (บางจอต้องการ active LOW)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_test_negsync is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic
    );
end vga_test_negsync;

architecture Behavioral of vga_test_negsync is
    signal counter : unsigned(25 downto 0) := (others => '0');
begin
    
    -- Negative Sync (Active LOW)
    vga_hsync <= '0';
    vga_vsync <= '0';
    
    -- กระพริบสี
    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
        end if;
    end process;
    
    vga_r <= counter(23);
    vga_g <= counter(24);
    vga_b <= counter(25);
    
end Behavioral;
